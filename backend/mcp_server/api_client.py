"""
API Client for communicating with Django backend.
All requests are authenticated with the trainer's JWT token.
"""
from __future__ import annotations

import httpx
from typing import Any, Optional, cast
from mcp_config import DJANGO_API_BASE_URL


class DjangoAPIClient:
    """Client for Django REST API with trainer authentication."""

    def __init__(self, jwt_token: str):
        self.base_url = DJANGO_API_BASE_URL
        self.jwt_token = jwt_token
        self._client: Optional[httpx.AsyncClient] = None

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.jwt_token}",
            "Content-Type": "application/json",
        }

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                headers=self.headers,
                timeout=30.0,
            )
        return self._client

    async def close(self) -> None:
        if self._client:
            await self._client.aclose()
            self._client = None

    async def get(self, endpoint: str, params: Optional[dict[str, Any]] = None) -> Any:
        """Make GET request to Django API."""
        client = await self._get_client()
        response = await client.get(endpoint, params=params)
        response.raise_for_status()
        return response.json()

    async def post(self, endpoint: str, data: Optional[dict[str, Any]] = None) -> Any:
        """Make POST request to Django API."""
        client = await self._get_client()
        response = await client.post(endpoint, json=data)
        response.raise_for_status()
        return response.json()

    async def put(self, endpoint: str, data: Optional[dict[str, Any]] = None) -> Any:
        """Make PUT request to Django API."""
        client = await self._get_client()
        response = await client.put(endpoint, json=data)
        response.raise_for_status()
        return response.json()

    async def patch(self, endpoint: str, data: Optional[dict[str, Any]] = None) -> Any:
        """Make PATCH request to Django API."""
        client = await self._get_client()
        response = await client.patch(endpoint, json=data)
        response.raise_for_status()
        return response.json()

    # ==================== Trainer Endpoints ====================

    async def get_current_user(self) -> dict[str, Any]:
        """Get the authenticated trainer's info."""
        result = await self.get("/auth/users/me/")
        return cast(dict[str, Any], result)

    async def get_trainer_dashboard(self) -> dict[str, Any]:
        """Get trainer dashboard stats."""
        result = await self.get("/trainer/dashboard/")
        return cast(dict[str, Any], result)

    async def get_trainer_stats(self) -> dict[str, Any]:
        """Get detailed trainer statistics."""
        result = await self.get("/trainer/dashboard/stats/")
        return cast(dict[str, Any], result)

    # ==================== Trainee Endpoints ====================

    async def get_trainees(self, search: Optional[str] = None) -> list[dict[str, Any]]:
        """Get list of trainer's trainees."""
        params: Optional[dict[str, Any]] = {"search": search} if search else None
        result = await self.get("/trainer/trainees/", params=params)
        return cast(list[dict[str, Any]], result)

    async def get_trainee(self, trainee_id: int) -> dict[str, Any]:
        """Get specific trainee details."""
        result = await self.get(f"/trainer/trainees/{trainee_id}/")
        return cast(dict[str, Any], result)

    async def get_trainee_profile(self, trainee_id: int) -> dict[str, Any]:
        """Get trainee's profile with goals and preferences."""
        trainee = await self.get_trainee(trainee_id)
        # Profile is usually nested in the trainee response
        profile = trainee.get("profile", {})
        return cast(dict[str, Any], profile)

    # ==================== Daily Logs Endpoints ====================

    async def get_trainee_daily_logs(
        self,
        trainee_id: int,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        limit: int = 30
    ) -> list[dict[str, Any]]:
        """Get trainee's daily logs (workout + nutrition)."""
        params: dict[str, Any] = {"trainee": trainee_id, "limit": limit}
        if start_date:
            params["start_date"] = start_date
        if end_date:
            params["end_date"] = end_date
        result = await self.get("/workouts/daily-logs/", params=params)
        return cast(list[dict[str, Any]], result)

    async def get_trainee_nutrition_summary(
        self,
        trainee_id: int,
        days: int = 7
    ) -> dict[str, Any]:
        """Get trainee's nutrition summary."""
        result = await self.get(
            "/workouts/daily-logs/nutrition-summary/",
            params={"trainee": trainee_id, "days": days}
        )
        return cast(dict[str, Any], result)

    async def get_trainee_workout_summary(
        self,
        trainee_id: int,
        days: int = 7
    ) -> dict[str, Any]:
        """Get trainee's workout summary."""
        result = await self.get(
            "/workouts/daily-logs/workout-summary/",
            params={"trainee": trainee_id, "days": days}
        )
        return cast(dict[str, Any], result)

    # ==================== Nutrition Goals Endpoints ====================

    async def get_trainee_nutrition_goals(self, trainee_id: int) -> dict[str, Any]:
        """Get trainee's nutrition goals."""
        result = await self.get(f"/workouts/nutrition-goals/?trainee={trainee_id}")
        return cast(dict[str, Any], result)

    # ==================== Weight Check-ins Endpoints ====================

    async def get_trainee_weight_checkins(
        self,
        trainee_id: int,
        limit: int = 30
    ) -> list[dict[str, Any]]:
        """Get trainee's weight check-in history."""
        result = await self.get(
            "/workouts/weight-checkins/",
            params={"trainee": trainee_id, "limit": limit}
        )
        return cast(list[dict[str, Any]], result)

    async def get_trainee_latest_weight(self, trainee_id: int) -> dict[str, Any]:
        """Get trainee's latest weight check-in."""
        result = await self.get(
            "/workouts/weight-checkins/latest/",
            params={"trainee": trainee_id}
        )
        return cast(dict[str, Any], result)

    # ==================== Program Endpoints ====================

    async def get_trainee_programs(self, trainee_id: int) -> list[dict[str, Any]]:
        """Get programs assigned to a trainee."""
        result = await self.get(f"/workouts/programs/?trainee={trainee_id}")
        return cast(list[dict[str, Any]], result)

    async def get_trainee_active_program(self, trainee_id: int) -> Optional[dict[str, Any]]:
        """Get trainee's active program."""
        programs = await self.get_trainee_programs(trainee_id)
        for program in programs:
            if program.get("is_active"):
                return program
        return None

    async def get_program(self, program_id: int) -> dict[str, Any]:
        """Get specific program details."""
        result = await self.get(f"/workouts/programs/{program_id}/")
        return cast(dict[str, Any], result)

    # ==================== Exercise Endpoints ====================

    async def get_exercises(self, search: Optional[str] = None) -> list[dict[str, Any]]:
        """Get trainer's exercise library."""
        params: Optional[dict[str, Any]] = {"search": search} if search else None
        result = await self.get("/workouts/exercises/", params=params)
        return cast(list[dict[str, Any]], result)

    async def get_exercise(self, exercise_id: int) -> dict[str, Any]:
        """Get specific exercise details."""
        result = await self.get(f"/workouts/exercises/{exercise_id}/")
        return cast(dict[str, Any], result)

    # ==================== Program Template Endpoints ====================

    async def get_program_templates(self) -> list[dict[str, Any]]:
        """Get trainer's program templates."""
        result = await self.get("/trainer/program-templates/")
        return cast(list[dict[str, Any]], result)

    async def get_program_template(self, template_id: int) -> dict[str, Any]:
        """Get specific program template."""
        result = await self.get(f"/trainer/program-templates/{template_id}/")
        return cast(dict[str, Any], result)

    # ==================== Analytics Endpoints ====================

    async def get_adherence_analytics(
        self,
        trainee_id: Optional[int] = None,
        days: int = 30
    ) -> dict[str, Any]:
        """Get adherence analytics."""
        params: dict[str, Any] = {"days": days}
        if trainee_id:
            params["trainee"] = trainee_id
        result = await self.get("/trainer/analytics/adherence/", params=params)
        return cast(dict[str, Any], result)

    async def get_progress_analytics(
        self,
        trainee_id: int,
        days: int = 30
    ) -> dict[str, Any]:
        """Get progress analytics for a trainee."""
        result = await self.get(
            "/trainer/analytics/progress/",
            params={"trainee": trainee_id, "days": days}
        )
        return cast(dict[str, Any], result)
