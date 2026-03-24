"""
AI Prompts for Natural Language Logging and Program Generation.
All prompts are stored here as per project standards.
"""
from __future__ import annotations

from typing import Any


def get_natural_language_log_parsing_prompt(user_input: str, context: dict[str, Any] | None = None) -> str:
    """
    Generate prompt for parsing natural language workout/nutrition logs.
    
    Args:
        user_input: Raw user input string (e.g., "I ate a chicken bowl and did 3 sets of bench press at 225")
        context: Optional context about user's current program, recent logs, etc.
    
    Returns:
        Formatted prompt string for OpenAI
    """
    context_str = ""
    if context:
        context_str = f"""
User Context:
- Current Program: {context.get('program_name', 'None')}
- Recent Exercises: {', '.join(context.get('recent_exercises', []))}
"""
    
    prompt = f"""You are a fitness AI assistant that parses natural language input from users logging their workouts and nutrition.

User Input: "{user_input}"
{context_str}

Your task is to extract structured data from this input. The user may mention:
1. **Nutrition**: Food items, meals, calories, macros (protein, carbs, fat)
2. **Workouts**: Exercises, sets, reps, weight, units (lbs/kg)

Parse the input and return ONLY valid JSON in this exact structure:
{{
  "nutrition": {{
    "meals": [
      {{
        "name": "string (meal/food name)",
        "protein": number (grams),
        "carbs": number (grams),
        "fat": number (grams),
        "calories": number,
        "timestamp": "ISO 8601 timestamp or null"
      }}
    ]
  }},
  "workout": {{
    "exercises": [
      {{
        "exercise_name": "string (e.g., 'Bench Press')",
        "sets": number,
        "reps": number (or range like "8-10"),
        "weight": number,
        "unit": "lbs" or "kg",
        "timestamp": "ISO 8601 timestamp or null"
      }}
    ]
  }},
  "confidence": number (0-1, how confident you are in the parsing),
  "needs_clarification": boolean (true if input is ambiguous),
  "clarification_question": "string (if needs_clarification is true, ask what's unclear)"
}}

Rules:
- If nutrition is mentioned, extract it. If not, set "nutrition" to {{"meals": []}}
- If workout is mentioned, extract it. If not, set "workout" to {{"exercises": []}}
- For weight/rep ranges (e.g., "8-10 reps"), use the first number as default
- If unit is not specified, default to "lbs" for US users
- If timestamp is not mentioned, set to null
- Be conservative: if something is unclear, set needs_clarification=true

Return ONLY the JSON, no additional text."""
    
    return prompt


def get_exercise_classification_prompt(exercises: list[dict[str, str]]) -> str:
    """
    Generate prompt for classifying exercises by difficulty level AND training goals.

    Args:
        exercises: List of dicts with 'id', 'name', 'muscle_group', and optional 'category'.

    Returns:
        Formatted prompt string.
    """
    exercise_lines = "\n".join(
        f"- [id={ex.get('id', 'unknown')}] {ex['name']} (muscle_group: {ex['muscle_group']}, category: {ex.get('category', 'unknown')})"
        for ex in exercises
    )

    return f"""You are a certified strength & conditioning specialist with 20+ years of experience. Your job is to classify exercises by difficulty level AND which training goals each exercise is best suited for.

## DIFFICULTY LEVELS

Classify each exercise as exactly one of: "beginner", "intermediate", or "advanced".

- **beginner**: Machine-based exercises, cable exercises, bodyweight basics, guided movements, assisted variations. Low injury risk, minimal technique required. Examples: Leg Press, Cable Fly, Lat Pulldown, Smith Machine Squat, Assisted Chin-Up.
- **intermediate**: Free weight compound and isolation exercises with moderate technique requirements. Standard barbell and dumbbell work. Examples: Barbell Bench Press, Dumbbell Row, Romanian Deadlift, Barbell Curl, Pull-Ups.
- **advanced**: Complex multi-joint movements requiring significant technique, Olympic lifts, plyometrics, specialty exercises, unusual grip/stance variations, pin presses, deficit work. Examples: Snatch, Clean & Jerk, Pistol Squat, Muscle-Up, Deficit Deadlift, Thick Bar variations.

## TRAINING GOALS

For each exercise, select ALL applicable goals from this list:
- **build_muscle**: Exercises effective for hypertrophy — good time-under-tension, targets specific muscles, allows progressive overload. Most compound and isolation exercises qualify.
- **fat_loss**: Exercises that elevate heart rate, burn significant calories, or work well in circuit/superset formats. Compound movements, bodyweight exercises, kettlebell work.
- **strength**: Exercises that allow heavy loading and develop maximal force. Compound barbell movements, low-rep staples. NOT isolation exercises.
- **endurance**: Exercises suitable for high-rep, low-rest training. Bodyweight movements, cables, machines, light dumbbell work.
- **recomp**: Exercises effective for simultaneous muscle gain and fat loss — compound movements that build muscle while burning calories.
- **general_fitness**: Exercises suitable for overall health and functional fitness. Bodyweight basics, compound movements, balanced routines.

## EXERCISES TO CLASSIFY

{exercise_lines}

## OUTPUT FORMAT

Return ONLY valid JSON — an array of objects:
[
  {{
    "id": "123",
    "name": "Bench Press",
    "difficulty_level": "intermediate",
    "suitable_for_goals": ["build_muscle", "strength", "recomp"]
  }},
  {{
    "id": "456",
    "name": "Cable Fly",
    "difficulty_level": "beginner",
    "suitable_for_goals": ["build_muscle", "endurance", "general_fitness"]
  }}
]

## RULES

- Classify ALL {len(exercises)} exercises. Do not skip any.
- Include the exact "id" from the input.
- Each exercise must have exactly ONE difficulty_level.
- Each exercise must have 2-4 suitable_for_goals (most exercises suit multiple goals).
- When in doubt about difficulty, pick the lower level (safer for beginners).
- Return ONLY the JSON array. No markdown fences, no commentary."""


