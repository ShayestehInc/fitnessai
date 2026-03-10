"""
Tests for Voice Memo + Video Analysis — v6.5 Step 14.

Covers:
- Voice memo upload, transcription (mocked), parsing (mocked)
- Video upload, analysis (mocked), confirm
- API endpoints
- File validation
"""
from __future__ import annotations

from io import BytesIO
from unittest.mock import MagicMock, patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from users.models import User
from workouts.models import (
    DecisionLog,
    Exercise,
    VideoAnalysis,
    VoiceMemo,
)
from workouts.services.voice_memo_service import (
    get_voice_memo,
    list_voice_memos,
    upload_and_transcribe,
)
from workouts.services.video_analysis_service import (
    confirm_analysis,
    get_video_analysis,
    list_video_analyses,
    upload_and_analyze,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _create_trainer() -> User:
    return User.objects.create_user(
        email='trainer@test.com', password='pass', role='TRAINER',
    )


def _create_trainee(trainer: User) -> User:
    return User.objects.create_user(
        email='trainee@test.com', password='pass', role='TRAINEE',
        parent_trainer=trainer,
    )


def _audio_file(name: str = 'test.mp3', size: int = 1024) -> SimpleUploadedFile:
    return SimpleUploadedFile(name, b'\x00' * size, content_type='audio/mpeg')


def _video_file(name: str = 'test.mp4', size: int = 2048) -> SimpleUploadedFile:
    return SimpleUploadedFile(name, b'\x00' * size, content_type='video/mp4')


def _mock_transcribe(memo: object) -> tuple[str, float, str]:
    return ('I did 3 sets of bench press at 225 pounds', 0.92, 'en')


def _mock_parse(transcript: str, trainee: object) -> dict:
    return {
        'workout': {
            'exercises': [{
                'exercise_name': 'Bench Press',
                'sets': 3,
                'reps': 8,
                'weight': 225,
                'unit': 'lbs',
            }],
        },
        'nutrition': {'meals': []},
        'confidence': 0.85,
    }


MOCK_VIDEO_AI_RESPONSE: dict = {
    'exercise_detected': 'Barbell Squat',
    'rep_count': 5,
    'form_score': 7.5,
    'observations': ['Good depth', 'Slight forward lean at bottom'],
    'confidence': 0.8,
}


# ---------------------------------------------------------------------------
# Voice Memo Service Tests
# ---------------------------------------------------------------------------

class VoiceMemoServiceTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_upload_and_transcribe(self, mock_trans: object, mock_parse: object) -> None:
        result = upload_and_transcribe(
            trainee=self.trainee,
            audio_file=_audio_file(),
        )
        self.assertEqual(result.status, 'parsed')
        self.assertIn('bench press', result.transcript.lower())
        self.assertIn('workout', result.parsed_result)

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_creates_memo_record(self, mock_trans: object, mock_parse: object) -> None:
        result = upload_and_transcribe(
            trainee=self.trainee,
            audio_file=_audio_file(),
        )
        memo = VoiceMemo.objects.get(pk=result.memo_id)
        self.assertEqual(memo.status, 'parsed')
        self.assertEqual(memo.transcription_language, 'en')

    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=Exception("API error"))
    def test_transcription_failure(self, mock_trans: object) -> None:
        result = upload_and_transcribe(
            trainee=self.trainee,
            audio_file=_audio_file(),
        )
        self.assertEqual(result.status, 'failed')
        self.assertIn('Transcription failed', result.error)

    def test_invalid_format(self) -> None:
        with self.assertRaises(ValueError):
            upload_and_transcribe(
                trainee=self.trainee,
                audio_file=SimpleUploadedFile('test.exe', b'\x00' * 100),
            )

    def test_file_too_large(self) -> None:
        large_file = SimpleUploadedFile('test.mp3', b'\x00' * (26 * 1024 * 1024))
        with self.assertRaises(ValueError):
            upload_and_transcribe(trainee=self.trainee, audio_file=large_file)

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_get_and_list(self, mock_trans: object, mock_parse: object) -> None:
        result = upload_and_transcribe(trainee=self.trainee, audio_file=_audio_file())
        memo = get_voice_memo(memo_id=result.memo_id, trainee=self.trainee)
        self.assertEqual(str(memo.pk), result.memo_id)

        memos = list_voice_memos(trainee=self.trainee)
        self.assertEqual(len(memos), 1)

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_wrong_trainee_cannot_access(self, mock_trans: object, mock_parse: object) -> None:
        result = upload_and_transcribe(trainee=self.trainee, audio_file=_audio_file())
        other = User.objects.create_user(
            email='other@test.com', password='pass', role='TRAINEE',
            parent_trainer=self.trainer,
        )
        with self.assertRaises(ValueError):
            get_voice_memo(memo_id=result.memo_id, trainee=other)


