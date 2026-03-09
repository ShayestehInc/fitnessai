"""
Tests for ProgressPhoto CRUD, permissions, filtering, pagination, and comparison.
"""
from __future__ import annotations

import io
import json
from datetime import date, timedelta

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from PIL import Image
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User
from workouts.models import ProgressPhoto


def _make_image(name: str = "test.jpg", size: tuple[int, int] = (100, 100)) -> SimpleUploadedFile:
    """Create a small in-memory JPEG for upload tests."""
    buf = io.BytesIO()
    Image.new("RGB", size, color="red").save(buf, format="JPEG")
    buf.seek(0)
    return SimpleUploadedFile(name, buf.read(), content_type="image/jpeg")


class ProgressPhotoTestBase(TestCase):
    """Shared setup: trainer, two trainees (one assigned, one not), API clients."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee = User.objects.create_user(
            email="trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.other_trainer = User.objects.create_user(
            email="other_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.other_trainee = User.objects.create_user(
            email="other_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.other_trainer,
        )
        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee)

        self.other_trainee_client = APIClient()
        self.other_trainee_client.force_authenticate(user=self.other_trainee)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)

        self.other_trainer_client = APIClient()
        self.other_trainer_client.force_authenticate(user=self.other_trainer)

        self.list_url = "/api/workouts/progress-photos/"
        self.compare_url = "/api/workouts/progress-photos/compare/"

    def _create_photo(
        self,
        trainee: User | None = None,
        category: str = "front",
        photo_date: date | None = None,
        notes: str = "",
        measurements: dict | None = None,
    ) -> ProgressPhoto:
        """Helper to create a ProgressPhoto directly in the DB."""
        return ProgressPhoto.objects.create(
            trainee=trainee or self.trainee,
            photo=_make_image(),
            category=category,
            date=photo_date or date.today(),
            notes=notes,
            measurements=measurements or {},
        )


class TraineeListPhotosTests(ProgressPhotoTestBase):
    """1. Trainee can list their own photos."""

    def test_trainee_lists_own_photos(self) -> None:
        self._create_photo(category="front")
        self._create_photo(category="back")
        response = self.trainee_client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Paginated response has 'results'
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 2)

    def test_trainee_empty_list(self) -> None:
        response = self.trainee_client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 0)


class TraineeCreatePhotoTests(ProgressPhotoTestBase):
    """2. Trainee can create a photo with category, date, notes, measurements."""

    def test_create_photo_with_all_fields(self) -> None:
        measurements = {"waist_cm": 80, "chest_cm": 100}
        response = self.trainee_client.post(
            self.list_url,
            {
                "photo": _make_image(),
                "category": "front",
                "date": "2026-03-01",
                "notes": "Week 1 progress",
                "measurements": json.dumps(measurements),
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["category"], "front")
        self.assertEqual(response.data["notes"], "Week 1 progress")
        self.assertEqual(response.data["date"], "2026-03-01")
        # Verify measurements stored correctly
        photo = ProgressPhoto.objects.get(id=response.data["id"])
        self.assertIsInstance(photo.measurements, dict)

    def test_create_photo_minimal_fields(self) -> None:
        response = self.trainee_client.post(
            self.list_url,
            {
                "photo": _make_image(),
                "category": "back",
                "date": "2026-03-02",
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_create_photo_auto_assigns_trainee(self) -> None:
        """Trainee field should be auto-set to authenticated user, not from request."""
        response = self.trainee_client.post(
            self.list_url,
            {
                "photo": _make_image(),
                "category": "side",
                "date": "2026-03-01",
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        photo = ProgressPhoto.objects.get(id=response.data["id"])
        self.assertEqual(photo.trainee_id, self.trainee.id)


class TraineeDeletePhotoTests(ProgressPhotoTestBase):
    """3. Trainee can delete their own photo."""

    def test_delete_own_photo(self) -> None:
        photo = self._create_photo()
        url = f"{self.list_url}{photo.id}/"
        response = self.trainee_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(ProgressPhoto.objects.filter(id=photo.id).exists())


class TraineeIsolationTests(ProgressPhotoTestBase):
    """4. Trainee CANNOT see another trainee's photos."""

    def test_trainee_cannot_see_others_photos(self) -> None:
        self._create_photo(trainee=self.other_trainee)
        response = self.trainee_client.get(self.list_url)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 0)

    def test_trainee_cannot_delete_others_photo(self) -> None:
        photo = self._create_photo(trainee=self.other_trainee)
        url = f"{self.list_url}{photo.id}/"
        response = self.trainee_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(ProgressPhoto.objects.filter(id=photo.id).exists())


