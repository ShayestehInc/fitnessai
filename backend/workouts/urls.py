from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CheckInResponseViewSet,
    CheckInTemplateViewSet,
    DailyLogViewSet,
    DecisionLogViewSet,
    ExerciseViewSet,
    FoodItemViewSet,
    HabitViewSet,
    LiftMaxViewSet,
    LiftSetLogViewSet,
    MacroPresetViewSet,
    MealLogViewSet,
    NutritionDayPlanViewSet,
    NutritionGoalViewSet,
    NutritionTemplateAssignmentViewSet,
    NutritionTemplateViewSet,
    PlanSessionViewSet,
    PlanSlotViewSet,
    ProgressionProfileViewSet,
    ProgressionSuggestionViewSet,
    ProgressPhotoViewSet,
    ProgramViewSet,
    SetStructureModalityViewSet,
    SplitTemplateViewSet,
    TrainingPlanViewSet,
    WeightCheckInViewSet,
    WorkloadFactTemplateViewSet,
    WorkloadViewSet,
    WorkoutTemplateViewSet,
)
from .session_views import ActiveSessionViewSet
from .feedback_views import (
    PainEventViewSet,
    SessionFeedbackViewSet,
    TrainerRoutingRuleViewSet,
)
from .survey_views import ReadinessSurveyView, PostWorkoutSurveyView, MyLayoutConfigView
from .import_views import (
    ProgramImportConfirmView,
    ProgramImportDetailView,
    ProgramImportListView,
    ProgramImportUploadView,
)
from .auto_tag_views import (
    ApplyDraftView,
    AutoTagDraftView,
    RejectDraftView,
    RequestAutoTagView,
    RetryDraftView,
    TagHistoryView,
)
from .media_views import (
    VideoAnalysisConfirmView,
    VideoAnalysisDetailView,
    VideoAnalysisListView,
    VideoAnalysisUploadView,
    VoiceMemoDetailView,
    VoiceMemoListView,
    VoiceMemoUploadView,
)

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
router.register(r'nutrition-templates', NutritionTemplateViewSet, basename='nutritiontemplate')
router.register(r'nutrition-template-assignments', NutritionTemplateAssignmentViewSet, basename='nutritiontemplateassignment')
router.register(r'nutrition-day-plans', NutritionDayPlanViewSet, basename='nutritiondayplan')
router.register(r'food-items', FoodItemViewSet, basename='fooditem')
router.register(r'meal-logs', MealLogViewSet, basename='meallog')
router.register(r'decision-logs', DecisionLogViewSet, basename='decisionlog')
router.register(r'lift-set-logs', LiftSetLogViewSet, basename='liftsetlog')
router.register(r'lift-maxes', LiftMaxViewSet, basename='liftmax')
router.register(r'workload-facts', WorkloadFactTemplateViewSet, basename='workloadfacttemplate')
router.register(r'workload', WorkloadViewSet, basename='workload')
router.register(r'training-plans', TrainingPlanViewSet, basename='trainingplan')
router.register(r'plan-slots', PlanSlotViewSet, basename='planslot')
router.register(r'plan-sessions', PlanSessionViewSet, basename='plansession')
router.register(r'modalities', SetStructureModalityViewSet, basename='modality')
router.register(r'split-templates', SplitTemplateViewSet, basename='splittemplate')
router.register(r'progression-profiles', ProgressionProfileViewSet, basename='progressionprofile')
router.register(r'sessions', ActiveSessionViewSet, basename='activesession')
router.register(r'session-feedback', SessionFeedbackViewSet, basename='sessionfeedback')
router.register(r'pain-events', PainEventViewSet, basename='painevent')
router.register(r'routing-rules', TrainerRoutingRuleViewSet, basename='routingrule')

urlpatterns = [
    path('', include(router.urls)),
    # Workout surveys
    path('surveys/readiness/', ReadinessSurveyView.as_view(), name='readiness-survey'),
    path('surveys/post-workout/', PostWorkoutSurveyView.as_view(), name='post-workout-survey'),
    path('my-layout/', MyLayoutConfigView.as_view(), name='my-layout-config'),

    # Program imports (v6.5 Step 12)
    path('program-imports/', ProgramImportListView.as_view(), name='program-import-list'),
    path('program-imports/upload/', ProgramImportUploadView.as_view(), name='program-import-upload'),
    path('program-imports/<str:draft_id>/', ProgramImportDetailView.as_view(), name='program-import-detail'),
    path('program-imports/<str:draft_id>/confirm/', ProgramImportConfirmView.as_view(), name='program-import-confirm'),

    # Exercise auto-tagging (v6.5 Step 13)
    path('exercises/<int:exercise_id>/auto-tag/', RequestAutoTagView.as_view(), name='exercise-auto-tag'),
    path('exercises/<int:exercise_id>/auto-tag-draft/', AutoTagDraftView.as_view(), name='exercise-auto-tag-draft'),
    path('exercises/<int:exercise_id>/auto-tag-draft/apply/', ApplyDraftView.as_view(), name='exercise-auto-tag-apply'),
    path('exercises/<int:exercise_id>/auto-tag-draft/reject/', RejectDraftView.as_view(), name='exercise-auto-tag-reject'),
    path('exercises/<int:exercise_id>/auto-tag-draft/retry/', RetryDraftView.as_view(), name='exercise-auto-tag-retry'),
    path('exercises/<int:exercise_id>/tag-history/', TagHistoryView.as_view(), name='exercise-tag-history'),

    # Voice memos (v6.5 Step 14)
    path('voice-memos/', VoiceMemoUploadView.as_view(), name='voice-memo-upload'),
    path('voice-memos/list/', VoiceMemoListView.as_view(), name='voice-memo-list'),
    path('voice-memos/<str:memo_id>/', VoiceMemoDetailView.as_view(), name='voice-memo-detail'),

    # Video analysis (v6.5 Step 14)
    path('video-analysis/', VideoAnalysisUploadView.as_view(), name='video-analysis-upload'),
    path('video-analysis/list/', VideoAnalysisListView.as_view(), name='video-analysis-list'),
    path('video-analysis/<str:analysis_id>/', VideoAnalysisDetailView.as_view(), name='video-analysis-detail'),
    path('video-analysis/<str:analysis_id>/confirm/', VideoAnalysisConfirmView.as_view(), name='video-analysis-confirm'),
]
