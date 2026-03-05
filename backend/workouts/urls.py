from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CheckInResponseViewSet,
    CheckInTemplateViewSet,
    DailyLogViewSet,
    ExerciseViewSet,
    HabitViewSet,
    MacroPresetViewSet,
    NutritionGoalViewSet,
    ProgressionSuggestionViewSet,
    ProgressPhotoViewSet,
    ProgramViewSet,
    WeightCheckInViewSet,
    WorkoutTemplateViewSet,
)
from .survey_views import ReadinessSurveyView, PostWorkoutSurveyView, MyLayoutConfigView

router = DefaultRouter()
router.register(r'exercises', ExerciseViewSet, basename='exercise')
router.register(r'programs', ProgramViewSet, basename='program')
router.register(r'daily-logs', DailyLogViewSet, basename='dailylog')
router.register(r'nutrition-goals', NutritionGoalViewSet, basename='nutritiongoal')
router.register(r'weight-checkins', WeightCheckInViewSet, basename='weightcheckin')
router.register(r'macro-presets', MacroPresetViewSet, basename='macropreset')
router.register(r'workout-templates', WorkoutTemplateViewSet, basename='workouttemplate')
router.register(r'progress-photos', ProgressPhotoViewSet, basename='progressphoto')
router.register(r'habits', HabitViewSet, basename='habit')
router.register(r'progression-suggestions', ProgressionSuggestionViewSet, basename='progressionsuggestion')
router.register(r'checkin-templates', CheckInTemplateViewSet, basename='checkintemplate')
router.register(r'checkin-responses', CheckInResponseViewSet, basename='checkinresponse')

urlpatterns = [
    path('', include(router.urls)),
    # Workout surveys
    path('surveys/readiness/', ReadinessSurveyView.as_view(), name='readiness-survey'),
    path('surveys/post-workout/', PostWorkoutSurveyView.as_view(), name='post-workout-survey'),
    path('my-layout/', MyLayoutConfigView.as_view(), name='my-layout-config'),
]
