"""
Natural Language Parser Service for workout and nutrition logging.
Uses OpenAI API to parse user input into structured data.
"""
import json
import logging
from typing import Dict, Any, Optional, Tuple
from django.conf import settings
from openai import OpenAI
from pydantic import BaseModel, ValidationError

logger = logging.getLogger(__name__)

# OpenAI client - initialized lazily to avoid import-time errors
_client_instance = None

def get_openai_client():
    """Get or create OpenAI client instance (lazy initialization)."""
    global _client_instance
    
    if _client_instance is not None:
        return _client_instance
    
    if not settings.OPENAI_API_KEY:
        logger.warning("OpenAI API key not configured")
        return None
    
    try:
        # Initialize client with just the API key (no proxies or other args)
        _client_instance = OpenAI(api_key=settings.OPENAI_API_KEY)
        return _client_instance
    except Exception as e:
        logger.error(f"Failed to initialize OpenAI client: {e}", exc_info=True)
        return None


class ParsedNutritionMeal(BaseModel):
    """Pydantic model for parsed nutrition meal."""
    name: str
    protein: float = 0.0
    carbs: float = 0.0
    fat: float = 0.0
    calories: float = 0.0
    timestamp: Optional[str] = None


class ParsedWorkoutExercise(BaseModel):
    """Pydantic model for parsed workout exercise."""
    exercise_name: str
    sets: int
    reps: int | str  # Can be "8-10" or just 8
    weight: float
    unit: str = "lbs"  # "lbs" or "kg"
    timestamp: Optional[str] = None


class ParsedLogResponse(BaseModel):
    """Pydantic model for the complete parsed response."""
    nutrition: Dict[str, Any] = {"meals": []}
    workout: Dict[str, Any] = {"exercises": []}
    confidence: float = 0.0
    needs_clarification: bool = False
    clarification_question: Optional[str] = None


class NaturalLanguageParserService:
    """
    Service for parsing natural language input into structured workout/nutrition logs.
    
    This service:
    1. Takes raw user input (text or speech transcript)
    2. Calls OpenAI API with structured prompt
    3. Validates response using Pydantic
    4. Returns structured data ready for database insertion
    """
    
    @staticmethod
    def parse_user_input(
        user_input: str,
        context: Optional[Dict[str, Any]] = None
    ) -> Tuple[Dict[str, Any], Optional[str]]:
        """
        Parse natural language input into structured log data.
        
        Args:
            user_input: Raw user input string
            context: Optional context (user's program, recent exercises, etc.)
        
        Returns:
            Tuple of (parsed_data, error_message)
            - parsed_data: Dict with 'nutrition' and 'workout' keys
            - error_message: None if successful, error string if failed
        
        Example:
            input: "I ate a chicken bowl with extra rice and did 3 sets of bench press at 225 for 8 reps"
            output: ({
                'nutrition': {'meals': [{'name': 'Chicken Bowl', 'protein': 45, ...}]},
                'workout': {'exercises': [{'exercise_name': 'Bench Press', 'sets': 3, ...}]}
            }, None)
        """
        if not user_input or not user_input.strip():
            return {}, "User input is empty"
        
        # Get OpenAI client (lazy initialization)
        client = get_openai_client()
        if not client:
            return {}, "OpenAI API key not configured"
        
        try:
            # Import prompt function
            from workouts.ai_prompts import get_natural_language_log_parsing_prompt
            
            # Build prompt
            prompt = get_natural_language_log_parsing_prompt(user_input, context or {})
            
            # Call OpenAI API
            response = client.chat.completions.create(
                model="gpt-4o",  # Using GPT-4o as specified
                messages=[
                    {
                        "role": "system",
                        "content": "You are a fitness AI assistant that parses natural language into structured JSON. Always return valid JSON only, no additional text."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.1,  # Low temperature for consistent parsing
                response_format={"type": "json_object"}  # Force JSON response
            )
            
            # Extract JSON from response
            response_text = response.choices[0].message.content
            parsed_json = json.loads(response_text)
            
            # Validate with Pydantic
            try:
                validated_response = ParsedLogResponse(**parsed_json)
                
                # Convert to dict for return
                result = {
                    "nutrition": validated_response.nutrition,
                    "workout": validated_response.workout,
                    "confidence": validated_response.confidence,
                    "needs_clarification": validated_response.needs_clarification,
                    "clarification_question": validated_response.clarification_question
                }
                
                # If clarification is needed, return early
                if validated_response.needs_clarification:
                    return result, validated_response.clarification_question
                
                return result, None
                
            except ValidationError as e:
                logger.error(f"Pydantic validation error: {e}")
                return {}, f"AI response validation failed: {str(e)}"
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            return {}, f"Failed to parse AI response as JSON: {str(e)}"
        
        except Exception as e:
            logger.error(f"Error parsing user input: {e}", exc_info=True)
            return {}, f"Failed to parse input: {str(e)}"
    
    @staticmethod
    def format_for_daily_log(
        parsed_data: Dict[str, Any],
        trainee_id: int
    ) -> Dict[str, Any]:
        """
        Format parsed data into DailyLog-compatible structure.
        
        Args:
            parsed_data: Output from parse_user_input
            trainee_id: ID of the trainee
        
        Returns:
            Dict with 'nutrition_data' and 'workout_data' keys ready for DailyLog
        """
        nutrition_data = {
            "meals": parsed_data.get("nutrition", {}).get("meals", []),
            "totals": {
                "protein": sum(meal.get("protein", 0) for meal in parsed_data.get("nutrition", {}).get("meals", [])),
                "carbs": sum(meal.get("carbs", 0) for meal in parsed_data.get("nutrition", {}).get("meals", [])),
                "fat": sum(meal.get("fat", 0) for meal in parsed_data.get("nutrition", {}).get("meals", [])),
                "calories": sum(meal.get("calories", 0) for meal in parsed_data.get("nutrition", {}).get("meals", []))
            }
        }
        
        workout_data = {
            "exercises": []
        }
        
        # Format workout exercises
        for exercise in parsed_data.get("workout", {}).get("exercises", []):
            formatted_exercise = {
                "exercise_name": exercise.get("exercise_name"),
                "sets": [],
                "timestamp": exercise.get("timestamp")
            }
            
            # Convert sets/reps/weight into set-by-set format
            sets_count = exercise.get("sets", 1)
            reps = exercise.get("reps", 0)
            weight = exercise.get("weight", 0)
            unit = exercise.get("unit", "lbs")
            
            for set_num in range(1, sets_count + 1):
                formatted_exercise["sets"].append({
                    "set_number": set_num,
                    "reps": reps if isinstance(reps, int) else int(str(reps).split("-")[0]),
                    "weight": weight,
                    "unit": unit,
                    "completed": True
                })
            
            workout_data["exercises"].append(formatted_exercise)
        
        return {
            "nutrition_data": nutrition_data,
            "workout_data": workout_data
        }