def get_program_generation_prompt(
    trainer_request: str,
    trainee_context: dict[str, Any],
    exercise_bank: list[dict[str, Any]]
) -> str:
    """
    Generate prompt for AI program generation from natural language.

    Args:
        trainer_request: Natural language request (e.g., "Create a 4-week hypertrophy block for a client with knee pain")
        trainee_context: Information about the trainee (goals, limitations, etc.)
        exercise_bank: List of available exercises from trainer's workout bank

    Returns:
        Formatted prompt string
    """
    exercise_list = "\n".join([f"- {ex['name']} ({ex['muscle_group']})" for ex in exercise_bank[:50]])

    prompt = f"""You are a fitness AI assistant helping a trainer create a personalized program for their client.

Trainer Request: "{trainer_request}"

Trainee Context:
- Goals: {trainee_context.get('goals', 'Not specified')}
- Limitations: {trainee_context.get('limitations', 'None')}
- Experience Level: {trainee_context.get('experience_level', 'Intermediate')}
- Training Frequency: {trainee_context.get('training_frequency', '3-4 days/week')}

Available Exercises (from Trainer's Workout Bank):
{exercise_list}

Create a structured training program that:
1. Matches the trainer's request
2. Uses exercises from the workout bank when possible
3. Follows progressive overload principles
4. Respects the trainee's limitations

Return ONLY valid JSON in this structure:
{{
  "name": "Program name",
  "description": "Brief description",
  "weeks": [
    {{
      "week_number": 1,
      "days": [
        {{
          "day": "Monday",
          "exercises": [
            {{
              "exercise_name": "string (must match an exercise from the bank)",
              "sets": number,
              "reps": number or string (e.g., "8-10"),
              "weight": number or null,
              "unit": "lbs" or "kg",
              "rest_seconds": number,
              "notes": "string (optional)"
            }}
          ]
        }}
      ]
    }}
  ]
}}

Return ONLY the JSON, no additional text."""

    return prompt


