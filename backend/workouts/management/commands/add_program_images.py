"""
Management command to add image URLs to programs and program templates.
Uses verified working Unsplash fitness images based on goal type.
"""
from __future__ import annotations

from typing import Any

from django.core.management.base import BaseCommand

from workouts.models import Program, ProgramTemplate


class Command(BaseCommand):
    help = 'Adds image URLs to all programs and program templates in the database'

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            '--force',
            action='store_true',
            help='Update all images even if already set',
        )

    def handle(self, *args: Any, **options: Any) -> None:
        force = options.get('force', False)

        # Verified working Unsplash images by goal type
        goal_type_images = {
            # Build Muscle - muscular person doing weights
            'build_muscle': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&q=80',
            # Fat Loss - person running/cardio
            'fat_loss': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&q=80',
            # Strength - person deadlifting/powerlifting
            'strength': 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&q=80',
            # Endurance - person running
            'endurance': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=400&q=80',
            # Body Recomposition - person with dumbbells
            'recomp': 'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=400&q=80',
            # General Fitness - gym workout scene
            'general_fitness': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80',
        }

        # Default fallback image
        default_image = 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80'

        # Update ProgramTemplates
        template_updated = 0
        for template in ProgramTemplate.objects.all():
            if template.image_url and not force:
                continue

            image_url = goal_type_images.get(template.goal_type, default_image)
            template.image_url = image_url
            template.save(update_fields=['image_url'])
            template_updated += 1

        # Update Programs (inherit goal from template or use default)
        program_updated = 0
        for program in Program.objects.all():
            if program.image_url and not force:
                continue

            # Try to infer goal from program name or use default
            program_name_lower = program.name.lower()
            if 'muscle' in program_name_lower or 'hypertrophy' in program_name_lower or 'mass' in program_name_lower:
                image_url = goal_type_images['build_muscle']
            elif 'fat' in program_name_lower or 'cut' in program_name_lower or 'lean' in program_name_lower or 'weight loss' in program_name_lower:
                image_url = goal_type_images['fat_loss']
            elif 'strength' in program_name_lower or 'power' in program_name_lower:
                image_url = goal_type_images['strength']
            elif 'endurance' in program_name_lower or 'cardio' in program_name_lower or 'marathon' in program_name_lower:
                image_url = goal_type_images['endurance']
            elif 'recomp' in program_name_lower:
                image_url = goal_type_images['recomp']
            else:
                image_url = goal_type_images['general_fitness']

            program.image_url = image_url
            program.save(update_fields=['image_url'])
            program_updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Updated images for {template_updated} program templates and {program_updated} programs.'
            )
        )
