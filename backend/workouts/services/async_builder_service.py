"""
Async Builder Service — runs quick_build in a background thread with cache-based status tracking.

Flow:
  1. POST quick-build/ calls start_quick_build_task() -> returns task_id immediately
  2. Background thread runs quick_build() and writes result/error to cache
  3. GET quick-build/<task_id>/status/ calls get_task_status() -> returns current state
"""
from __future__ import annotations

import logging
import threading
import uuid
from dataclasses import asdict, dataclass, field
from typing import Any

from django.core.cache import cache

logger = logging.getLogger(__name__)

_CACHE_PREFIX = 'builder_task'
_CACHE_TIMEOUT = 1800  # 30 minutes


@dataclass
class AsyncTaskStatus:
    """Serializable status object stored in cache."""
    status: str  # pending, running, completed, failed
    result: dict[str, Any] | None = None
    error: str | None = None
    progress_step: str | None = None
    completed_steps: list[str] = field(default_factory=list)


def start_quick_build_task(brief: Any) -> str:
    """Start a quick build in a background thread. Returns task_id immediately."""
    task_id = str(uuid.uuid4())
    cache.set(
        f'{_CACHE_PREFIX}:{task_id}',
        asdict(AsyncTaskStatus(status='pending')),
        timeout=_CACHE_TIMEOUT,
    )

    thread = threading.Thread(
        target=_run_quick_build,
        args=(task_id, brief),
        daemon=True,
    )
    thread.start()
    return task_id


def get_task_status(task_id: str) -> AsyncTaskStatus | None:
    """Read task status from cache. Returns None if not found/expired."""
    data = cache.get(f'{_CACHE_PREFIX}:{task_id}')
    if data is None:
        return None
    return AsyncTaskStatus(**data)


def _update_progress(task_id: str, step: str) -> None:
    """Append a completed step and set the current progress step."""
    data = cache.get(f'{_CACHE_PREFIX}:{task_id}')
    completed: list[str] = []
    if data and data.get('completed_steps'):
        completed = list(data['completed_steps'])
    # Move the previous progress_step to completed
    if data and data.get('progress_step'):
        completed.append(data['progress_step'])
    cache.set(
        f'{_CACHE_PREFIX}:{task_id}',
        asdict(AsyncTaskStatus(
            status='running',
            progress_step=step,
            completed_steps=completed,
        )),
        timeout=_CACHE_TIMEOUT,
    )


def _run_quick_build(task_id: str, brief: Any) -> None:
    """Background thread: run the full quick_build pipeline and store result."""
    from django.db import connection

    try:
        _update_progress(task_id, 'Starting build...')

        from workouts.services.builder_service import quick_build
        result = quick_build(brief, progress_callback=lambda step: _update_progress(task_id, step))

        result_dict = {
            'plan_id': result.plan_id,
            'plan_name': result.plan_name,
            'weeks_count': result.weeks_count,
            'sessions_count': result.sessions_count,
            'slots_count': result.slots_count,
            'decision_log_ids': result.decision_log_ids,
            'summary': result.summary,
            'step_explanations': [
                {
                    'step_name': e.step_name,
                    'step_number': e.step_number,
                    'recommendation': e.recommendation,
                    'alternatives': e.alternatives,
                    'why': e.why,
                }
                for e in result.step_explanations
            ],
        }

        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='completed', result=result_dict)),
            timeout=_CACHE_TIMEOUT,
        )
        logger.info("Quick build task %s completed successfully.", task_id)

    except Exception as e:
        logger.exception("Quick build task %s failed.", task_id)
        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='failed', error=str(e))),
            timeout=_CACHE_TIMEOUT,
        )
    finally:
        connection.close()


def start_curated_nutrition_task(
    trainee_id: int,
    trainer_id: int,
    trainer_notes: str = '',
    override_template_type: str = '',
    override_goal: str = '',
) -> str:
    """Start a curated nutrition build in a background thread. Returns task_id immediately."""
    task_id = str(uuid.uuid4())
    cache.set(
        f'{_CACHE_PREFIX}:{task_id}',
        asdict(AsyncTaskStatus(status='pending')),
        timeout=_CACHE_TIMEOUT,
    )

    thread = threading.Thread(
        target=_run_curated_nutrition,
        args=(task_id, trainee_id, trainer_id, trainer_notes, override_template_type, override_goal),
        daemon=True,
    )
    thread.start()
    return task_id