class TrainerReadAccessTests(ProgressPhotoTestBase):
    """5. Trainer can see their trainee's photos via ?trainee_id=X."""

    def test_trainer_sees_trainee_photos_with_id(self) -> None:
        self._create_photo(trainee=self.trainee, category="front")
        self._create_photo(trainee=self.trainee, category="back")
        response = self.trainer_client.get(
            self.list_url, {"trainee_id": self.trainee.id}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 2)

    def test_trainer_sees_all_own_trainees_without_id(self) -> None:
        """Without trainee_id, trainer should see all their trainees' photos."""
        self._create_photo(trainee=self.trainee)
        response = self.trainer_client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)


class TrainerCannotSeeOtherTrainerTraineeTests(ProgressPhotoTestBase):
    """6. Trainer CANNOT see photos of a trainee not assigned to them."""

    def test_trainer_cannot_see_other_trainers_trainee(self) -> None:
        self._create_photo(trainee=self.other_trainee)
        response = self.trainer_client.get(
            self.list_url, {"trainee_id": self.other_trainee.id}
        )
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 0)

    def test_trainer_without_id_sees_only_own_trainees(self) -> None:
        self._create_photo(trainee=self.trainee)
        self._create_photo(trainee=self.other_trainee)
        response = self.trainer_client.get(self.list_url)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)


