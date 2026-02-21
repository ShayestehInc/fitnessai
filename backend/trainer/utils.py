"""Shared utility functions for the trainer app."""
from __future__ import annotations

from rest_framework.request import Request


def parse_days_param(request: Request, default: int = 30) -> int:
    """Parse and clamp the `days` query parameter (1-365)."""
    try:
        return min(max(int(request.query_params.get("days", default)), 1), 365)
    except (ValueError, TypeError):
        return default
