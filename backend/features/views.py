"""
Views for features app.
"""
from __future__ import annotations

from typing import Any, cast

from rest_framework import generics, status, views
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, QuerySet

from core.permissions import IsAdmin, IsTrainerOrAdmin
from users.models import User
from .models import FeatureRequest, FeatureVote, FeatureComment
from .serializers import (
    FeatureRequestListSerializer, FeatureRequestDetailSerializer,
    CreateFeatureRequestSerializer, FeatureCommentSerializer,
    CreateCommentSerializer, VoteSerializer, AdminUpdateStatusSerializer
)


class FeatureRequestListCreateView(generics.ListCreateAPIView[FeatureRequest]):
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

    def get_serializer_class(self) -> type:
        if self.request.method == 'POST':
            return CreateFeatureRequestSerializer
        return FeatureRequestListSerializer

    def get_queryset(self) -> QuerySet[FeatureRequest]:
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

    def perform_create(self, serializer: Any) -> None:
        user = cast(User, self.request.user)
        serializer.save(submitted_by=user)


class FeatureRequestDetailView(generics.RetrieveUpdateDestroyAPIView[FeatureRequest]):
    """
    GET: Retrieve a feature request.
    PUT/PATCH: Update a feature request (only owner).
    DELETE: Delete a feature request (only owner or admin).
    """
    permission_classes = [IsAuthenticated]
    serializer_class = FeatureRequestDetailSerializer
    queryset = FeatureRequest.objects.all()

    def get_serializer_class(self) -> type:
        if self.request.method in ['PUT', 'PATCH']:
            return CreateFeatureRequestSerializer
        return FeatureRequestDetailSerializer

    def update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
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

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        instance = self.get_object()
        # Only owner or admin can delete
        user = cast(User, request.user)
        if instance.submitted_by != request.user and not user.is_admin():
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

    def get(self, request: Request, pk: int) -> Response:
        """Get current user's vote on this feature."""
        user = cast(User, request.user)
        try:
            feature = FeatureRequest.objects.get(pk=pk)
        except FeatureRequest.DoesNotExist:
            return Response(
                {'error': 'Feature request not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        vote = FeatureVote.objects.filter(
            feature=feature,
            user=user
        ).first()

        return Response({
            'vote_type': vote.vote_type if vote else None,
            'upvotes': feature.upvotes,
            'downvotes': feature.downvotes
        })

    def post(self, request: Request, pk: int) -> Response:
        """Create or update a vote."""
        user = cast(User, request.user)
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
            user=user
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
                user=user,
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


class FeatureCommentListCreateView(generics.ListCreateAPIView[FeatureComment]):
    """
    GET: List comments for a feature request.
    POST: Add a comment to a feature request.
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self) -> type:
        if self.request.method == 'POST':
            return CreateCommentSerializer
        return FeatureCommentSerializer

    def get_queryset(self) -> QuerySet[FeatureComment]:
        feature_id = self.kwargs['pk']
        return FeatureComment.objects.filter(feature_id=feature_id).order_by('created_at')

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
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
            user=user,
            content=serializer.validated_data['content'],
            is_admin_response=user.is_admin()
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

    def patch(self, request: Request, pk: int) -> Response:
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