def get_structured_program_generation_prompt(
    split_type: str,
    difficulty: str,
    goal: str,
    duration_weeks: int,
    training_days_per_week: int,
    exercise_bank: list[dict[str, Any]],
    custom_day_config: list[dict[str, Any]] | None = None,
    training_days: list[str] | None = None,
) -> str:
    """
    Generate prompt for AI program generation following v6.5 philosophy.

    The AI generates a Week 1 template using tag-based exercise selection,
    slot roles, set structure modalities, and progression profile recommendations.
    The caller then programmatically expands the template across all weeks.

    Core v6.5 principles embedded in this prompt:
    - Tag-based exercise selection (pattern_tags, stance, plane, rom_bias)
    - Slot role hierarchy (primary_compound → secondary → accessory → isolation)
    - Set structure modalities with USE/AVOID rules
    - Progression profile recommendations
    - No "exercise difficulty levels" — use tags + constraints + guardrails
    - Every decision must be explainable and deterministic by default

    Args:
        split_type: One of ppl, upper_lower, full_body, bro_split, custom.
        difficulty: One of beginner, intermediate, advanced.
        goal: One of build_muscle, fat_loss, strength, endurance, recomp, general_fitness.
        duration_weeks: Program duration (1-52).
        training_days_per_week: Training days per week (2-7).
        exercise_bank: Available exercises with rich v6.5 tags.
        custom_day_config: For custom splits — list of dicts with label and muscle_groups.
        training_days: Explicit list of day names to train.

    Returns:
        Formatted prompt string.
    """
    split_labels = {
        'ppl': 'Push/Pull/Legs',
        'upper_lower': 'Upper/Lower',
        'full_body': 'Full Body',
        'bro_split': 'Bro Split',
        'custom': 'Custom Split',
    }
    goal_labels = {
        'build_muscle': 'Muscle Building / Hypertrophy',
        'fat_loss': 'Fat Loss / Cutting',
        'strength': 'Strength / Powerlifting',
        'endurance': 'Muscular Endurance',
        'recomp': 'Body Recomposition',
        'general_fitness': 'General Fitness',
    }

    # Format exercise bank with rich tags for tag-based selection
    exercise_bank_text = _format_exercise_bank_with_tags(exercise_bank)

    # Day structure description
    if custom_day_config:
        day_structure = "Custom day configuration:\n"
        for i, day_cfg in enumerate(custom_day_config, 1):
            day_structure += f"  Day {i}: {day_cfg.get('label', f'Day {i}')} — targets: {', '.join(day_cfg.get('muscle_groups', []))}\n"
    else:
        day_structure = f"Split type: {split_labels.get(split_type, split_type)}"

    # Explicit training day schedule
    if training_days:
        all_days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        training_set = set(training_days)
        schedule_lines = []
        for d in all_days:
            schedule_lines.append(f"  {d}: {'TRAINING' if d in training_set else 'REST'}")
        day_schedule = "Weekly schedule (user-selected):\n" + "\n".join(schedule_lines)
    else:
        day_schedule = f"Spread {training_days_per_week} training days across the week with rest days in between."

    return f"""You are a deterministic training plan engine following the v6.5 coaching operating system. You are NOT a generic fitness AI. You follow structured rules, use tags instead of subjective labels, and every choice you make must be explainable with a reason code.

## NON-NEGOTIABLE RULES

1. Everything is overrideable by trainer or user — you produce a DRAFT, not a final plan.
2. Default behavior is deterministic. No randomness unless explicitly enabled.
3. Do NOT use "exercise difficulty levels." They are subjective. Use tags + constraints + guardrails instead.
4. Exercise selection is based on pattern_tags, primary_muscle_group, stance, plane, rom_bias, and equipment — NOT exercise names or subjective difficulty.
5. Every exercise slot has a role: primary_compound, secondary_compound, accessory, or isolation. Slot role determines sets/reps/rest/intensity.
6. Only progress one knob at a time (load OR reps OR sets) unless the user is clearly under-challenged.
7. Cap hard sets per muscle/pattern: 8-20 per week depending on training age.

## YOUR TASK

Design Week 1 of a training program with these parameters:

- **Split:** {split_labels.get(split_type, split_type)}
- **Training Age Context:** {difficulty.title()} (use this to determine exercise complexity, volume, and which constraints to apply — NOT to filter exercises by a "difficulty" label)
- **Goal:** {goal_labels.get(goal, goal)}
- **Duration:** {duration_weeks} weeks
- **Training days/week:** {training_days_per_week}
- **{day_structure}**
- **{day_schedule}**

## EXERCISE BANK (with v6.5 tags)

Select exercises ONLY from this bank. Use the exact exercise ID. When tags are available, use them for selection. When tags are missing, fall back to muscle_group + category.
{exercise_bank_text}

## SLOT ROLE HIERARCHY (mandatory for every session)

Each training session must follow this slot ordering:

1. **primary_compound** (slots 1): The heaviest, most technically demanding compound movement for the session's target pattern. Highest intensity, longest rest.
2. **secondary_compound** (slot 2): A complementary compound that covers a different pattern or angle. Moderate intensity.
3. **accessory** (slots 3-4): Targeted work for muscle groups that need additional volume. Moderate load, controlled tempo.
4. **isolation** (slots 5+): Single-joint movements for lagging areas, pump work, or injury-prone muscles. Lower load, higher reps.

## TAG-BASED EXERCISE SELECTION RULES

When selecting exercises for each slot, reason about these tags (in order of priority):

1. **pattern_tags** — Match the session's movement intent. A "Push" day needs horizontal_push and vertical_push patterns. A "Pull" day needs horizontal_pull and vertical_pull. A "Legs" day needs knee_dominant and hip_dominant.
2. **primary_muscle_group** — Must match the session's target muscle groups.
3. **stance** — Vary stances across slots: e.g., bilateral_standing for compounds, split_squat_lunge or single_leg for accessories, seated_supported or prone for isolations.
4. **plane** — Ensure coverage across sagittal (most compounds), frontal (lateral work), and transverse (rotational) planes.
5. **rom_bias** — Mix lengthened bias (stretch-focused), mid_range, and shortened bias exercises within a session for complete stimulus.
6. **equipment_required** — Respect what's available. Don't stack exercises that compete for the same equipment.

## SET STRUCTURE MODALITIES (v6.5 rules)

For each exercise, select a set_structure from this list. Follow the USE/AVOID rules strictly:

- **straight_sets**: USE for heavy compound work (5-10 reps), most training. AVOID when goal is metabolite training (20-30 reps). Count: 1.0x per set.
- **down_sets**: USE when heavy sets drop below 5 reps and load is too high for hypertrophy rep range. AVOID when you could keep same weight and just lose reps. Count: 1.0x per set.
- **drop_sets**: USE for metabolite drive on isolation/machine movements. AVOID when movement is systemically fatiguing AND in heavy (5-10) rep range. Count: 0.67x per drop set.
- **supersets**: USE for pre-exhaust (hard-to-isolate muscles) or non-overlapping pairs (time-saving). AVOID when mind-muscle connection, technique, or performance are the focus. Count: pre-exhaust 2.0x, non-overlapping 2.0x total (1 per muscle).
- **myo_reps**: USE when short on time AND exercise is not systemically fatiguing. AVOID when mind-muscle connection is the focus OR systemic fatigue is high. Count: 0.67x per mini-set.
- **controlled_eccentrics**: USE for technique improvement or injury management/prevention. AVOID with 20+ reps (don't stack tempo difficulty on high-rep hypertrophy). Count: 1.0x per set.

**Engine enforcement rules:**
- If exercise is systemically fatiguing → ban drop_sets + myo_reps (unless explicitly allowed by coach)
- If reps are 20+ → ban controlled_eccentrics (for hypertrophy-focused work)
- primary_compound slots should default to straight_sets
- isolation slots are good candidates for drop_sets, myo_reps, or supersets

## SETS / REPS / REST BY GOAL AND SLOT ROLE

| Goal | Slot Role | Sets | Reps | Rest (sec) | Intensity (%TM) |
|------|-----------|------|------|------------|-----------------|
| build_muscle | primary_compound | 4 | 6-10 | 120 | 70-80% |
| build_muscle | secondary_compound | 3 | 8-12 | 90 | 65-75% |
| build_muscle | accessory | 3 | 10-15 | 60 | 60-70% |
| build_muscle | isolation | 3 | 12-15 | 45 | 55-65% |
| strength | primary_compound | 5 | 3-5 | 180 | 80-90% |
| strength | secondary_compound | 4 | 4-6 | 150 | 75-85% |
| strength | accessory | 3 | 6-8 | 90 | 65-75% |
| strength | isolation | 3 | 8-10 | 60 | 60-70% |
| fat_loss | primary_compound | 3 | 10-15 | 45 | 60-70% |
| fat_loss | secondary_compound | 3 | 12-15 | 45 | 55-65% |
| fat_loss | accessory | 3 | 12-20 | 30 | 50-60% |
| fat_loss | isolation | 2 | 15-20 | 30 | 45-55% |
| endurance | primary_compound | 3 | 15-20 | 30 | 50-60% |
| endurance | secondary_compound | 3 | 15-20 | 30 | 45-55% |
| endurance | accessory | 2 | 15-25 | 30 | 40-50% |
| endurance | isolation | 2 | 15-20 | 30 | 40-50% |
| recomp | primary_compound | 4 | 8-12 | 90 | 70-80% |
| recomp | secondary_compound | 3 | 8-12 | 75 | 65-75% |
| recomp | accessory | 3 | 10-15 | 60 | 60-70% |
| recomp | isolation | 3 | 12-15 | 45 | 55-65% |
| general_fitness | primary_compound | 3 | 8-12 | 75 | 65-75% |
| general_fitness | secondary_compound | 3 | 10-12 | 60 | 60-70% |
| general_fitness | accessory | 3 | 10-15 | 45 | 55-65% |
| general_fitness | isolation | 2 | 12-15 | 45 | 50-60% |

## REP BUCKET DISTRIBUTION (hypertrophy & GPP goals)

For build_muscle and general_fitness, target this weekly volume distribution:
- 50% of sets in 10-20 rep range (primary hypertrophy zone)
- 25% of sets in 5-10 rep range (mechanical tension zone)
- 25% of sets in 20-30 rep range (metabolite zone)

## TEMPO PRESETS (recommended defaults)

Select a tempo for each exercise based on intent. Format: E-P-C-P (eccentric-pause-concentric-pause, seconds). "X" means explosive.

- **Joint-friendly control**: 5-0-2-0 or 3-3-1-0 (reduce peak forces)
- **Power / speed intent**: 2-0-X-0 (controlled down, fast up)
- **Pause strength**: 2-3-X-0 (long pause in weakest position)
- **Hypertrophy (lengthened-bias)**: 4-1-1-1 (long eccentric + double pause + forceful concentric)
- **Technique / strategy**: 3-2-1-0 (slow down + own positions)
- **Standard** (default): 2-0-1-0

## PROGRESSION PROFILE RECOMMENDATION

Based on the goal and duration, recommend ONE progression profile:

1. **staircase_percent** — Keep reps stable, increase load % each week, then deload/reset. Best for strength/hypertrophy with predictable loading. Rules: 3-6 work weeks then 1 deload, +2.5-5% TM per step, deload at 30-50% volume drop.
2. **rep_staircase** — Hold load constant, stair-step reps up week to week, then reset reps and bump load. Best for hypertrophy with stable technique. Rules: hold load, climb reps (6→7→8→9), bump load +2.5-5lb upper / +5-10lb lower, reset to bottom rung.
3. **wave_by_month** — Each month is a wave (accumulation → intensification → realization/deload). Within the month, % varies in a planned pattern. Best for intermediates who respond to planned fatigue + recovery.
4. **double_progression** — Pick a rep range (e.g. 8-12), earn load increases by first earning reps. Best for hypertrophy and general strength — highly auto-regulatable.

## PERIODIZATION STYLE

Based on the goal and days_per_week, recommend a periodization style:

- **DUP** (Daily Undulating): Same lift 2-4x/week with different emphases per day. Best for 3+ days/week.
- **WUP** (Weekly Undulating): Each week has a distinct emphasis. Good for 1-2x/week per lift.
- **Linear**: Increase load or reps in a straight line. Best for novices or constrained lifts.
- **Block**: Focus on one adaptation per block (accumulation → intensification → realization). Best for advanced or peaking.
- **Concurrent**: Train multiple qualities same week with planned priority. Best for athletes.

## IMPLEMENTATION GUARDRAILS

- Only progress one knob at a time (load or reps or sets) unless user is clearly under-challenged.
- Cap hard sets per muscle/pattern: 8-20 hard sets/week depending on training age context ({difficulty}).
- Auto-deload triggers (any 2-3 of these): e1RM trending down 2+ weeks, RIR collapsing, soreness/pain flags rising, sleep/stress poor + performance drop.
- Exercise substitutions must preserve the pattern (same movement goal) and optionally preserve the slot role.

## DAY LAYOUT RULES

- Follow the user's weekly schedule EXACTLY — only assign workouts on days marked TRAINING
- Days marked REST must have is_rest_day=true and empty exercises
- Each training day: 5-8 exercise slots following the slot role hierarchy
- Compounds first, then accessories, then isolations
- Ensure pattern coverage across the week (don't leave gaps in horizontal pull, vertical push, etc.)

## NUTRITION RECOMMENDATIONS

Provide daily macro targets for training and rest days based on the goal:
- Build Muscle: caloric surplus (+300-500 cal), protein 1g/lb, high carbs
- Fat Loss: caloric deficit (-500-750 cal from TDEE), protein 1g/lb, moderate carbs
- Strength: slight surplus, high protein, pre/post workout carbs
- Endurance: moderate calories, high carb ratio, adequate protein
- Recomp: training day surplus, rest day deficit, high protein
- General Fitness: maintenance calories, balanced macros

## REQUIRED JSON OUTPUT

Return ONLY valid JSON matching this exact structure:

{{
  "name": "string — descriptive program name",
  "description": "string — 1-2 sentence description including the training philosophy",
  "week_template": {{
    "days": [
      {{
        "day": "Monday",
        "name": "string — session role label (e.g., 'Heavy Upper', 'Push', 'Lower Hypertrophy')",
        "is_rest_day": false,
        "session_role_labels": ["string — e.g., 'heavy upper', 'light lower', 'push hypertrophy'"],
        "exercises": [
          {{
            "exercise_id": 123,
            "exercise_name": "Barbell Bench Press",
            "muscle_group": "chest",
            "slot_role": "primary_compound",
            "sets": 4,
            "reps": "6-10",
            "rest_seconds": 120,
            "intensity_target_pct": 75,
            "set_structure": "straight_sets",
            "tempo": "2-0-1-0",
            "selection_reason": "string — brief reason for this exercise choice based on tags/pattern/slot role"
          }}
        ]
      }},
      {{
        "day": "Tuesday",
        "name": "Rest",
        "is_rest_day": true,
        "session_role_labels": [],
        "exercises": []
      }}
    ]
  }},
  "progression": {{
    "profile": "staircase_percent",
    "periodization_style": "linear",
    "reps_increase_per_week": 1,
    "sets_increase_interval_weeks": 3,
    "deload_every_n_weeks": 4,
    "deload_volume_modifier": 0.6,
    "deload_intensity_modifier": 0.6,
    "auto_progression_gates": {{
      "completion": "hit all prescribed reps/sets within technique rules",
      "effort": "average set RIR within ±1 of target (or RPE within ±1)",
      "symptom_flags": "pain > threshold, form breakdown, unusual stiffness → hold/regress"
    }},
    "notes": "string — brief progression strategy explanation"
  }},
  "nutrition_template": {{
    "training_day": {{
      "calories": 2800,
      "protein": 200,
      "carbs": 350,
      "fat": 80
    }},
    "rest_day": {{
      "calories": 2400,
      "protein": 200,
      "carbs": 250,
      "fat": 80
    }},
    "note": "string — brief nutrition guidance"
  }},
  "weekly_volume_summary": {{
    "total_hard_sets": 0,
    "sets_by_muscle_group": {{"chest": 0, "back": 0}},
    "pattern_coverage": ["horizontal_push", "horizontal_pull", "vertical_push", "vertical_pull", "knee_dominant", "hip_dominant"]
  }}
}}

## CRITICAL RULES

- You MUST include all 7 days (Monday through Sunday) in the days array
- Training days have exercises; rest days have is_rest_day=true and empty exercises array
- Use ONLY exercise IDs and names from the exercise bank above
- reps can be a number string ("12") or range string ("8-10")
- Every exercise MUST have a slot_role, set_structure, tempo, and selection_reason
- selection_reason must reference tags (pattern, muscle, stance, plane) — not subjective difficulty
- Return ONLY the JSON, no markdown fences, no commentary"""


