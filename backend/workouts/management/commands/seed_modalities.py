"""
Seed system set structure modalities and their guardrails.

Based on v6.5 packet Section 6: Set-Structure Modality Rules.
"""
from decimal import Decimal

from django.core.management.base import BaseCommand

from workouts.models import ModalityGuardrail, SetStructureModality


SYSTEM_MODALITIES = [
    {
        'name': 'Straight Sets',
        'slug': 'straight-sets',
        'description': 'Standard working sets with consistent weight and rep target. The default for most training.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Heavy sets (5-10 reps)', 'Most training in general'],
        'avoid_when': ['Metabolite training (20-30 reps) may benefit from other modalities'],
    },
    {
        'name': 'Down Sets',
        'slug': 'down-sets',
        'description': 'Additional sets at reduced weight after heavy top sets. Used when heavy sets drop below 5 reps.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Heavy sets drop below 5 reps per set', 'Load is too high for intended hypertrophy rep range'],
        'avoid_when': ['Can keep same weight and stay in target rep range'],
    },
    {
        'name': 'Controlled Eccentrics',
        'slug': 'controlled-eccentrics',
        'description': 'Emphasis on slow, controlled eccentric (lowering) phase. Useful for technique and injury prevention.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Technique improvement', 'Injury management or prevention'],
        'avoid_when': ['Sets of 20+ reps (avoid stacking tempo difficulty on high-rep hypertrophy)'],
    },
    {
        'name': 'Giant Sets',
        'slug': 'giant-sets',
        'description': 'Multiple exercises performed back-to-back targeting the same muscle. For advanced trainees with stable volume landmarks.',
        'volume_multiplier': Decimal('0.67'),
        'use_when': ['User knows volume landmarks well', 'Focus on technique and mind-muscle connection'],
        'avoid_when': ["User doesn't know volume landmarks well (tracking difficult)"],
    },
    {
        'name': 'Myo-reps',
        'slug': 'myo-reps',
        'description': 'Activation set followed by short rest mini-sets. Time-efficient for isolation work.',
        'volume_multiplier': Decimal('0.67'),
        'use_when': ['Short on time', 'Exercise is not very systemically fatiguing'],
        'avoid_when': ['Mind-muscle connection and technique are the big focus', 'Systemic fatigue from exercise is high'],
    },
    {
        'name': 'Drop Sets',
        'slug': 'drop-sets',
        'description': 'Reduce weight and continue reps after reaching failure. Drives metabolite accumulation.',
        'volume_multiplier': Decimal('0.67'),
        'use_when': ['Driving metabolites', 'Usually on isolation or machine movements'],
        'avoid_when': ['Movement is systemically fatiguing AND performed in heavy (5-10) rep range'],
    },
    {
        'name': 'Supersets',
        'slug': 'supersets',
        'description': 'Two exercises performed back-to-back. Pre-exhaust (same muscle) or non-overlapping (different muscles).',
        'volume_multiplier': Decimal('2.00'),
        'use_when': ['Pre-exhaust: hard-to-isolate muscles', 'Non-overlapping: limited time'],
        'avoid_when': ['When mind-muscle connection, technique, or performance are the focus'],
    },
    {
        'name': 'Occlusion Training',
        'slug': 'occlusion',
        'description': 'Blood flow restriction training. Drives metabolites with light loads. For injury rehab or metabolite work.',
        'volume_multiplier': Decimal('0.67'),
        'use_when': ['Injury rehab or return from injury', 'Driving metabolites with light loads'],
        'avoid_when': ['Compound moves', 'Core exercises', 'Longer than one mesocycle per muscle group'],
    },
    # v6.5 UI/UX Packet §6 — Additional modalities
    {
        'name': '1.5 Reps',
        'slug': '1-5-reps',
        'description': 'Full rep + half rep = one count. Increases time under tension at the hardest range.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Hypertrophy with lengthened emphasis', 'Building bottom-range strength'],
        'avoid_when': ['Heavy strength sets (5 reps or fewer)', 'Exercises with poor bottom control'],
    },
    {
        'name': 'Iso-Hold + Reps',
        'slug': 'iso-hold-reps',
        'description': 'Static hold at a weak point, then complete prescribed reps. Builds position ownership.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Tendon tolerance', 'Position ownership at weak point', 'Rehab exposure'],
        'avoid_when': ['Very heavy loads', 'Exercises where hold position is unsafe'],
    },
    {
        'name': 'Burnout Sets',
        'slug': 'burnout-sets',
        'description': 'Final set taken to technical failure after working sets. High fatigue, pump-focused.',
        'volume_multiplier': Decimal('0.67'),
        'use_when': ['End of isolation work', 'Pump / metabolite accumulation'],
        'avoid_when': ['Main compound lifts', 'Exercises with injury risk at failure'],
    },
    {
        'name': 'Widowmaker Sets',
        'slug': 'widowmaker',
        'description': 'Single high-rep set (typically 20+ reps). Extreme metabolic stress and mental toughness.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['End of session finisher', 'Metabolic conditioning on safe exercises'],
        'avoid_when': ['Technical lifts', 'Exercises with high spinal load'],
    },
    {
        'name': 'E2MOM',
        'slug': 'e2mom',
        'description': 'Every 2 Minutes On the Minute. Longer recovery between clusters for heavier work.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Moderate-heavy strength work with controlled density', 'Compound movements'],
        'avoid_when': ['Very light isolation work (EMOM suffices)'],
    },
    {
        'name': 'AMQR',
        'slug': 'amqr',
        'description': 'As Many Quality Reps. Stop when rep quality degrades, not at a fixed number.',
        'volume_multiplier': Decimal('1.00'),
        'use_when': ['Technical work', 'Autoregulated volume', 'Skill-based movements'],
        'avoid_when': ['Users who struggle to self-regulate effort'],
    },
]


