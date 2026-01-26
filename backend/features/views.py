"""
Views for features app.
"""
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q

from core.permissions import IsAdmin, IsTrainerOrAdmin
from .models import FeatureRequest, FeatureVote, FeatureComment
from .serializers import (
    FeatureRequestListSerializer, FeatureRequestDetailSerializer,
    CreateFeatureRequestSerializer, FeatureCommentSerializer,
    CreateCommentSerializer, VoteSerializer, AdminUpdateStatusSerializer
)


class FeatureRequestListCreateView(generics.ListCreateAPIView):
    """
    GET: List all feature requests.
    POST: Create a new feature request.
    Query params:
        - status: filter by status
        - category: filter by category
        - search: search in title/description
        - sort: 'votes' (default), 'recent', 'comments'
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateFeatureRequestSerializer
        return FeatureRequestListSerializer

    def get_queryset(self):
        queryset = FeatureRequest.objects.all()

        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)

        # Search
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(description__icontains=search)
            )

        # Sort
        sort = self.request.query_params.get('sort', 'votes')
        if sort == 'recent':
            queryset = queryset.order_by('-created_at')
        elif sort == 'comments':
            queryset = queryset.annotate(
                comment_count=Count('comments')
            ).order_by('-comment_count', '-upvotes')
        else:  # votes (default)
            queryset = queryset.order_by('-upvotes', '-created_at')

        return queryset

    def perform_create(self, serializer):
        serializer.save(submitted_by=self.request.user)


class FeatureRequestDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve a feature request.
    PUT/PATCH: Update a feature request (only owner).
    DELETE: Delete a feature request (only owner or admin).
    """
    permission_classes = [IsAuthenticated]
    serializer_class = FeatureRequestDetailSerializer
    queryset = FeatureRequest.objects.all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return CreateFeatureRequestSerializer
        return FeatureRequestDetailSerializer

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Only owner can update
        if instance.submitted_by != request.user:
            return Response(
                {'error': 'You can only edit your own feature requests'},
                status=status.HTTP_403_FORBIDDEN
            )
        # Can only update if still in submitted status
        if instance.status != FeatureRequest.Status.SUBMITTED:
            return Response(
                {'error': 'Cannot edit feature request once reviewed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        # Only owner or admin can delete
        if instance.submitted_by != request.user and not request.user.is_admin():
            return Response(
                {'error': 'You can only delete your own feature requests'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)


class FeatureVoteView(views.APIView):
    """
    POST: Vote on a feature request.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        """Get current user's vote on this feature."""
        try:
            feature = FeatureRequest.objects.get(pk=pk)
        except FeatureRequest.DoesNotExist:
            return Response(
                {'error': 'Feature request not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        vote = FeatureVote.objects.filter(
            feature=feature,
            user=request.user
        ).first()

        return Response({
            'vote_type': vote.vote_type if vote else None,
            'upvotes': feature.upvotes,
            'downvotes': feature.downvotes
        })

    def post(self, request, pk):
        """Create or update a vote."""
        serializer = VoteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            feature = FeatureRequest.objects.get(pk=pk)
        except FeatureRequest.DoesNotExist:
            return Response(
                {'error': 'Feature request not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        vote_type = serializer.validated_data['vote_type']
        existing_vote = FeatureVote.objects.filter(
            feature=feature,
            user=request.user
        ).first()

        if vote_type == 'remove':
            if existing_vote:
                existing_vote.delete()
            return Response({
                'message': 'Vote removed',
                'upvotes': feature.upvotes,
                'downvotes': feature.downvotes
            })

        if existing_vote:
            if existing_vote.vote_type == vote_type:
                # Same vote, no change needed
                return Response({
                    'message': f'Already voted {vote_type}',
                    'upvotes': feature.upvotes,
                    'downvotes': feature.downvotes
                })
            # Change vote
            existing_vote.vote_type = vote_type
            existing_vote.save()
            message = f'Vote changed to {vote_type}'
        else:
            # New vote
            FeatureVote.objects.create(
                feature=feature,
                user=request.user,
                vote_type=vote_type
            )
            message = f'Voted {vote_type}'

        # Refresh vote counts
        feature.refresh_from_db()

        return Response({
            'message': message,
            'upvotes': feature.upvotes,
            'downvotes': feature.downvotes
        })


class FeatureCommentListCreateView(generics.ListCreateAPIView):
    """
    GET: List comments for a feature request.
    POST: Add a comment to a feature request.
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateCommentSerializer
        return FeatureCommentSerializer

    def get_queryset(self):
        feature_id = self.kwargs['pk']
        return FeatureComment.objects.filter(feature_id=feature_id).order_by('created_at')

    def create(self, request, *args, **kwargs):
        feature_id = self.kwargs['pk']

        try:
            feature = FeatureRequest.objects.get(pk=feature_id)
        except FeatureRequest.DoesNotExist:
            return Response(
                {'error': 'Feature request not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = CreateCommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        comment = FeatureComment.objects.create(
            feature=feature,
            user=request.user,
            content=serializer.validated_data['content'],
            is_admin_response=request.user.is_admin()
        )

        return Response(
            FeatureCommentSerializer(comment).data,
            status=status.HTTP_201_CREATED
        )


class AdminUpdateStatusView(views.APIView):
    """
    PATCH: Update feature request status (admin only).
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def patch(self, request, pk):
        try:
            feature = FeatureRequest.objects.get(pk=pk)
        except FeatureRequest.DoesNotExist:
            return Response(
                {'error': 'Feature request not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = AdminUpdateStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data

        feature.status = data['status']
        if 'public_response' in data:
            feature.public_response = data['public_response']
        if 'admin_notes' in data:
            feature.admin_notes = data['admin_notes']
        if 'target_release' in data:
            feature.target_release = data['target_release']

        feature.save()

        return Response(
            FeatureRequestDetailSerializer(feature, context={'request': request}).data
        )


# Need to import Count for annotation
from django.db.models import Count