def get_progression_suggestion_prompt(
    exercise_name: str,
    history: dict[str, Any],
) -> str:
    """
    Generate prompt for AI-powered progression suggestions.

    Args:
        exercise_name: Name of the exercise.
        history: Aggregated exercise history with sessions, trend, averages.

    Returns:
        Formatted prompt string for OpenAI.
    """
    sessions_text = ""
    for session in history.get("sessions", []):
        sessions_text += (
            f"  - {session.get('date')}: {session.get('max_weight')}lbs × "
            f"{session.get('avg_reps'):.0f} reps, {session.get('sets')} sets\n"
        )

    return f"""You are an expert strength coach analyzing training data for progressive overload.

Exercise: {exercise_name}
Current trend: {history.get('trend', 'unknown')}
Average weight: {history.get('avg_weight', 0)}lbs
Max weight: {history.get('max_weight', 0)}lbs
Average reps: {history.get('avg_reps', 0):.1f}
Total sessions analyzed: {len(history.get('sessions', []))}

Recent session history:
{sessions_text}

Based on this data, provide a progression recommendation in JSON:
{{
  "recommendation": "increase_weight" | "increase_reps" | "increase_sets" | "maintain" | "deload",
  "suggested_weight": <number>,
  "suggested_reps": <number>,
  "rationale": "<2-3 sentence explanation>",
  "confidence": <0.0-1.0>
}}

Rules:
- Only suggest weight increases of 5lbs (or 2.5kg) at a time.
- If reps are consistently above target range (10+), suggest weight increase.
- If weight/reps are declining, suggest maintaining or deloading.
- If plateau for 3+ sessions, suggest a small increase to break through.
- Be conservative — better to under-suggest than over-suggest.
"""