GUARDRAILS = [
    # Athletic movements cannot use drop sets, myo-reps
    {
        'modality_slug': 'drop-sets',
        'rule_type': 'avoid',
        'condition_field': 'exercise.athletic_skill_tags',
        'condition_operator': 'has_any',
        'condition_value': [
            'jump_vertical', 'jump_horizontal', 'jump_lateral',
            'hop_single_leg_vertical', 'hop_single_leg_horizontal',
            'bound_alternating', 'landing_and_deceleration',
            'sprint_acceleration', 'sprint_max_velocity',
            'change_of_direction_cut', 'shuffle_and_lateral',
            'olympic_lift_derivative',
        ],
        'error_message': 'Drop sets cannot be used with athletic/explosive movements.',
    },
    {
        'modality_slug': 'myo-reps',
        'rule_type': 'avoid',
        'condition_field': 'exercise.athletic_skill_tags',
        'condition_operator': 'has_any',
        'condition_value': [
            'jump_vertical', 'jump_horizontal', 'jump_lateral',
            'hop_single_leg_vertical', 'hop_single_leg_horizontal',
            'bound_alternating', 'landing_and_deceleration',
            'sprint_acceleration', 'sprint_max_velocity',
            'change_of_direction_cut', 'shuffle_and_lateral',
            'olympic_lift_derivative',
        ],
        'error_message': 'Myo-reps cannot be used with athletic/explosive movements.',
    },
    # Heavy compounds (5-10 rep range) cannot use drop sets
    {
        'modality_slug': 'drop-sets',
        'rule_type': 'avoid',
        'condition_field': 'slot.slot_role',
        'condition_operator': 'in',
        'condition_value': ['primary_compound', 'secondary_compound'],
        'error_message': 'Drop sets should not be used on compound movements in the heavy rep range.',
    },
    # Controlled eccentrics avoid 20+ rep sets
    {
        'modality_slug': 'controlled-eccentrics',
        'rule_type': 'avoid',
        'condition_field': 'slot.reps_max',
        'condition_operator': 'gt',
        'condition_value': 20,
        'error_message': 'Controlled eccentrics should not be used with 20+ rep sets.',
    },
    # Occlusion avoid on compounds
    {
        'modality_slug': 'occlusion',
        'rule_type': 'avoid',
        'condition_field': 'slot.slot_role',
        'condition_operator': 'in',
        'condition_value': ['primary_compound', 'secondary_compound'],
        'error_message': 'Occlusion training should not be used on compound movements.',
    },
]


class Command(BaseCommand):
    help = 'Seed system set structure modalities and guardrails (v6.5 Step 6).'

    def handle(self, *args: object, **options: object) -> None:
        created_count = 0
        updated_count = 0

        modality_map: dict[str, SetStructureModality] = {}

        for data in SYSTEM_MODALITIES:
            modality, created = SetStructureModality.objects.update_or_create(
                slug=data['slug'],
                defaults={
                    'name': data['name'],
                    'description': data['description'],
                    'volume_multiplier': data['volume_multiplier'],
                    'use_when': data['use_when'],
                    'avoid_when': data['avoid_when'],
                    'is_system': True,
                },
            )
            modality_map[data['slug']] = modality
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f"  Created: {data['name']}"))
            else:
                updated_count += 1
                self.stdout.write(f"  Updated: {data['name']}")

        # Seed guardrails
        guardrail_count = 0
        for g_data in GUARDRAILS:
            modality = modality_map.get(g_data['modality_slug'])
            if not modality:
                self.stdout.write(self.style.WARNING(
                    f"  Skipping guardrail for unknown modality: {g_data['modality_slug']}"
                ))
                continue

            _, g_created = ModalityGuardrail.objects.update_or_create(
                modality=modality,
                condition_field=g_data['condition_field'],
                condition_operator=g_data['condition_operator'],
                defaults={
                    'rule_type': g_data['rule_type'],
                    'condition_value': g_data['condition_value'],
                    'error_message': g_data['error_message'],
                    'is_active': True,
                },
            )
            if g_created:
                guardrail_count += 1

        self.stdout.write(self.style.SUCCESS(
            f"\nDone! Modalities: {created_count} created, {updated_count} updated. "
            f"Guardrails: {guardrail_count} created."
        ))
