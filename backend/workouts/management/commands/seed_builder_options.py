"""Seed the full split library and expanded set structure modalities from the UI/UX spec."""
from django.core.management.base import BaseCommand

from workouts.models import SetStructureModality, SplitTemplate


class Command(BaseCommand):
    help = 'Seed split templates and set structure modalities per the UI/UX spec.'

    def handle(self, *args: object, **options: object) -> None:
        self._seed_split_templates()
        self._seed_modalities()
        self.stdout.write(self.style.SUCCESS('Builder options seeded.'))

    def _seed_split_templates(self) -> None:
        """Seed the full 24-type split library from the UI/UX spec."""
        templates = [
            # Group 1
            {'name': 'Full Body', 'days': 3, 'goal': 'general_fitness', 'defs': [
                {'label': 'Full Body A', 'muscle_groups': ['chest', 'back', 'quadriceps', 'shoulders']},
                {'label': 'Full Body B', 'muscle_groups': ['chest', 'back', 'hamstrings', 'shoulders']},
                {'label': 'Full Body C', 'muscle_groups': ['chest', 'back', 'glutes', 'shoulders']},
            ]},
            {'name': 'Push / Pull / Legs', 'days': 3, 'goal': 'build_muscle', 'defs': [
                {'label': 'Push', 'muscle_groups': ['chest', 'shoulders', 'triceps']},
                {'label': 'Pull', 'muscle_groups': ['back', 'biceps']},
                {'label': 'Legs', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
            ]},
            {'name': 'PPL (6-Day)', 'days': 6, 'goal': 'build_muscle', 'defs': [
                {'label': 'Push A', 'muscle_groups': ['chest', 'shoulders', 'triceps']},
                {'label': 'Pull A', 'muscle_groups': ['back', 'biceps']},
                {'label': 'Legs A', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
                {'label': 'Push B', 'muscle_groups': ['chest', 'shoulders', 'triceps']},
                {'label': 'Pull B', 'muscle_groups': ['back', 'biceps']},
                {'label': 'Legs B', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
            ]},
            {'name': 'Anterior / Posterior', 'days': 4, 'goal': 'build_muscle', 'defs': [
                {'label': 'Anterior A', 'muscle_groups': ['chest', 'quadriceps', 'shoulders']},
                {'label': 'Posterior A', 'muscle_groups': ['back', 'hamstrings', 'glutes']},
                {'label': 'Anterior B', 'muscle_groups': ['chest', 'quadriceps', 'triceps']},
                {'label': 'Posterior B', 'muscle_groups': ['back', 'hamstrings', 'biceps']},
            ]},
            {'name': 'Body-Part Split', 'days': 5, 'goal': 'build_muscle', 'defs': [
                {'label': 'Chest', 'muscle_groups': ['chest']},
                {'label': 'Back', 'muscle_groups': ['back']},
                {'label': 'Shoulders & Arms', 'muscle_groups': ['shoulders', 'biceps', 'triceps']},
                {'label': 'Legs', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
                {'label': 'Weak Points', 'muscle_groups': ['chest', 'back', 'shoulders']},
            ]},
            {'name': 'Heavy / Light / Medium', 'days': 3, 'goal': 'strength', 'defs': [
                {'label': 'Heavy', 'muscle_groups': ['chest', 'back', 'quadriceps']},
                {'label': 'Light', 'muscle_groups': ['shoulders', 'biceps', 'triceps']},
                {'label': 'Medium', 'muscle_groups': ['chest', 'back', 'hamstrings']},
            ]},
            {'name': 'Conjugate Split', 'days': 4, 'goal': 'strength', 'defs': [
                {'label': 'Max Effort Upper', 'muscle_groups': ['chest', 'shoulders', 'triceps']},
                {'label': 'Max Effort Lower', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
                {'label': 'Dynamic Effort Upper', 'muscle_groups': ['chest', 'shoulders', 'back']},
                {'label': 'Dynamic Effort Lower', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
            ]},
            # Group 2
            {'name': 'Full Body Alternating Emphasis', 'days': 3, 'goal': 'general_fitness', 'defs': [
                {'label': 'Upper Emphasis Full Body', 'muscle_groups': ['chest', 'back', 'shoulders', 'quadriceps']},
                {'label': 'Lower Emphasis Full Body', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes', 'back']},
                {'label': 'Balanced Full Body', 'muscle_groups': ['chest', 'back', 'quadriceps', 'shoulders']},
            ]},
            {'name': 'Push / Pull', 'days': 4, 'goal': 'build_muscle', 'defs': [
                {'label': 'Push A', 'muscle_groups': ['chest', 'shoulders', 'triceps', 'quadriceps']},
                {'label': 'Pull A', 'muscle_groups': ['back', 'biceps', 'hamstrings']},
                {'label': 'Push B', 'muscle_groups': ['chest', 'shoulders', 'triceps', 'quadriceps']},
                {'label': 'Pull B', 'muscle_groups': ['back', 'biceps', 'hamstrings']},
            ]},
            {'name': 'Movement-Pattern Split', 'days': 4, 'goal': 'strength', 'defs': [
                {'label': 'Squat Day', 'muscle_groups': ['quadriceps', 'glutes']},
                {'label': 'Bench Day', 'muscle_groups': ['chest', 'shoulders', 'triceps']},
                {'label': 'Deadlift Day', 'muscle_groups': ['hamstrings', 'back', 'glutes']},
                {'label': 'Overhead Day', 'muscle_groups': ['shoulders', 'triceps', 'back']},
            ]},
            {'name': 'Specialization Split', 'days': 5, 'goal': 'build_muscle', 'defs': [
                {'label': 'Specialization A', 'muscle_groups': ['chest']},
                {'label': 'Lower', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
                {'label': 'Back & Arms', 'muscle_groups': ['back', 'biceps', 'triceps']},
                {'label': 'Specialization B', 'muscle_groups': ['chest']},
                {'label': 'Full Body Light', 'muscle_groups': ['shoulders', 'back', 'quadriceps']},
            ]},
            {'name': 'Block Split', 'days': 3, 'goal': 'strength', 'defs': [
                {'label': 'Accumulation', 'muscle_groups': ['chest', 'back', 'quadriceps']},
                {'label': 'Intensification', 'muscle_groups': ['chest', 'back', 'hamstrings']},
                {'label': 'Realization', 'muscle_groups': ['chest', 'back', 'quadriceps']},
            ]},
            {'name': 'DUP Split', 'days': 3, 'goal': 'strength', 'defs': [
                {'label': 'Hypertrophy Day', 'muscle_groups': ['chest', 'back', 'quadriceps', 'shoulders']},
                {'label': 'Strength Day', 'muscle_groups': ['chest', 'back', 'quadriceps', 'shoulders']},
                {'label': 'Power Day', 'muscle_groups': ['chest', 'back', 'quadriceps', 'shoulders']},
            ]},
            {'name': 'Event-Based Split', 'days': 4, 'goal': 'endurance', 'defs': [
                {'label': 'Strength', 'muscle_groups': ['chest', 'back', 'quadriceps']},
                {'label': 'Conditioning A', 'muscle_groups': ['quadriceps', 'hamstrings']},
                {'label': 'Power', 'muscle_groups': ['shoulders', 'back', 'glutes']},
                {'label': 'Conditioning B', 'muscle_groups': ['quadriceps', 'hamstrings']},
            ]},
            # Group 3
            {'name': 'Upper / Lower', 'days': 4, 'goal': 'build_muscle', 'defs': [
                {'label': 'Upper A', 'muscle_groups': ['chest', 'back', 'shoulders']},
                {'label': 'Lower A', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
                {'label': 'Upper B', 'muscle_groups': ['chest', 'back', 'shoulders']},
                {'label': 'Lower B', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
            ]},
            {'name': 'Torso / Limbs', 'days': 4, 'goal': 'build_muscle', 'defs': [
                {'label': 'Torso A', 'muscle_groups': ['chest', 'back']},
                {'label': 'Limbs A', 'muscle_groups': ['quadriceps', 'hamstrings', 'biceps', 'triceps']},
                {'label': 'Torso B', 'muscle_groups': ['chest', 'back', 'shoulders']},
                {'label': 'Limbs B', 'muscle_groups': ['quadriceps', 'hamstrings', 'biceps', 'triceps']},
            ]},
            {'name': 'Lift-Specific Split', 'days': 4, 'goal': 'strength', 'defs': [
                {'label': 'Squat', 'muscle_groups': ['quadriceps', 'glutes']},
                {'label': 'Bench', 'muscle_groups': ['chest', 'triceps']},
                {'label': 'Deadlift', 'muscle_groups': ['hamstrings', 'back', 'glutes']},
                {'label': 'Overhead Press', 'muscle_groups': ['shoulders', 'triceps']},
            ]},
            {'name': 'Athletic Quality Split', 'days': 4, 'goal': 'general_fitness', 'defs': [
                {'label': 'Max Strength', 'muscle_groups': ['chest', 'back', 'quadriceps']},
                {'label': 'Speed & Power', 'muscle_groups': ['glutes', 'hamstrings', 'shoulders']},
                {'label': 'Conditioning', 'muscle_groups': ['quadriceps', 'hamstrings']},
                {'label': 'Hypertrophy & Recovery', 'muscle_groups': ['chest', 'back', 'shoulders']},
            ]},
            {'name': 'Concurrent Split', 'days': 4, 'goal': 'general_fitness', 'defs': [
                {'label': 'Strength + Conditioning A', 'muscle_groups': ['chest', 'back', 'quadriceps']},
                {'label': 'Hypertrophy A', 'muscle_groups': ['shoulders', 'biceps', 'triceps']},
                {'label': 'Strength + Conditioning B', 'muscle_groups': ['hamstrings', 'glutes', 'back']},
                {'label': 'Hypertrophy B', 'muscle_groups': ['chest', 'shoulders', 'triceps']},
            ]},
            {'name': 'Rehab / Return-to-Play', 'days': 3, 'goal': 'general_fitness', 'defs': [
                {'label': 'Tolerance A', 'muscle_groups': ['quadriceps', 'glutes']},
                {'label': 'Tolerance B', 'muscle_groups': ['chest', 'back', 'shoulders']},
                {'label': 'Graded Exposure', 'muscle_groups': ['quadriceps', 'hamstrings', 'glutes']},
            ]},
        ]

        created = 0
        for t in templates:
            _, was_created = SplitTemplate.objects.update_or_create(
                name=t['name'],
                is_system=True,
                defaults={
                    'days_per_week': t['days'],
                    'session_definitions': t['defs'],
                    'goal_type': t['goal'],
                },
            )
            if was_created:
                created += 1

        self.stdout.write(f'  Split templates: {created} created, {len(templates) - created} updated')

    def _seed_modalities(self) -> None:
        """Seed expanded set structure modalities per the UI/UX spec."""
        modalities = [
            # Strength & quality
            {'name': 'Cluster Sets', 'slug': 'cluster-sets', 'mult': 1.0,
             'desc': 'Break a heavy set into mini-clusters with brief intra-set rest (10-20s).'},
            {'name': 'Wave Sets', 'slug': 'wave-sets', 'mult': 1.0,
             'desc': 'Ascending or wave-loading scheme (e.g., 3-2-1-3-2-1).'},
            {'name': 'Ramping Sets', 'slug': 'ramping-sets', 'mult': 1.0,
             'desc': 'Progressively increase load each set to a top set.'},
            {'name': 'Back-Off Sets', 'slug': 'back-off-sets', 'mult': 1.0,
             'desc': 'Heavy top set followed by lighter volume sets.'},
            {'name': 'Paused Reps', 'slug': 'paused-reps', 'mult': 1.0,
             'desc': 'Deliberate pause at the bottom position for position ownership.'},
            {'name': 'Dead-Stop Reps', 'slug': 'dead-stop-reps', 'mult': 1.0,
             'desc': 'Full reset between reps — eliminates stretch reflex.'},
            # Hypertrophy & density
            {'name': 'Rest-Pause', 'slug': 'rest-pause', 'mult': 0.67,
             'desc': 'Take a set to near-failure, rest 10-15s, continue for more reps.'},
            {'name': 'Tempo Reps', 'slug': 'tempo-reps', 'mult': 1.0,
             'desc': 'Controlled eccentric (3-5s) for time under tension.'},
            {'name': 'Mechanical Drop Sets', 'slug': 'mechanical-drop-sets', 'mult': 0.67,
             'desc': 'Change leverage/grip instead of weight to extend the set.'},
            {'name': 'Lengthened Partials', 'slug': 'lengthened-partials', 'mult': 0.67,
             'desc': 'Partial reps in the lengthened (stretched) position after full-ROM failure.'},
            # Pacing
            {'name': 'EMOM', 'slug': 'emom', 'mult': 1.0,
             'desc': 'Every Minute On the Minute — fixed work interval with built-in rest.'},
            {'name': 'AMRAP', 'slug': 'amrap', 'mult': 1.0,
             'desc': 'As Many Reps/Rounds As Possible in a fixed time window.'},
            {'name': 'Ascending Ladder', 'slug': 'ascending-ladder', 'mult': 1.0,
             'desc': 'Reps increase each set (1-2-3-4-5...).'},
            {'name': 'Descending Ladder', 'slug': 'descending-ladder', 'mult': 1.0,
             'desc': 'Reps decrease each set (10-8-6-4-2).'},
        ]

        created = 0
        for m in modalities:
            _, was_created = SetStructureModality.objects.update_or_create(
                slug=m['slug'],
                defaults={
                    'name': m['name'],
                    'description': m['desc'],
                    'volume_multiplier': m['mult'],
                    'is_system': True,
                },
            )
            if was_created:
                created += 1

        self.stdout.write(f'  Modalities: {created} created, {len(modalities) - created} updated')