def get_exercise_auto_tag_prompt(
    exercise_name: str,
    description: str = '',
    category: str = '',
    muscle_group: str = '',
    existing_tags: dict[str, Any] | None = None,
) -> str:
    """
    Generate prompt for AI-powered exercise auto-tagging (v6.5 Step 13).

    Uses GPT-4o to generate structured v6.5 ExerciseCard tags with
    confidence scores and reasoning.
    """
    existing_info = ""
    if existing_tags:
        existing_info = f"""
Existing tags (may be incomplete or inaccurate — re-evaluate from scratch):
{_format_existing_tags(existing_tags)}
"""

    return f"""You are a certified strength & conditioning specialist (CSCS) and exercise science expert with 20+ years of experience. Your task is to classify an exercise with rich, precise tags used for program design, exercise swaps, and workload analytics.

## EXERCISE
- Name: {exercise_name}
- Description: {description or 'Not provided'}
- Category: {category or 'Not provided'}
- Legacy muscle group: {muscle_group or 'Not provided'}
{existing_info}

## TAG TAXONOMY

### pattern_tags (select ALL that apply, usually 1-3):
knee_dominant, hip_dominant, horizontal_push, horizontal_pull, vertical_push, vertical_pull, trunk_anti_extension, trunk_anti_flexion, trunk_anti_rotation, trunk_rotation, trunk_lateral_flexion, trunk_anti_lateral_flexion, pelvis_flexion_emphasis, pelvis_extension_emphasis, locomotion, carries

### primary_muscle_group (select exactly ONE):
quads, hamstrings, glutes, calves, hip_adductors, hip_abductors, hip_flexors, spinal_erectors, lats, mid_back, upper_traps, rear_delts, side_delts, front_delts, chest, triceps, biceps, forearms_and_grip, abs_rectus, obliques, deep_core

### secondary_muscle_groups (select 1-5):
Same options as primary_muscle_group. Must NOT include the primary.

### muscle_contribution_map (weights MUST sum to 1.0):
Map of muscle_group → contribution weight. Include primary + secondary muscles.
Example: {{"quads": 0.6, "glutes": 0.25, "hamstrings": 0.1, "deep_core": 0.05}}

### stance (select exactly ONE):
supine, prone, quadruped, tall_kneeling, half_kneeling, seated_supported, standing_supported, bilateral_standing, staggered, split_squat_lunge, single_leg, athletic_multidirectional, hang_support

### plane (select exactly ONE):
sagittal, frontal, transverse, mixed

### rom_bias (select exactly ONE):
lengthened, mid_range, shortened, mixed

### athletic_skill_tags (select 0-3, empty for non-athletic exercises):
jump_vertical, jump_horizontal, jump_lateral, hop_single_leg_vertical, hop_single_leg_horizontal, bound_alternating, landing_and_deceleration, sprint_acceleration, sprint_max_velocity, change_of_direction_cut, shuffle_and_lateral, throw_overhead, throw_rotational, throw_chest_pass, olympic_lift_derivative, upper_body_plyometric, medicine_ball_slam, medicine_ball_scoop_toss, reactive_agility_cue_based

### athletic_attribute_tags (select 0-3, empty for non-athletic exercises):
power, elasticity, rate_of_force_development, reactive_strength_index, speed_linear, agility_multi_directional, coordination, stiffness, deceleration_capacity, work_capacity

### equipment_required (list all REQUIRED equipment):
e.g., ["barbell", "squat_rack"] or ["cable_machine"] or [] for bodyweight

### equipment_optional (list optional enhancements):
e.g., ["belt", "wrist_wraps"] or []

## OUTPUT FORMAT

Return ONLY valid JSON:
{{
  "pattern_tags": ["tag1", "tag2"],
  "primary_muscle_group": "string",
  "secondary_muscle_groups": ["string1", "string2"],
  "muscle_contribution_map": {{"muscle": 0.5, "muscle2": 0.3, "muscle3": 0.2}},
  "stance": "string",
  "plane": "string",
  "rom_bias": "string",
  "athletic_skill_tags": [],
  "athletic_attribute_tags": [],
  "equipment_required": [],
  "equipment_optional": [],
  "confidence": {{
    "pattern_tags": 0.95,
    "primary_muscle_group": 0.9,
    "secondary_muscle_groups": 0.85,
    "muscle_contribution_map": 0.8,
    "stance": 0.9,
    "plane": 0.95,
    "rom_bias": 0.85,
    "athletic_skill_tags": 0.9,
    "athletic_attribute_tags": 0.9,
    "equipment_required": 0.95,
    "equipment_optional": 0.9
  }},
  "reasoning": {{
    "pattern_tags": "Brief explanation",
    "primary_muscle_group": "Brief explanation",
    "stance": "Brief explanation",
    "plane": "Brief explanation",
    "rom_bias": "Brief explanation"
  }}
}}

## RULES
- Be precise. Don't over-tag — only select what clearly applies.
- muscle_contribution_map weights MUST sum to exactly 1.0.
- Confidence values: 0.0 = no idea, 0.5 = educated guess, 0.8 = fairly sure, 0.95+ = very confident.
- Reasoning only for the 5 most important fields (pattern_tags, primary_muscle_group, stance, plane, rom_bias).
- Return ONLY the JSON. No markdown fences, no commentary."""