def _run_curated_nutrition(
    task_id: str,
    trainee_id: int,
    trainer_id: int,
    trainer_notes: str,
    override_template_type: str,
    override_goal: str,
) -> None:
    """Background thread: run curated_nutrition_build and store result."""
    from django.db import connection

    try:
        _update_progress(task_id, 'Starting curated nutrition build...')

        from workouts.services.nutrition_plan_service import curated_nutrition_build
        result = curated_nutrition_build(
            trainee_id=trainee_id,
            trainer_id=trainer_id,
            trainer_notes=trainer_notes,
            override_template_type=override_template_type,
            override_goal=override_goal,
            progress_callback=lambda step: _update_progress(task_id, step),
        )

        result_dict = {
            'assignment_id': result.assignment_id,
            'template_type': result.template_type,
            'template_name': result.template_name,
            'weekly_preview': result.weekly_preview,
            'reasoning': result.reasoning,
            'decision_log_id': result.decision_log_id,
        }

        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='completed', result=result_dict)),
            timeout=_CACHE_TIMEOUT,
        )
        logger.info("Curated nutrition task %s completed successfully.", task_id)

    except Exception as e:
        logger.exception("Curated nutrition task %s failed.", task_id)
        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='failed', error=str(e))),
            timeout=_CACHE_TIMEOUT,
        )
    finally:
        connection.close()


def start_curated_build_task(
    brief: Any,
    trainee_context: Any,
    trainer_notes: str = '',
) -> str:
    """Start a curated build in a background thread. Returns task_id immediately."""
    task_id = str(uuid.uuid4())
    cache.set(
        f'{_CACHE_PREFIX}:{task_id}',
        asdict(AsyncTaskStatus(status='pending')),
        timeout=_CACHE_TIMEOUT,
    )

    thread = threading.Thread(
        target=_run_curated_build,
        args=(task_id, brief, trainee_context, trainer_notes),
        daemon=True,
    )
    thread.start()
    return task_id


def _run_curated_build(
    task_id: str,
    brief: Any,
    trainee_context: Any,
    trainer_notes: str,
) -> None:
    """Background thread: run curated_build pipeline and store result."""
    from django.db import connection

    try:
        _update_progress(task_id, 'Starting curated build...')

        from workouts.services.builder_service import curated_build
        result = curated_build(
            brief,
            trainee_context,
            trainer_notes,
            progress_callback=lambda step: _update_progress(task_id, step),
        )

        result_dict = {
            'plan_id': result.plan_id,
            'plan_name': result.plan_name,
            'weeks_count': result.weeks_count,
            'sessions_count': result.sessions_count,
            'slots_count': result.slots_count,
            'decision_log_ids': result.decision_log_ids,
            'summary': result.summary,
            'step_explanations': [
                {
                    'step_name': e.step_name,
                    'step_number': e.step_number,
                    'recommendation': e.recommendation,
                    'alternatives': e.alternatives,
                    'why': e.why,
                }
                for e in result.step_explanations
            ],
        }

        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='completed', result=result_dict)),
            timeout=_CACHE_TIMEOUT,
        )
        logger.info("Curated build task %s completed successfully.", task_id)

    except Exception as e:
        logger.exception("Curated build task %s failed.", task_id)
        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='failed', error=str(e))),
            timeout=_CACHE_TIMEOUT,
        )
    finally:
        connection.close()


def start_advance_task(plan_id: str, override: dict[str, Any] | None) -> str:
    """Start a builder advance step in a background thread. Returns task_id immediately."""
    task_id = str(uuid.uuid4())
    cache.set(
        f'{_CACHE_PREFIX}:{task_id}',
        asdict(AsyncTaskStatus(status='pending')),
        timeout=_CACHE_TIMEOUT,
    )

    thread = threading.Thread(
        target=_run_advance,
        args=(task_id, plan_id, override),
        daemon=True,
    )
    thread.start()
    return task_id


def _run_advance(task_id: str, plan_id: str, override: dict[str, Any] | None) -> None:
    """Background thread: run builder_advance and store result."""
    from django.db import connection

    try:
        _update_progress(task_id, 'Processing step...')

        from workouts.models import TrainingPlan
        from workouts.services.builder_service import builder_advance

        plan = TrainingPlan.objects.get(pk=plan_id)
        result = builder_advance(plan, override)

        result_dict = {
            'plan_id': result.plan_id,
            'current_step': result.current_step,
            'current_step_number': result.current_step_number,
            'total_steps': result.total_steps,
            'recommendation': result.recommendation,
            'alternatives': result.alternatives,
            'why': result.why,
            'preview': result.preview,
            'is_complete': result.is_complete,
        }

        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='completed', result=result_dict)),
            timeout=_CACHE_TIMEOUT,
        )
        logger.info("Advance task %s completed successfully.", task_id)

    except Exception as e:
        logger.exception("Advance task %s failed.", task_id)
        cache.set(
            f'{_CACHE_PREFIX}:{task_id}',
            asdict(AsyncTaskStatus(status='failed', error=str(e))),
            timeout=_CACHE_TIMEOUT,
        )
    finally:
        connection.close()
