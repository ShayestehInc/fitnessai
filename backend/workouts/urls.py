from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ExerciseViewSet,
    ProgramViewSet,
    DailyLogViewSet,
    NutritionGoalViewSet,
    WeightCheckInViewSet,
    MacroPresetViewSet,
)
from .survey_views import ReadinessSurveyView, PostWorkoutSurveyView

router = DefaultRouter()
router.register(r'exercises', ExerciseViewSet, basename='exercise')
router.register(r'programs', ProgramViewSet, basename='program')
router.register(r'daily-logs', DailyLogViewSet, basename='dailylog')
router.register(r'nutrition-goals', NutritionGoalViewSet, basename='nutritiongoal')
router.register(r'weight-checkins', WeightCheckInViewSet, basename='weightcheckin')
router.register(r'macro-presets', MacroPresetViewSet, basename='macropreset')

urlpatterns = [
    path('', include(router.urls)),
    # Workout surveys
    path('surveys/readiness/', ReadinessSurveyView.as_view(), name='readiness-survey'),
    path('surveys/post-workout/', PostWorkoutSurveyView.as_view(), name='post-workout-survey'),
]