def get_program_modification_prompt(
    current_program: dict[str, Any],
    modification_request: str,
    exercise_bank: list[dict[str, Any]],
) -> str:
    """
    Generate prompt for modifying an existing program based on natural language.

    The trainer describes what they want changed (e.g., "focus week 1 more on squats",
    "add drop sets to isolation exercises", "reduce volume on back day") and the AI
    returns the modified program schedule.

    Args:
        current_program: The full current program data (name, description, schedule, etc.)
        modification_request: Natural language instruction from the trainer.
        exercise_bank: Available exercises with rich v6.5 tags.

    Returns:
        Formatted prompt string.
    """
    import json

    exercise_bank_text = _format_exercise_bank_with_tags(exercise_bank)

    # Compact the schedule for the prompt — only include week 1 template + metadata
    schedule = current_program.get('schedule', {})
    weeks = schedule.get('weeks', [])
    schedule_preview = json.dumps(weeks[:1], indent=2) if weeks else '[]'

    program_meta = json.dumps({
        'name': current_program.get('name', ''),
        'description': current_program.get('description', ''),
        'difficulty_level': current_program.get('difficulty_level', ''),
        'goal_type': current_program.get('goal_type', ''),
        'duration_weeks': current_program.get('duration_weeks', 0),
        'total_weeks': len(weeks),
    }, indent=2)

    return f"""You are a deterministic training plan engine following the v6.5 coaching operating system. A trainer has an existing generated program and wants to modify it using natural language.

## CURRENT PROGRAM METADATA
{program_meta}

## CURRENT WEEK 1 SCHEDULE
{schedule_preview}

## TRAINER'S MODIFICATION REQUEST
"{modification_request}"

## AVAILABLE EXERCISE BANK
{exercise_bank_text}

## RULES

1. Apply the trainer's modification request to the program.
2. Only change what the trainer asked for — preserve everything else.
3. If the trainer asks to change a specific week, only modify that week. If they say "all weeks" or don't specify, modify the week 1 template (which gets expanded to all weeks).
4. You MUST use exercises from the exercise bank above. Use exact exercise IDs and names.
5. Maintain the v6.5 slot role hierarchy: primary_compound → secondary_compound → accessory → isolation.
6. Every exercise must have: slot_role, set_structure, tempo, sets, reps, rest_seconds.
7. If the trainer asks to "focus more on X", add more exercises targeting X or replace less relevant exercises.
8. If the trainer asks to change set structures, apply the USE/AVOID rules from v6.5.

## REQUIRED JSON OUTPUT

Return ONLY valid JSON with the modified program. The structure must match EXACTLY:

{{
  "name": "string — updated program name if appropriate, or keep original",
  "description": "string — updated description reflecting the modification",
  "modification_summary": "string — 1-2 sentence summary of what was changed and why",
  "schedule": {{
    "weeks": [
      {{
        "week_number": 1,
        "is_deload": false,
        "intensity_modifier": 1.0,
        "volume_modifier": 1.0,
        "days": [
          {{
            "day": "Monday",
            "name": "Session Label",
            "is_rest_day": false,
            "session_role_labels": [],
            "exercises": [
              {{
                "exercise_id": 123,
                "exercise_name": "Exercise Name",
                "muscle_group": "chest",
                "slot_role": "primary_compound",
                "sets": 4,
                "reps": "6-10",
                "rest_seconds": 120,
                "intensity_target_pct": 75,
                "set_structure": "straight_sets",
                "tempo": "2-0-1-0",
                "selection_reason": "brief reason"
              }}
            ]
          }}
        ]
      }}
    ]
  }},
  "nutrition_template": {json.dumps(current_program.get('nutrition_template', {}), indent=2)}
}}

IMPORTANT:
- Return the FULL modified week(s), not just the changed exercises
- Include ALL 7 days (Mon-Sun) — rest days have is_rest_day=true and empty exercises
- Return ONLY the JSON, no markdown fences, no commentary"""


def _format_exercise_bank_with_tags(exercise_bank: list[dict[str, Any]]) -> str:
    """Format exercise bank with rich v6.5 tags for AI program generation prompt."""
    exercises_by_group: dict[str, list[str]] = {}
    for ex in exercise_bank:
        mg = ex.get('primary_muscle_group') or ex.get('muscle_group', 'other')
        parts = [f"[id={ex['id']}] {ex['name']}"]

        # Add rich tag info when available
        tag_parts: list[str] = []
        if ex.get('pattern_tags'):
            tag_parts.append(f"patterns: {', '.join(ex['pattern_tags'])}")
        if ex.get('stance'):
            tag_parts.append(f"stance: {ex['stance']}")
        if ex.get('plane'):
            tag_parts.append(f"plane: {ex['plane']}")
        if ex.get('rom_bias'):
            tag_parts.append(f"rom: {ex['rom_bias']}")
        if ex.get('equipment_required'):
            tag_parts.append(f"equip: {', '.join(ex['equipment_required'])}")
        if ex.get('category'):
            tag_parts.append(f"category: {ex['category']}")

        if tag_parts:
            parts.append(f"({'; '.join(tag_parts)})")
        elif ex.get('category'):
            parts.append(f"({ex['category']})")

        exercises_by_group.setdefault(mg, []).append(' '.join(parts))

    result = ""
    for mg, exercises in sorted(exercises_by_group.items()):
        result += f"\n### {mg.replace('_', ' ').title()}\n"
        result += "\n".join(f"  - {e}" for e in exercises)
        result += "\n"

    return result


def _format_existing_tags(tags: dict[str, Any]) -> str:
    """Format existing tags for prompt context."""
    parts: list[str] = []
    for key, value in tags.items():
        if value:
            parts.append(f"  - {key}: {value}")
    return "\n".join(parts) if parts else "  (none)"


def get_video_analysis_prompt() -> str:
    """
    Generate prompt for video-based exercise analysis (v6.5 Step 14).
    Used with GPT-4o Vision API — image is a video frame.
    """
    return """You are an expert strength & conditioning coach analyzing a frame from an exercise video. Your task is to identify the exercise, estimate rep count if visible, and evaluate form quality.

Analyze this image and return ONLY valid JSON:
{
  "exercise_detected": "string (exercise name, e.g., 'Barbell Bench Press', 'Dumbbell Curl')",
  "rep_count": number or null (if you can estimate reps from the motion/position),
  "form_score": number 0-10 or null (10 = perfect form, 0 = dangerous form),
  "observations": [
    "string (form observation 1, e.g., 'Good depth on the squat')",
    "string (form observation 2, e.g., 'Slight forward lean')"
  ],
  "confidence": number 0-1 (how confident you are in the analysis)
}

## RULES
- If you cannot identify the exercise, set exercise_detected to "" and confidence to 0.
- If you can see the exercise but not count reps, set rep_count to null.
- If form is not evaluable from a single frame, set form_score to null.
- Observations should be specific and actionable (e.g., "knees caving inward" not "bad form").
- Be honest about confidence — single frames provide limited information.
- Return ONLY the JSON. No markdown fences, no commentary."""


