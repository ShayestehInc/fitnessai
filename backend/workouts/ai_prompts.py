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
    Generate prompt for AI program generation from structured parameters.

    The AI generates a Week 1 template with intelligent exercise selection,
    set/rep schemes, and progression guidelines. The caller then programmatically
    expands the template across all weeks with progressive overload.

    Args:
        split_type: One of ppl, upper_lower, full_body, bro_split, custom.
        difficulty: One of beginner, intermediate, advanced.
        goal: One of build_muscle, fat_loss, strength, endurance, recomp, general_fitness.
        duration_weeks: Program duration (1-52).
        training_days_per_week: Training days per week (2-7).
        exercise_bank: Available exercises with id, name, muscle_group, category.
        custom_day_config: For custom splits — list of dicts with label and muscle_groups.
        training_days: Explicit list of day names to train (e.g. ["Monday", "Wednesday", "Friday"]).

    Returns:
        Formatted system+user prompt pair as a single string.
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

    # Format exercise bank — group by muscle group for readability
    exercises_by_group: dict[str, list[str]] = {}
    for ex in exercise_bank:
        mg = ex.get('muscle_group', 'other')
        entry = f"[id={ex['id']}] {ex['name']}"
        if ex.get('category'):
            entry += f" ({ex['category']})"
        exercises_by_group.setdefault(mg, []).append(entry)

    exercise_bank_text = ""
    for mg, exercises in sorted(exercises_by_group.items()):
        exercise_bank_text += f"\n### {mg.title()}\n"
        exercise_bank_text += "\n".join(f"  - {e}" for e in exercises)
        exercise_bank_text += "\n"

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

    return f"""You are an elite strength & conditioning coach and certified personal trainer with 20+ years of experience designing programs for clients at every level. You design programs that are evidence-based, progressive, and practical.

## YOUR TASK

Design Week 1 of a training program with the following parameters:

- **Split:** {split_labels.get(split_type, split_type)}
- **Difficulty:** {difficulty.title()}
- **Goal:** {goal_labels.get(goal, goal)}
- **Duration:** {duration_weeks} weeks
- **Training days/week:** {training_days_per_week}
- **{day_structure}**
- **{day_schedule}**

## EXERCISE BANK

You MUST select exercises ONLY from this bank. Use the exact exercise name and ID.
{exercise_bank_text}

## PROGRAM DESIGN GUIDELINES

1. **Exercise Selection:**
   - Pick 4-6 exercises per training day (fewer for beginners, more for advanced)
   - Start each day with compound movements, then isolation
   - Match exercises to the muscle groups for that day
   - Choose exercises appropriate for the difficulty level:
     - Beginner: machines, cables, guided movements
     - Intermediate: free weight compounds, dumbbells
     - Advanced: barbell compounds, Olympic lifts, advanced variations
   - Ensure exercise variety — avoid picking the same exercise for multiple days

2. **Sets & Reps by Goal:**
   - Build Muscle: 3-4 sets, 8-12 reps, 60-90s rest
   - Fat Loss: 3 sets, 12-15 reps, 30-45s rest (circuit-style)
   - Strength: 4-5 sets, 3-6 reps, 2-3min rest
   - Endurance: 2-3 sets, 15-20 reps, 30s rest
   - Recomp: 3-4 sets, 8-12 reps, 60-90s rest
   - General Fitness: 3 sets, 10-12 reps, 60s rest

3. **Day Layout:**
   - Follow the user's weekly schedule EXACTLY — only assign workouts on days marked TRAINING
   - Days marked REST must have is_rest_day=true and empty exercises
   - Label rest days clearly

4. **Nutrition Recommendations:**
   - Provide daily macro targets for training days and rest days
   - Base recommendations on the goal:
     - Build Muscle: caloric surplus, high protein (1g/lb)
     - Fat Loss: caloric deficit (500-750 cal below TDEE), high protein
     - Strength: slight surplus, high protein
     - Endurance: moderate calories, high carbs
     - Recomp: training day surplus, rest day deficit
     - General Fitness: maintenance calories, balanced macros

## REQUIRED JSON OUTPUT

Return ONLY valid JSON matching this exact structure:

{{
  "name": "string — creative, descriptive program name",
  "description": "string — 1-2 sentence description of the program",
  "week_template": {{
    "days": [
      {{
        "day": "Monday",
        "name": "string — day label (e.g., 'Push', 'Upper Body', 'Rest')",
        "is_rest_day": false,
        "exercises": [
          {{
            "exercise_id": 123,
            "exercise_name": "Bench Press",
            "muscle_group": "chest",
            "sets": 4,
            "reps": "8-10",
            "rest_seconds": 90
          }}
        ]
      }},
      {{
        "day": "Tuesday",
        "name": "Rest",
        "is_rest_day": true,
        "exercises": []
      }}
    ]
  }},
  "progression": {{
    "reps_increase_per_week": 1,
    "sets_increase_interval_weeks": 3,
    "deload_every_n_weeks": 4,
    "deload_volume_modifier": 0.6,
    "deload_intensity_modifier": 0.6,
    "notes": "string — brief progression strategy"
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
  }}
}}

IMPORTANT:
- You MUST include all 7 days (Monday through Sunday) in the days array
- Training days have exercises; rest days have is_rest_day=true and empty exercises array
- Use ONLY exercise IDs and names from the exercise bank above
- reps can be a number string ("12") or range string ("8-10")
- Return ONLY the JSON, no markdown fences, no commentary"""