# ---------------------------------------------------------------------------
# Video Analysis Service Tests
# ---------------------------------------------------------------------------

class VideoAnalysisServiceTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        Exercise.objects.create(name='Barbell Squat', is_public=True)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_upload_and_analyze(self, mock_ai: object) -> None:
        result = upload_and_analyze(
            trainee=self.trainee,
            video_file=_video_file(),
        )
        self.assertEqual(result.status, 'analyzed')
        self.assertEqual(result.exercise_detected, 'Barbell Squat')
        self.assertEqual(result.rep_count, 5)
        self.assertAlmostEqual(result.form_score, 7.5)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_matches_exercise(self, mock_ai: object) -> None:
        result = upload_and_analyze(trainee=self.trainee, video_file=_video_file())
        self.assertIsNotNone(result.exercise_id)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', side_effect=Exception("Vision API error"))
    def test_analysis_failure(self, mock_ai: object) -> None:
        result = upload_and_analyze(trainee=self.trainee, video_file=_video_file())
        self.assertEqual(result.status, 'failed')
        self.assertIn('Analysis failed', result.error)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_confirm_creates_decision_log(self, mock_ai: object) -> None:
        result = upload_and_analyze(trainee=self.trainee, video_file=_video_file())
        confirm_result = confirm_analysis(
            analysis_id=result.analysis_id, trainee=self.trainee,
        )
        self.assertIsNotNone(confirm_result.exercise_id)

        log = DecisionLog.objects.filter(decision_type='video_analysis_confirmed').first()
        self.assertIsNotNone(log)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_confirm_updates_status(self, mock_ai: object) -> None:
        result = upload_and_analyze(trainee=self.trainee, video_file=_video_file())
        confirm_analysis(analysis_id=result.analysis_id, trainee=self.trainee)

        analysis = VideoAnalysis.objects.get(pk=result.analysis_id)
        self.assertEqual(analysis.status, 'confirmed')
        self.assertIsNotNone(analysis.confirmed_at)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_cannot_confirm_twice(self, mock_ai: object) -> None:
        result = upload_and_analyze(trainee=self.trainee, video_file=_video_file())
        confirm_analysis(analysis_id=result.analysis_id, trainee=self.trainee)
        with self.assertRaises(ValueError):
            confirm_analysis(analysis_id=result.analysis_id, trainee=self.trainee)

    def test_invalid_video_format(self) -> None:
        with self.assertRaises(ValueError):
            upload_and_analyze(
                trainee=self.trainee,
                video_file=SimpleUploadedFile('test.txt', b'\x00' * 100),
            )


# ---------------------------------------------------------------------------
# API Tests — Voice Memos
# ---------------------------------------------------------------------------