def get_exercise_thumbnail_prompt(
    exercise_name: str,
    muscle_group: str,
    equipment: list[str] | None = None,
) -> str:
    """
    Generate a DALL-E prompt for creating a professional exercise thumbnail image.

    Args:
        exercise_name: Name of the exercise (e.g., "Barbell Bench Press").
        muscle_group: Primary muscle group targeted.
        equipment: Optional list of equipment used.

    Returns:
        Formatted prompt string for DALL-E 3.
    """
    equipment_str = ""
    if equipment:
        equipment_str = f" using {', '.join(equipment)}"

    return (
        f"A clean, professional fitness photograph of an athletic person "
        f"performing {exercise_name}{equipment_str}. "
        f"The image shows proper form for this {muscle_group} exercise, "
        f"shot from a 3/4 angle in a well-lit modern gym. "
        f"Photorealistic style, shallow depth of field, "
        f"neutral color palette, no text, no watermarks, no logos. "
        f"The subject is mid-rep demonstrating correct technique."
    )


# ---------------------------------------------------------------------------
# Builder Decision Tree Prompts (UI/UX Master Packet §12)
#
# Each tree provides structured reasoning the AI must follow when making
# decisions at each builder step. The AI should output its reasoning
# along each branch, not skip to a conclusion.
# ---------------------------------------------------------------------------

def get_photo_food_recognition_prompt() -> str:
    """
    Prompt for AI food recognition from a meal photo (Nutrition Spec §12).

    The AI should identify foods, estimate portions, and provide macro estimates.
    Results must be editable by the user before saving.
    """
    return """You are a nutrition AI analyzing a photo of a meal.

Identify every visible food item in the image. For each item:
1. Name the food (be specific — "grilled chicken breast" not just "chicken")
2. Estimate the portion size in grams (use visual cues like plate size, utensils)
3. Estimate macros per the estimated portion: protein_g, carbs_g, fat_g, calories

Return a JSON array:
{
  "foods": [
    {
      "name": "Grilled Chicken Breast",
      "quantity_g": 150,
      "confidence": 0.85,
      "protein_g": 46,
      "carbs_g": 0,
      "fat_g": 5,
      "calories": 231
    },
    ...
  ],
  "meal_total": {
    "protein_g": ...,
    "carbs_g": ...,
    "fat_g": ...,
    "calories": ...
  },
  "notes": "Any relevant observations about the meal"
}

Rules:
- Be specific about food names (include cooking method if visible)
- Use standard portion estimation (a fist ≈ 1 cup, palm ≈ 3-4 oz protein)
- Include sauces, dressings, oils if visible
- Confidence should be 0.0-1.0 (lower if item is partially hidden or ambiguous)
- Round macros to whole numbers
- If you cannot identify a food, include it with name="Unknown item" and low confidence
"""


