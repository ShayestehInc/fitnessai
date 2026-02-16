"""
User models for Fitness AI platform.
"""
from __future__ import annotations

from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models
from typing import Any, ClassVar, Optional, TYPE_CHECKING, cast

if TYPE_CHECKING:
    from typing_extensions import Self


class UserManager(BaseUserManager["User"]):
    """Custom user manager where email is the unique identifier."""

    def create_user(self, email: str, password: Optional[str] = None, **extra_fields: Any) -> User:
        """Create and save a user with the given email and password."""
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user: User = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email: str, password: Optional[str] = None, **extra_fields: Any) -> User:
        """Create and save a superuser with the given email and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', User.Role.ADMIN)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(email, password, **extra_fields)


class User(AbstractUser):
    """
    Custom User model with role-based access control.
    Uses email as the primary identifier (no username required).

    Roles:
    - ADMIN: Super Admin (platform owner)
    - TRAINER: Personal trainers who manage trainees
    - TRAINEE: End users who log workouts and nutrition
    """
    class Role(models.TextChoices):
        ADMIN = 'ADMIN', 'Admin'
        AMBASSADOR = 'AMBASSADOR', 'Ambassador'
        TRAINER = 'TRAINER', 'Trainer'
        TRAINEE = 'TRAINEE', 'Trainee'

    # Use email as the username field
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS: ClassVar[list[str]] = []  # Remove 'email' from required fields since it's now the username

    # Custom manager
    objects: ClassVar[UserManager] = UserManager()  # type: ignore[assignment]

    # Override username to be nullable (effectively removing it as identifier)
    # Django pattern: set to None when using email as username field
    username = None  # type: ignore[assignment]

    # Override email to make it unique (required when used as USERNAME_FIELD)
    email = models.EmailField(
        unique=True,
        help_text="Email address (used as username for login)"
    )


    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.TRAINEE,
        help_text="User role in the platform"
    )
    
    parent_trainer = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='trainees',
        limit_choices_to={'role': Role.TRAINER},
        help_text="The trainer assigned to this trainee (null for Admins/Trainers)"
    )
    
    phone_number = models.CharField(
        max_length=20,
        blank=True,
        null=True
    )

    business_name = models.CharField(
        max_length=150,
        blank=True,
        null=True,
        help_text="Business name for trainers"
    )

    profile_image = models.ImageField(
        upload_to='profiles/',
        blank=True,
        null=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['role']),
            models.Index(fields=['parent_trainer']),
        ]
    
    def __str__(self) -> str:
        return f"{self.email} ({self.role})"
    
    def is_trainer(self) -> bool:
        """Check if user is a trainer."""
        return self.role == self.Role.TRAINER
    
    def is_trainee(self) -> bool:
        """Check if user is a trainee."""
        return self.role == self.Role.TRAINEE
    
    def is_admin(self) -> bool:
        """Check if user is an admin."""
        return self.role == self.Role.ADMIN

    def is_ambassador(self) -> bool:
        """Check if user is an ambassador."""
        return self.role == self.Role.AMBASSADOR
    
    def get_active_trainees_count(self) -> int:
        """Get count of active trainees (only for trainers)."""
        if not self.is_trainer():
            return 0
        return self.trainees.filter(is_active=True).count()


class UserProfile(models.Model):
    """
    Extended profile for trainees with onboarding data and preferences.
    Used to calculate personalized nutrition goals.
    """
    class Sex(models.TextChoices):
        MALE = 'male', 'Male'
        FEMALE = 'female', 'Female'

    class ActivityLevel(models.TextChoices):
        SEDENTARY = 'sedentary', 'Sedentary'
        LIGHTLY_ACTIVE = 'lightly_active', 'Lightly Active'
        MODERATELY_ACTIVE = 'moderately_active', 'Moderately Active'
        VERY_ACTIVE = 'very_active', 'Very Active'
        EXTREMELY_ACTIVE = 'extremely_active', 'Extremely Active'

    class Goal(models.TextChoices):
        BUILD_MUSCLE = 'build_muscle', 'Build Muscle'
        FAT_LOSS = 'fat_loss', 'Fat Loss'
        RECOMP = 'recomp', 'Recomp'

    class DietType(models.TextChoices):
        LOW_CARB = 'low_carb', 'Low Carb'
        BALANCED = 'balanced', 'Balanced'
        HIGH_CARB = 'high_carb', 'High Carb'

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile'
    )

    # Physical attributes
    sex = models.CharField(
        max_length=10,
        choices=Sex.choices,
        null=True,
        blank=True
    )
    age = models.PositiveIntegerField(null=True, blank=True)
    height_cm = models.FloatField(null=True, blank=True)
    weight_kg = models.FloatField(null=True, blank=True)

    # Activity and goals
    activity_level = models.CharField(
        max_length=20,
        choices=ActivityLevel.choices,
        default=ActivityLevel.MODERATELY_ACTIVE
    )
    goal = models.CharField(
        max_length=20,
        choices=Goal.choices,
        default=Goal.BUILD_MUSCLE
    )

    # Diet preferences
    check_in_days = models.JSONField(
        default=list,
        help_text="Days of the week for weight check-ins (e.g., ['monday', 'thursday'])"
    )
    diet_type = models.CharField(
        max_length=20,
        choices=DietType.choices,
        default=DietType.BALANCED
    )
    meals_per_day = models.PositiveIntegerField(
        default=4,
        validators=[MinValueValidator(2), MaxValueValidator(6)]
    )

    # Leaderboard opt-in
    leaderboard_opt_in = models.BooleanField(
        default=True,
        help_text="Whether this trainee appears on leaderboards",
    )

    # Onboarding status
    onboarding_completed = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_profiles'

    def __str__(self) -> str:
        return f"Profile for {self.user.email}"


class DeviceToken(models.Model):
    """
    FCM device token for push notifications.
    One user can have multiple tokens (multiple devices).
    """
    class Platform(models.TextChoices):
        IOS = 'ios', 'iOS'
        ANDROID = 'android', 'Android'
        WEB = 'web', 'Web'

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='device_tokens',
    )
    token = models.CharField(max_length=512)
    platform = models.CharField(
        max_length=10,
        choices=Platform.choices,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'device_tokens'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'token'],
                name='unique_user_device_token',
            ),
        ]
        indexes = [
            models.Index(fields=['user', 'is_active']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email}: {self.platform} ({'active' if self.is_active else 'inactive'})"