class VoiceMemoAPITests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        self.client = APIClient()
        self.client.force_authenticate(self.trainee)

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_upload_api(self, mock_trans: object, mock_parse: object) -> None:
        resp = self.client.post(
            '/api/workouts/voice-memos/',
            {'audio_file': _audio_file()},
            format='multipart',
        )
        self.assertEqual(resp.status_code, 201)
        self.assertIn('memo_id', resp.data)
        self.assertEqual(resp.data['status'], 'parsed')

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_list_api(self, mock_trans: object, mock_parse: object) -> None:
        self.client.post('/api/workouts/voice-memos/', {'audio_file': _audio_file()}, format='multipart')
        resp = self.client.get('/api/workouts/voice-memos/list/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(len(resp.data), 1)

    @patch('workouts.services.voice_memo_service._parse_transcript', side_effect=_mock_parse)
    @patch('workouts.services.voice_memo_service._transcribe_audio', side_effect=_mock_transcribe)
    def test_detail_api(self, mock_trans: object, mock_parse: object) -> None:
        upload_resp = self.client.post(
            '/api/workouts/voice-memos/',
            {'audio_file': _audio_file()},
            format='multipart',
        )
        memo_id = upload_resp.data['memo_id']
        resp = self.client.get(f'/api/workouts/voice-memos/{memo_id}/')
        self.assertEqual(resp.status_code, 200)

    def test_trainer_cannot_upload(self) -> None:
        self.client.force_authenticate(self.trainer)
        resp = self.client.post(
            '/api/workouts/voice-memos/',
            {'audio_file': _audio_file()},
            format='multipart',
        )
        self.assertEqual(resp.status_code, 403)

    def test_missing_file(self) -> None:
        resp = self.client.post('/api/workouts/voice-memos/', {}, format='multipart')
        self.assertEqual(resp.status_code, 400)


# ---------------------------------------------------------------------------
# API Tests — Video Analysis
# ---------------------------------------------------------------------------

class VideoAnalysisAPITests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        Exercise.objects.create(name='Barbell Squat', is_public=True)
        self.client = APIClient()
        self.client.force_authenticate(self.trainee)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_upload_api(self, mock_ai: object) -> None:
        resp = self.client.post(
            '/api/workouts/video-analysis/',
            {'video_file': _video_file()},
            format='multipart',
        )
        self.assertEqual(resp.status_code, 201)
        self.assertIn('analysis_id', resp.data)
        self.assertEqual(resp.data['exercise_detected'], 'Barbell Squat')

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_confirm_api(self, mock_ai: object) -> None:
        upload_resp = self.client.post(
            '/api/workouts/video-analysis/',
            {'video_file': _video_file()},
            format='multipart',
        )
        analysis_id = upload_resp.data['analysis_id']
        resp = self.client.post(f'/api/workouts/video-analysis/{analysis_id}/confirm/')
        self.assertEqual(resp.status_code, 200)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_list_api(self, mock_ai: object) -> None:
        self.client.post('/api/workouts/video-analysis/', {'video_file': _video_file()}, format='multipart')
        resp = self.client.get('/api/workouts/video-analysis/list/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(len(resp.data), 1)

    @patch('workouts.services.video_analysis_service._analyze_video_with_ai', return_value=MOCK_VIDEO_AI_RESPONSE)
    def test_detail_api(self, mock_ai: object) -> None:
        upload_resp = self.client.post(
            '/api/workouts/video-analysis/',
            {'video_file': _video_file()},
            format='multipart',
        )
        analysis_id = upload_resp.data['analysis_id']
        resp = self.client.get(f'/api/workouts/video-analysis/{analysis_id}/')
        self.assertEqual(resp.status_code, 200)

    def test_trainer_cannot_upload(self) -> None:
        self.client.force_authenticate(self.trainer)
        resp = self.client.post(
            '/api/workouts/video-analysis/',
            {'video_file': _video_file()},
            format='multipart',
        )
        self.assertEqual(resp.status_code, 403)

    def test_missing_file(self) -> None:
        resp = self.client.post('/api/workouts/video-analysis/', {}, format='multipart')
        self.assertEqual(resp.status_code, 400)
