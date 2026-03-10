# Dev Done: Wire All v6.5 Features Into Mobile Navigation

## Files Changed

### Created

- `mobile/lib/features/home/presentation/widgets/v65_feature_cards.dart` — 6 card widgets (TrainingPlansCard, LiftMaxesCard, WorkloadCard, VoiceMemosCard, VideoAnalysisCard, FeedbackHistoryCard)

### Modified

- `mobile/lib/features/home/presentation/widgets/dashboard_content.dart` — Added import and 6 card widgets between WeightLogCard and LeaderboardTeaserCard
- `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` — Added "Analytics & Insights" section with 4 cards (Correlations, Audit Trail, Decision Log, Import Programs) before "Your Trainees" section
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — Added "View Patterns" IconButton in SliverAppBar actions
- `mobile/lib/features/exercises/presentation/screens/exercise_bank_screen.dart` — Added go_router import, 3 new ListTiles in quick actions (Lift History, Auto-Tag, Tag History), 2 new OutlinedButtons in detail sheet (Lift History, Auto-Tag)

## Key Decisions

1. Used existing Card > InkWell pattern (matching QuickLogCard) for home screen cards
2. Used existing GestureDetector > Container pattern for trainer dashboard cards
3. Added exercise actions to both quick-actions and detail bottom sheet for discoverability
4. URI-encoded exercise name in tag history route to handle special characters

## Navigation Map

| Feature          | Route                           | Entry Point                     |
| ---------------- | ------------------------------- | ------------------------------- |
| Training Plans   | `/my-plans`                     | Home screen card                |
| Lift Maxes       | `/lift-maxes`                   | Home screen card                |
| Workload         | `/workload`                     | Home screen card                |
| Voice Memos      | `/voice-memos`                  | Home screen card                |
| Video Analysis   | `/video-analysis`               | Home screen card                |
| Session Feedback | `/feedback-history`             | Home screen card                |
| Correlations     | `/trainer/correlations`         | Trainer dashboard               |
| Audit Trail      | `/trainer/audit-trail`          | Trainer dashboard               |
| Decision Log     | `/decision-log`                 | Trainer dashboard               |
| Import Programs  | `/program-import`               | Trainer dashboard               |
| Trainee Patterns | `/trainer/trainee-patterns/:id` | Trainee detail app bar          |
| Lift History     | `/lift-history/:id`             | Exercise quick actions + detail |
| Auto-Tag         | `/auto-tag/:id`                 | Exercise quick actions + detail |
| Tag History      | `/tag-history/:id`              | Exercise quick actions          |

## How to Manually Test

1. Open app as trainee → scroll home screen → verify 6 new cards visible → tap each
2. Open app as trainer → scroll dashboard → verify Analytics & Insights section with 4 cards → tap each
3. Open trainee detail → verify patterns icon in app bar → tap it
4. Open exercise bank → long-press exercise → verify 3 new options → tap each
5. Open exercise detail → verify Lift History and Auto-Tag buttons → tap each
