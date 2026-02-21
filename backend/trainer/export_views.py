"""
Views for CSV data exports from the trainer dashboard.
Separated from views.py to keep file sizes manageable.
"""
from __future__ import annotations

from typing import cast

from django.http import HttpResponse
from rest_framework import views
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request

from core.permissions import IsTrainer
from users.models import User

from .services.export_service import (
    export_payments_csv,
    export_subscribers_csv,
    export_trainees_csv,
)
from .utils import parse_days_param


def _csv_response(content: str, filename: str) -> HttpResponse:
    """Build an HttpResponse for a CSV file download."""
    response = HttpResponse(content, content_type="text/csv")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    response["Cache-Control"] = "no-store"
    return response


class PaymentExportView(views.APIView):
    """
    GET: Download trainer payment history as CSV.
    Query params: ?days=30 (default 30, range 1-365)
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> HttpResponse:
        trainer = cast(User, request.user)
        days = parse_days_param(request)
        result = export_payments_csv(trainer, days)
        return _csv_response(result.content, result.filename)


class SubscriberExportView(views.APIView):
    """
    GET: Download trainer subscriber list as CSV.
    Includes all subscription statuses for bookkeeping.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> HttpResponse:
        trainer = cast(User, request.user)
        result = export_subscribers_csv(trainer)
        return _csv_response(result.content, result.filename)


class TraineeExportView(views.APIView):
    """
    GET: Download trainer trainee roster as CSV.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> HttpResponse:
        trainer = cast(User, request.user)
        result = export_trainees_csv(trainer)
        return _csv_response(result.content, result.filename)
