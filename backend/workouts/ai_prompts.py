"""
AI Prompts for Natural Language Logging and Program Generation.
All prompts are stored here as per project standards.
"""
from typing import Dict, Any


def get_natural_language_log_parsing_prompt(user_input: str, context: Dict[str, Any] = None) -> str:
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


def get_program_generation_prompt(
    trainer_request: str,
    trainee_context: Dict[str, Any],
    exercise_bank: list
) -> str:
    """
    Generate prompt for AI program generation.
    
    Args:
        trainer_request: Natural language request (e.g., "Create a 4-week hypertrophy block for a client with knee pain")
        trainee_context: Information about the trainee (goals, limitations, etc.)
        exercise_bank: List of available exercises from trainer's workout bank
    
    Returns:
        Formatted prompt string for OpenAI
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
