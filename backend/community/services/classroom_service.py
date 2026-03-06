"""
Service layer for the Classroom feature:
course enrollment, drip scheduling, and progress tracking.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import timedelta
from typing import Optional

from django.db.models import Count, QuerySet
from django.utils import timezone

from users.models import User
from ..models import (
    Course,
    CourseEnrollment,
    CourseLesson,
    LessonProgress,
)

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class EnrollmentResult:
    enrollment: CourseEnrollment
    created: bool


@dataclass(frozen=True)
class LessonAvailability:
    lesson: CourseLesson
    is_unlocked: bool
    unlocks_at: Optional[str]  # ISO datetime string or None


class ClassroomService:
    """Handles course enrollment, drip schedules, and lesson progress."""

    @staticmethod
    def enroll_trainee(course: Course, user: User) -> EnrollmentResult:
        """Enroll a user in a course. Idempotent."""
        enrollment, created = CourseEnrollment.objects.get_or_create(
            course=course,
            user=user,
        )
        if created:
            logger.info("User %s enrolled in course %s", user.email, course.title)
        return EnrollmentResult(enrollment=enrollment, created=created)

    @staticmethod
    def auto_enroll_mandatory_courses(trainer: User, user: User) -> list[CourseEnrollment]:
        """Auto-enroll a user in all mandatory published courses for their trainer."""
        mandatory_courses = Course.objects.filter(
            trainer=trainer,
            status=Course.Status.PUBLISHED,
            is_mandatory=True,
        )
        enrollments: list[CourseEnrollment] = []
        for course in mandatory_courses:
            enrollment, _ = CourseEnrollment.objects.get_or_create(
                course=course,
                user=user,
            )
            enrollments.append(enrollment)
        return enrollments

    @staticmethod
    def get_lesson_availability(
        enrollment: CourseEnrollment,
        lesson: CourseLesson,
    ) -> LessonAvailability:
        """Check whether a lesson is unlocked for a given enrollment."""
        if not enrollment.course.drip_enabled or lesson.drip_delay_days == 0:
            return LessonAvailability(lesson=lesson, is_unlocked=True, unlocks_at=None)

        unlock_dt = enrollment.enrolled_at + timedelta(days=lesson.drip_delay_days)
        is_unlocked = timezone.now() >= unlock_dt
        unlocks_at = None if is_unlocked else unlock_dt.isoformat()
        return LessonAvailability(
            lesson=lesson,
            is_unlocked=is_unlocked,
            unlocks_at=unlocks_at,
        )

    @staticmethod
    def get_all_lesson_availability(
        enrollment: CourseEnrollment,
    ) -> list[LessonAvailability]:
        """Return availability for every lesson in the enrollment's course."""
        lessons = enrollment.course.lessons.all()
        return [
            ClassroomService.get_lesson_availability(enrollment, lesson)
            for lesson in lessons
        ]

    @staticmethod
    def mark_lesson_progress(
        enrollment: CourseEnrollment,
        lesson: CourseLesson,
        new_status: str,
    ) -> LessonProgress:
        """Update a trainee's progress on a lesson."""
        now = timezone.now()
        progress, created = LessonProgress.objects.get_or_create(
            enrollment=enrollment,
            lesson=lesson,
            defaults={'status': new_status},
        )

        if not created and progress.status != new_status:
            progress.status = new_status
            update_fields = ['status']

            if new_status == LessonProgress.ProgressStatus.IN_PROGRESS and not progress.started_at:
                progress.started_at = now
                update_fields.append('started_at')
            elif new_status == LessonProgress.ProgressStatus.COMPLETED:
                progress.completed_at = now
                update_fields.append('completed_at')

            progress.save(update_fields=update_fields)
        elif created:
            if new_status == LessonProgress.ProgressStatus.IN_PROGRESS:
                progress.started_at = now
                progress.save(update_fields=['started_at'])
            elif new_status == LessonProgress.ProgressStatus.COMPLETED:
                progress.started_at = progress.started_at or now
                progress.completed_at = now
                progress.save(update_fields=['started_at', 'completed_at'])

        # Check if course is completed
        ClassroomService._check_course_completion(enrollment)
        return progress

    @staticmethod
    def _check_course_completion(enrollment: CourseEnrollment) -> None:
        """Mark course as completed if all lessons are done."""
        total_lessons = enrollment.course.lessons.count()
        if total_lessons == 0:
            return

        completed_lessons = enrollment.lesson_progress.filter(
            status=LessonProgress.ProgressStatus.COMPLETED,
        ).count()

        if completed_lessons >= total_lessons and not enrollment.completed_at:
            enrollment.completed_at = timezone.now()
            enrollment.save(update_fields=['completed_at'])
            logger.info(
                "User %s completed course %s",
                enrollment.user.email,
                enrollment.course.title,
            )

    @staticmethod
    def get_course_progress(enrollment: CourseEnrollment) -> dict[str, int]:
        """Return progress summary for a course enrollment."""
        total = enrollment.course.lessons.count()
        completed = enrollment.lesson_progress.filter(
            status=LessonProgress.ProgressStatus.COMPLETED,
        ).count()
        in_progress = enrollment.lesson_progress.filter(
            status=LessonProgress.ProgressStatus.IN_PROGRESS,
        ).count()
        return {
            'total_lessons': total,
            'completed': completed,
            'in_progress': in_progress,
            'not_started': total - completed - in_progress,
            'percent_complete': round((completed / total * 100) if total > 0 else 0),
        }