class TrainerCannotCUDTests(ProgressPhotoTestBase):
    """7. Trainer CANNOT create/update/delete photos (403)."""

    def test_trainer_cannot_create_photo(self) -> None:
        response = self.trainer_client.post(
            self.list_url,
            {
                "photo": _make_image(),
                "category": "front",
                "date": "2026-03-01",
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_cannot_update_photo(self) -> None:
        photo = self._create_photo(trainee=self.trainee)
        url = f"{self.list_url}{photo.id}/"
        response = self.trainer_client.patch(
            url,
            {"notes": "edited by trainer"},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_cannot_delete_photo(self) -> None:
        photo = self._create_photo(trainee=self.trainee)
        url = f"{self.list_url}{photo.id}/"
        response = self.trainer_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(ProgressPhoto.objects.filter(id=photo.id).exists())


class InvalidDateParamTests(ProgressPhotoTestBase):
    """8. Invalid date params are handled gracefully (not 500)."""

    def test_invalid_date_from_returns_ok(self) -> None:
        self._create_photo()
        response = self.trainee_client.get(self.list_url, {"date_from": "not-a-date"})
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST])

    def test_invalid_date_to_returns_ok(self) -> None:
        self._create_photo()
        response = self.trainee_client.get(self.list_url, {"date_to": "abc"})
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST])

    def test_valid_date_range_filters(self) -> None:
        self._create_photo(photo_date=date(2026, 1, 1))
        self._create_photo(photo_date=date(2026, 3, 1))
        response = self.trainee_client.get(
            self.list_url,
            {"date_from": "2026-02-01", "date_to": "2026-04-01"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)


class CompareEndpointTests(ProgressPhotoTestBase):
    """9 & 10. Compare endpoint works with valid IDs and rejects invalid ones."""

    def test_compare_valid_photos(self) -> None:
        photo1 = self._create_photo(category="front", photo_date=date(2026, 1, 1))
        photo2 = self._create_photo(category="front", photo_date=date(2026, 3, 1))
        response = self.trainee_client.get(
            self.compare_url,
            {"photo1": photo1.id, "photo2": photo2.id},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["photos"]), 2)

    def test_compare_missing_params(self) -> None:
        response = self.trainee_client.get(self.compare_url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_compare_missing_one_param(self) -> None:
        photo1 = self._create_photo()
        response = self.trainee_client.get(self.compare_url, {"photo1": photo1.id})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_compare_photo_not_belonging_to_user(self) -> None:
        """Trainee cannot compare photos they don't own."""
        photo1 = self._create_photo(trainee=self.trainee)
        photo2 = self._create_photo(trainee=self.other_trainee)
        response = self.trainee_client.get(
            self.compare_url,
            {"photo1": photo1.id, "photo2": photo2.id},
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_compare_nonexistent_photo(self) -> None:
        photo1 = self._create_photo()
        response = self.trainee_client.get(
            self.compare_url,
            {"photo1": photo1.id, "photo2": 99999},
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_compare_non_numeric_id(self) -> None:
        """Non-numeric photo IDs should return 400, not 500."""
        photo1 = self._create_photo()
        response = self.trainee_client.get(
            self.compare_url,
            {"photo1": photo1.id, "photo2": "abc"},
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_trainer_can_compare_trainee_photos(self) -> None:
        photo1 = self._create_photo(trainee=self.trainee, photo_date=date(2026, 1, 1))
        photo2 = self._create_photo(trainee=self.trainee, photo_date=date(2026, 3, 1))
        response = self.trainer_client.get(
            self.compare_url,
            {"photo1": photo1.id, "photo2": photo2.id, "trainee_id": self.trainee.id},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)


class PaginationTests(ProgressPhotoTestBase):
    """11. Pagination works (page_size param)."""

    def test_default_pagination_20(self) -> None:
        for i in range(25):
            self._create_photo(photo_date=date(2026, 1, 1) + timedelta(days=i))
        response = self.trainee_client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 20)
        self.assertEqual(response.data["count"], 25)
        self.assertIsNotNone(response.data["next"])

    def test_custom_page_size(self) -> None:
        for i in range(15):
            self._create_photo(photo_date=date(2026, 1, 1) + timedelta(days=i))
        response = self.trainee_client.get(self.list_url, {"page_size": 5})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 5)

    def test_page_size_capped_at_50(self) -> None:
        for i in range(55):
            self._create_photo(photo_date=date(2026, 1, 1) + timedelta(days=i))
        response = self.trainee_client.get(self.list_url, {"page_size": 100})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertLessEqual(len(response.data["results"]), 50)

    def test_second_page(self) -> None:
        for i in range(25):
            self._create_photo(photo_date=date(2026, 1, 1) + timedelta(days=i))
        response = self.trainee_client.get(self.list_url, {"page": 2})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 5)


class CategoryFilterTests(ProgressPhotoTestBase):
    """12. Category filtering works."""

    def test_filter_by_front(self) -> None:
        self._create_photo(category="front")
        self._create_photo(category="back")
        self._create_photo(category="side")
        response = self.trainee_client.get(self.list_url, {"category": "front"})
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["category"], "front")

    def test_filter_by_back(self) -> None:
        self._create_photo(category="front")
        self._create_photo(category="back")
        response = self.trainee_client.get(self.list_url, {"category": "back"})
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)

    def test_filter_by_other(self) -> None:
        self._create_photo(category="other")
        self._create_photo(category="front")
        response = self.trainee_client.get(self.list_url, {"category": "other"})
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)

    def test_invalid_category_returns_all(self) -> None:
        """Unknown category value should not filter (ignored)."""
        self._create_photo(category="front")
        self._create_photo(category="back")
        response = self.trainee_client.get(self.list_url, {"category": "invalid"})
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 2)

    def test_trainer_category_filter_on_trainee(self) -> None:
        self._create_photo(trainee=self.trainee, category="front")
        self._create_photo(trainee=self.trainee, category="back")
        response = self.trainer_client.get(
            self.list_url,
            {"trainee_id": self.trainee.id, "category": "front"},
        )
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 1)


class UnauthenticatedAccessTests(TestCase):
    """Unauthenticated users get 401."""

    def test_unauthenticated_list(self) -> None:
        client = APIClient()
        response = client.get("/api/workouts/progress-photos/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_create(self) -> None:
        client = APIClient()
        response = client.post("/api/workouts/progress-photos/", {})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TrainerInvalidTraineeIdTests(ProgressPhotoTestBase):
    """Edge case: trainer passes invalid trainee_id."""

    def test_non_numeric_trainee_id(self) -> None:
        response = self.trainer_client.get(self.list_url, {"trainee_id": "abc"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 0)

    def test_nonexistent_trainee_id(self) -> None:
        response = self.trainer_client.get(self.list_url, {"trainee_id": 99999})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get("results", response.data)
        self.assertEqual(len(results), 0)