_DECISION_TREES: dict[str, str] = {
    'choose_split': """
You are choosing a training split. Follow this decision tree exactly:

1. FILTER by days per week. Remove splits that don't work at this frequency.
   - 2 days: full body, upper/lower
   - 3 days: full body, PPL, push/pull, full body alternating
   - 4 days: upper/lower, PPL+1, anterior/posterior, conjugate
   - 5 days: body-part, PPL+upper/lower, specialization
   - 6 days: PPL×2, body-part+1, concurrent
2. FILTER by main goal. Bodybuilding → body-part, PPL, specialization. Athletic → movement-pattern, concurrent, event-based. Rehab → full body, movement-pattern.
3. FILTER by recovery. Fragile recovery → simpler splits with more spacing. Strong recovery → complex/specialized splits.
4. CHECK equipment. Limited equipment → drop specialty-dependent splits.
5. CHECK emphasis needs. More upper/lower frequency → upper/lower or PPL. More body-part → body-part or specialization. More athletic → concurrent.
6. RANK the remaining 2-3 options and pick the best fit. Save reasons so the app can explain the choice.

Output: chosen split name, runner-up alternatives (max 3), and a 1-sentence "why" for each.
""",

    'choose_day_role': """
You are assigning a day role to a session within the chosen split. Follow this tree:

1. START with the split. The split determines the broad job of each day.
2. ASK what quality is primary: strength, hypertrophy, power, conditioning, technique, or rehab tolerance.
3. ASK what neural stress level: high neural (max effort, sprints, jumps), medium mixed, low neural (bodybuilding, machine, aerobic), or restore.
4. CHECK the day before and after. Hard lower + high-neural days should not stack consecutively.
5. ASSIGN the day label in plain language so the user immediately understands the session's job (e.g., "Heavy Lower Strength", "Upper Hypertrophy", "Athletic Power Day").

Output: day_role label, session_family, day_stress level, and estimated duration in minutes.
""",

    'choose_slot_roles': """
You are assigning slot roles inside a session. Follow this tree:

1. START with the session family. Strength, hypertrophy, power, conditioning, and rehab sessions each need different slot mixes.
2. PROTECT the first high-priority slot. If the session has power or technique work, that comes first to avoid fatigue contamination.
3. ADD secondary slots only until the session time cap and weekly volume coverage are met.
4. ADD support slots only if they fill a real need: trunk, carry, unilateral support, calves, neck, or rehab exposure.
5. MARK low-priority finishers as optional so they are the first to be cut when time or readiness falls apart.

Slot roles to choose from: prep, warm-up, main strength, secondary strength, hypertrophy compound, hypertrophy isolation, technique, power, sprint, jump, throw, unilateral support, trunk, carry, conditioning aerobic, conditioning high, rehab tolerance, cooldown.

Output: ordered list of slots with role, pattern target, and whether optional.
""",

    'choose_set_structure': """
You are choosing a set structure for a slot. Follow this tree:

1. START with the slot role. Main strength and hypertrophy isolation do NOT use the same structures well.
2. ASK how much quality control the slot needs. More technical or high-output → cleaner structures (straight sets, wave sets, cluster). More pump-focused → denser structures (drop sets, myo-reps, supersets).
3. CHECK time pressure. If the session is tight, denser structures may rise. But if the slot is high-skill, density should not win at the cost of quality.
4. CHECK safety and symptom risk. Aggressive fatigue methods should fall in rank when pain risk or technical risk is high.
5. CHOOSE the simplest structure that gets the job done and still leaves the session coherent.

Structure families:
- Strength/quality: straight sets, ramping sets, back-off sets, wave sets, cluster sets, paused reps, dead-stop reps
- Hypertrophy/density: rest-pause, myo-reps, drop sets, mechanical drop sets, tempo reps, 1.5 reps, iso-hold + reps, lengthened partials, burnout sets, widowmaker sets
- Pacing: EMOM, E2MOM, AMRAP, AMQR, ladder sets, ascending/descending ladders, timed sets

Output: structure name, sets, rep range, and USE/AVOID reason.
""",

    'choose_pairing': """
You are deciding how exercises within a session should be grouped. Follow this tree:

1. FIRST ask if the slot should stand alone. Main lifts, max effort work, sprints, jumps, and high-skill work often deserve straight sequencing.
2. IF the slot can be paired, ask whether the best pairing is non-competing, antagonist, agonist, same-muscle, corrective, or contrast-based.
3. CHECK interference risk, setup friction, and transition time. Does pairing wreck quality or add chaos?
4. IF pairing improves efficiency without wrecking the slot, use it. If it turns the session into chaos, do not use it just because it looks efficient on paper.

Pairing options: straight sequencing, alternating sets, supersets (antagonist, non-competing, agonist, compound), tri-sets, giant sets, contrast pairs, complex pairs, potentiation pairs, corrective + main, strength + mobility, strength + sprint, carry + trunk.

Output: pairing method for each slot group with rationale.
""",

    'choose_exercise': """
You are selecting an exercise for a slot. Follow this tree:

1. START with the slot role and the movement/tissue target.
2. PICK the right exercise class: barbell main lift, barbell secondary, dumbbell/kettlebell compound, machine compound, isolation, bodyweight strength, plyometric, sprint, COD/agility, carry, trunk, or aerobic modality.
3. CHOOSE the symmetry/stance bias: bilateral symmetrical, asymmetrical front/back, asymmetrical lateral, unilateral, supported unilateral, offset bilateral.
4. CHOOSE the plane bias: sagittal, frontal, transverse, multi-planar, or blended.
5. CHOOSE the ROM bias: full ROM, lengthened, mid-range, shortened, partial overload, constrained, or progressive expansion.
6. CHECK equipment availability, pain history, exercise familiarity, weekly coverage, fatigue stacking, and swap readiness.
7. PICK the exercise that best satisfies the slot while remaining easy enough to coach and easy enough to swap when life happens.

Output: exercise name, exercise class, key tags (stance, plane, ROM, velocity, load_source), and why this exercise fits.
""",

    'build_swaps': """
You are building swap alternatives for a selected exercise. Follow this tree:

1. START with the selected exercise and note which qualities must stay the same: slot role, movement pattern, muscle emphasis, set structure compatibility, intensity style, tempo, rest, and progression continuity.
2. BUILD Same Muscle options for users who need the same tissue emphasis.
3. BUILD Same Pattern options for users who need the same movement job.
4. BUILD Explore All options for users who simply need anything compatible.
5. PRE-BUILD pain-safe regressions for users who need the same slot to survive a flare-up.
6. PRE-BUILD equipment-limited fallbacks for users whose training environment is inconsistent.
7. If coach has locked alternatives, include Coach-Locked tab.

For each alternative, preserve the slot's sets, reps, intensity target, tempo, and set structure by default unless the user explicitly changes them.

Output: 3-5 alternatives per tab with similarity score and swap reason.
""",

    'choose_progression': """
You are choosing a progression model for a slot. Follow this tree:

1. START with the real goal. Strength, hypertrophy, athletic performance, conditioning, technique, and rehab do not use the same progression logic.
2. ASK what is stable enough to progress: load, reps, sets, density, tempo, ROM, frequency, or performance output.
3. ASK how much autoregulation the user actually needs and can handle.
   - RPE/RIR for self-aware lifters
   - Fixed percentages for lifters who prefer predictability
   - Pain cap or quality cap for symptomatic trainees
4. CHECK fatigue tolerance, deload needs, equipment consistency, and whether load prescription can be trusted.
5. CHOOSE the simplest progression model that creates clear forward motion without pretending the user is a robot.

Progression families: linear, step loading, double/triple progression, top set + back-off, wave/staircase, volume progression, density progression, tempo progression, ROM progression, frequency progression, rest reduction.

Autoregulation: RPE, RIR, APRE, DAPRE, daily max, readiness-based, performance drop-off, fatigue cap, pain response, bar speed cutoff, session-rating adjustment.

Output: progression type, autoregulation method (if any), deload trigger, and why.
""",

    'timing_check': """
You are reviewing session timing to ensure the workout fits within the user's time budget. Follow this tree:

1. START with the session time cap (e.g., 60 minutes). The session is NOT allowed to become imaginary.
2. ADD warm-up time, setup time, transition time between exercises, work time per set, rest time per set, and logging time per slot.
   - Warm-up/activation: 5-10 min
   - Per slot: (sets × (work_seconds + rest_seconds)) + transition (1-2 min)
3. SUM all slot times.
4. IF the session runs over:
   a. FIRST cut optional finishers
   b. THEN cut low-priority support volume
   c. THEN reduce density layers on remaining slots
   d. NEVER cut the core objective slots that define the day
5. PROTECT the slots that define the day. A 60-minute session should still feel like the day it was supposed to be, not a random pile of leftovers.

Output: total estimated duration, any slots trimmed, and final slot list with times.
""",
}


def get_builder_decision_tree_prompt(
    step_name: str,
    context: dict[str, object],
) -> str:
    """
    Return the decision tree prompt for a specific builder step.

    The AI should follow this tree when making recommendations, outputting
    its reasoning at each branch point.

    Args:
        step_name: One of: choose_split, choose_day_role, choose_slot_roles,
                   choose_set_structure, choose_pairing, choose_exercise,
                   build_swaps, choose_progression, timing_check
        context: Step-specific context (brief, current plan state, etc.)

    Returns:
        Formatted prompt string, or empty string if step_name not found.
    """
    tree = _DECISION_TREES.get(step_name, '')
    if not tree:
        return ''

    # Format context into the prompt
    context_lines: list[str] = []
    for key, value in context.items():
        context_lines.append(f"- {key}: {value}")

    context_block = '\n'.join(context_lines) if context_lines else 'No additional context.'

    return (
        f"## Decision Tree: {step_name.replace('_', ' ').title()}\n\n"
        f"### Context\n{context_block}\n\n"
        f"### Decision Process\n{tree}\n"
        f"Follow each step in order. Show your reasoning at each branch. "
        f"Do not skip to a conclusion.\n"
    )
