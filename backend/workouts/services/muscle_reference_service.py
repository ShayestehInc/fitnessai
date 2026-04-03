from __future__ import annotations

from dataclasses import dataclass

from workouts.models import Exercise, MuscleReference


@dataclass(frozen=True)
class MuscleReferenceResult:
    slug: str
    display_name: str
    latin_name: str
    body_region: str
    description: str
    origin: str
    insertion: str
    primary_movements: list[str]
    function_description: str
    training_tips: str
    common_exercises: list[str]
    sub_muscles: list[dict[str, str]]
    sort_order: int


class MuscleReferenceService:
    """Read operations for muscle reference data."""

    @staticmethod
    def get_all() -> list[MuscleReferenceResult]:
        refs = MuscleReference.objects.all()
        return [MuscleReferenceService._to_result(r) for r in refs]

    @staticmethod
    def get_by_slug(slug: str) -> MuscleReferenceResult | None:
        try:
            ref = MuscleReference.objects.get(slug=slug)
        except MuscleReference.DoesNotExist:
            return None
        return MuscleReferenceService._to_result(ref)

    @staticmethod
    def get_exercises_for_muscle(slug: str, limit: int = 50) -> list[Exercise]:
        """Return exercises that target this muscle (primary or via contribution map)."""
        from django.db.models import Q
        return list(
            Exercise.objects.filter(
                Q(primary_muscle_group=slug)
                | Q(secondary_muscle_groups__contains=[slug])
                | Q(muscle_contribution_map__has_key=slug)
            )
            .order_by('name')[:limit]
        )

    @staticmethod
    def _to_result(ref: MuscleReference) -> MuscleReferenceResult:
        return MuscleReferenceResult(
            slug=ref.slug,
            display_name=ref.display_name,
            latin_name=ref.latin_name,
            body_region=ref.body_region,
            description=ref.description,
            origin=ref.origin,
            insertion=ref.insertion,
            primary_movements=ref.primary_movements,
            function_description=ref.function_description,
            training_tips=ref.training_tips,
            common_exercises=ref.common_exercises,
            sub_muscles=ref.sub_muscles,
            sort_order=ref.sort_order,
        )
