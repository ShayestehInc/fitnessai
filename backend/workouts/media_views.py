"""
Views for voice memo and video analysis — v6.5 Step 14.

Voice memos: upload audio → transcribe → parse
Video analysis: upload video → analyze form → confirm
"""
from __future__ import annotations

from rest_framework import serializers, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import User
from .models import VideoAnalysis, VoiceMemo
from .services.voice_memo_service import (
    get_voice_memo,
    list_voice_memos,
    upload_and_transcribe,
)
from .services.video_analysis_service import (
    confirm_analysis,
    get_video_analysis,
    list_video_analyses,
    upload_and_analyze,
)


# ---------------------------------------------------------------------------
# Serializers
# ---------------------------------------------------------------------------

class VoiceMemoSerializer(serializers.Serializer):
    """Read-only voice memo serializer."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    transcript = serializers.CharField(allow_blank=True)
    transcription_confidence = serializers.FloatField(allow_null=True)
    transcription_language = serializers.CharField(allow_blank=True)
    parsed_result = serializers.JSONField()
    audio_format = serializers.CharField(allow_blank=True)
    duration_seconds = serializers.FloatField(allow_null=True)
    error_message = serializers.CharField(allow_blank=True)
    created_at = serializers.DateTimeField()


class VoiceMemoListSerializer(serializers.Serializer):
    """Lightweight list serializer."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    audio_format = serializers.CharField(allow_blank=True)
    transcript_preview = serializers.SerializerMethodField()
    created_at = serializers.DateTimeField()

    def get_transcript_preview(self, obj: VoiceMemo) -> str:
        if obj.transcript:
            return obj.transcript[:100] + ('...' if len(obj.transcript) > 100 else '')
        return ''


class VideoAnalysisSerializer(serializers.Serializer):
    """Read-only video analysis serializer."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    exercise_detected = serializers.CharField(allow_blank=True)
    exercise_id = serializers.IntegerField(allow_null=True)
    rep_count = serializers.IntegerField(allow_null=True)
    form_score = serializers.FloatField(allow_null=True)
    observations = serializers.ListField(child=serializers.CharField())
    confidence = serializers.FloatField(allow_null=True)
    error_message = serializers.CharField(allow_blank=True)
    created_at = serializers.DateTimeField()
    confirmed_at = serializers.DateTimeField(allow_null=True)


class VideoAnalysisListSerializer(serializers.Serializer):
    """Lightweight list serializer."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    exercise_detected = serializers.CharField(allow_blank=True)
    rep_count = serializers.IntegerField(allow_null=True)
    form_score = serializers.FloatField(allow_null=True)
    confidence = serializers.FloatField(allow_null=True)
    created_at = serializers.DateTimeField()


# ---------------------------------------------------------------------------
# Permission helper
# ---------------------------------------------------------------------------

def _require_trainee(request: Request) -> User:
    """Verify user is a trainee."""
    user = request.user
    if user.role != 'TRAINEE':
        raise PermissionDenied("Only trainees can use voice memos and video analysis.")
    return user


# ---------------------------------------------------------------------------
# Voice Memo Views
# ---------------------------------------------------------------------------

class VoiceMemoUploadView(APIView):
    """POST /voice-memos/ — Upload audio, transcribe, parse."""
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser]

    def post(self, request: Request) -> Response:
        trainee = _require_trainee(request)
        audio_file = request.FILES.get('audio_file')
        if not audio_file:
            return Response(
                {'detail': 'audio_file is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            result = upload_and_transcribe(
                trainee=trainee,
                audio_file=audio_file,
            )
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                'memo_id': result.memo_id,
                'status': result.status,
                'transcript': result.transcript,
                'parsed_result': result.parsed_result,
                'error': result.error,
            },
            status=status.HTTP_201_CREATED,
        )


class VoiceMemoListView(APIView):
    """GET /voice-memos/ — List recent voice memos."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        trainee = _require_trainee(request)
        try:
            limit = min(int(request.query_params.get('limit', '20')), 100)
        except (ValueError, TypeError):
            limit = 20
        memos = list_voice_memos(trainee=trainee, limit=limit)
        ser = VoiceMemoListSerializer(memos, many=True)
        return Response(ser.data)


class VoiceMemoDetailView(APIView):
    """GET /voice-memos/{memo_id}/ — Get voice memo detail."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, memo_id: str) -> Response:
        trainee = _require_trainee(request)
        try:
            memo = get_voice_memo(memo_id=memo_id, trainee=trainee)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_404_NOT_FOUND,
            )
        ser = VoiceMemoSerializer(memo)
        return Response(ser.data)


# ---------------------------------------------------------------------------
# Video Analysis Views
# ---------------------------------------------------------------------------

class VideoAnalysisUploadView(APIView):
    """POST /video-analysis/ — Upload video, analyze."""
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser]

    def post(self, request: Request) -> Response:
        trainee = _require_trainee(request)
        video_file = request.FILES.get('video_file')
        if not video_file:
            return Response(
                {'detail': 'video_file is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            result = upload_and_analyze(
                trainee=trainee,
                video_file=video_file,
            )
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                'analysis_id': result.analysis_id,
                'status': result.status,
                'exercise_detected': result.exercise_detected,
                'exercise_id': result.exercise_id,
                'rep_count': result.rep_count,
                'form_score': result.form_score,
                'observations': result.observations,
                'confidence': result.confidence,
                'error': result.error,
            },
            status=status.HTTP_201_CREATED,
        )


class VideoAnalysisListView(APIView):
    """GET /video-analysis/ — List recent video analyses."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        trainee = _require_trainee(request)
        try:
            limit = min(int(request.query_params.get('limit', '20')), 100)
        except (ValueError, TypeError):
            limit = 20
        analyses = list_video_analyses(trainee=trainee, limit=limit)
        ser = VideoAnalysisListSerializer(analyses, many=True)
        return Response(ser.data)


class VideoAnalysisDetailView(APIView):
    """GET /video-analysis/{analysis_id}/ — Get analysis detail."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, analysis_id: str) -> Response:
        trainee = _require_trainee(request)
        try:
            analysis = get_video_analysis(analysis_id=analysis_id, trainee=trainee)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_404_NOT_FOUND,
            )
        ser = VideoAnalysisSerializer(analysis)
        return Response(ser.data)


class VideoAnalysisConfirmView(APIView):
    """POST /video-analysis/{analysis_id}/confirm/ — Confirm findings."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, analysis_id: str) -> Response:
        trainee = _require_trainee(request)
        try:
            result = confirm_analysis(analysis_id=analysis_id, trainee=trainee)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response({
            'analysis_id': result.analysis_id,
            'exercise_id': result.exercise_id,
            'rep_count': result.rep_count,
            'form_score': result.form_score,
        })
