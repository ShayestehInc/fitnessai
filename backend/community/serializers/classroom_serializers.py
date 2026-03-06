"""
Serializers for the Classroom feature: courses, lessons, enrollments, progress.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from ..models import (
    Course,
    CourseEnrollment,
    CourseLesson,
    LessonProgress,
)


# ---------------------------------------------------------------------------
# Lessons
# ---------------------------------------------------------------------------

class CourseLessonSerializer(serializers.ModelSerializer[CourseLesson]):
    """Read serializer for a course lesson."""

    class Meta:
        model = CourseLesson
        fields = [
            'id', 'title', 'content_type', 'text_content', 'video_url',
            'file_attachment', 'sort_order', 'drip_delay_days',
            'estimated_minutes', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CourseLessonCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation / update of a lesson."""
    title = serializers.CharField(max_length=200)
    content_type = serializers.ChoiceField(
        choices=CourseLesson.ContentType.choices,
        default=CourseLesson.ContentType.TEXT,
    )
    text_content = serializers.CharField(required=False, allow_blank=True, default='')
    video_url = serializers.URLField(required=False, allow_blank=True, default='')
    sort_order = serializers.IntegerField(default=0, min_value=0)
    drip_delay_days = serializers.IntegerField(default=0, min_value=0)
    estimated_minutes = serializers.IntegerField(default=0, min_value=0)


# ---------------------------------------------------------------------------
# Courses
# ---------------------------------------------------------------------------

class CourseSerializer(serializers.ModelSerializer[Course]):
    """Read serializer for a course with lesson count and enrollment count."""
    lesson_count = serializers.IntegerField(read_only=True, default=0)
    enrollment_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Course
        fields = [
            'id', 'title', 'description', 'cover_image', 'status',
            'drip_enabled', 'is_mandatory', 'sort_order',
            'lesson_count', 'enrollment_count',
            'space', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CourseDetailSerializer(serializers.ModelSerializer[Course]):
    """Read serializer for a course with full lesson list."""
    lessons = CourseLessonSerializer(many=True, read_only=True)
    lesson_count = serializers.IntegerField(read_only=True, default=0)
    enrollment_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Course
        fields = [
            'id', 'title', 'description', 'cover_image', 'status',
            'drip_enabled', 'is_mandatory', 'sort_order',
            'lesson_count', 'enrollment_count',
            'space', 'lessons', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CourseCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation / update of a course."""
    title = serializers.CharField(max_length=200)
    description = serializers.CharField(
        max_length=2000, required=False, allow_blank=True, default='',
    )
    status = serializers.ChoiceField(
        choices=Course.Status.choices,
        default=Course.Status.DRAFT,
    )
    drip_enabled = serializers.BooleanField(default=False)
    is_mandatory = serializers.BooleanField(default=False)
    sort_order = serializers.IntegerField(default=0, min_value=0)
    space = serializers.IntegerField(required=False, allow_null=True, default=None)


# ---------------------------------------------------------------------------
# Enrollments & Progress
# ---------------------------------------------------------------------------

class CourseEnrollmentSerializer(serializers.ModelSerializer[CourseEnrollment]):
    """Read serializer for an enrollment."""
    course_title = serializers.CharField(source='course.title', read_only=True)
    course_status = serializers.CharField(source='course.status', read_only=True)
    progress = serializers.SerializerMethodField()

    class Meta:
        model = CourseEnrollment
        fields = [
            'id', 'course_id', 'course_title', 'course_status',
            'enrolled_at', 'completed_at', 'progress',
        ]
        read_only_fields = ['id', 'enrolled_at', 'completed_at']

    def get_progress(self, obj: CourseEnrollment) -> dict[str, int]:
        from ..services.classroom_service import ClassroomService
        return ClassroomService.get_course_progress(obj)


class LessonProgressSerializer(serializers.ModelSerializer[LessonProgress]):
    """Read serializer for lesson progress."""
    lesson_title = serializers.CharField(source='lesson.title', read_only=True)

    class Meta:
        model = LessonProgress
        fields = [
            'id', 'lesson_id', 'lesson_title', 'status',
            'started_at', 'completed_at',
        ]
        read_only_fields = ['id', 'started_at', 'completed_at']


class LessonProgressUpdateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates lesson progress update."""
    status = serializers.ChoiceField(choices=LessonProgress.ProgressStatus.choices)
