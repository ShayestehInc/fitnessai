# UX Audit: v6.5 Navigation Wiring

## Scope

Auditing the new v6.5 feature card navigation on the trainee home screen, trainer dashboard analytics section, trainee detail screen insights button, and exercise bank quick actions.

---

## Usability Issues

| #   | Severity | Screen/Component                         | Issue                                                                                                                                                                                               | Recommendation                                                                                                                                       | Status |
| --- | -------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 1   | Major    | Home / DashboardContent                  | 6 v6.5 feature cards stacked vertically with no section headers or logical grouping. User sees a wall of cards with no context about what they are.                                                 | Group into "Performance" (Training Plans, Lift Maxes, Workload, Session Feedback) and "AI Tools" (Voice Memos, Video Analysis) with section headers. | FIXED  |
| 2   | Medium   | Trainer Dashboard / Analytics            | "Import Programs" placed in "Analytics & Insights" section. Importing is an action, not an insight. Breaks the mental model.                                                                        | Moved to sit under "Your Programs" section where it logically belongs.                                                                               | FIXED  |
| 3   | Medium   | Trainer Dashboard / \_buildAnalyticsCard | Missing Semantics wrapper for accessibility. Home screen feature cards have `Semantics(button: true, label: ...)` but trainer analytics cards did not.                                              | Added Semantics wrapper with button role and label.                                                                                                  | FIXED  |
| 4   | Minor    | Home / v65_feature_cards.dart            | Session Feedback card (amber icon, `Icons.rate_review_rounded`) grouped with AI tools rather than performance tracking. Feedback about workout sessions relates more to performance review than AI. | Moved to Performance group.                                                                                                                          | FIXED  |

## Accessibility Issues

| #   | WCAG Level | Issue                                                                                                                     | Fix                                                                   |
| --- | ---------- | ------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| 1   | A          | Trainer dashboard analytics cards missing Semantics wrapper — screen readers cannot identify these as interactive buttons | Added `Semantics(button: true, label: 'Navigate to $title')` wrapper. |

## Missing States

- [x] Loading / skeleton — Not applicable (cards are static navigation)
- [x] Empty / zero data — Not applicable (cards are always visible)
- [x] Error / failure — Routes handle their own error states
- [x] Success / confirmation — Navigation handles this
- [x] Offline / degraded — Not applicable for nav cards
- [x] Permission denied — Route guards handle this

## Information Hierarchy Assessment

The `_FeatureNavCard` component is well-designed:

- Icon with colored background container provides visual anchor
- Title in `titleSmall` with w600 weight is scannable
- Subtitle in `bodySmall` with `onSurfaceVariant` color creates clear hierarchy
- Chevron_right affordance signals tappability
- Card wrapping with InkWell provides proper touch feedback

## Icon/Color Choices

| Card             | Icon                     | Color   | Assessment                                         |
| ---------------- | ------------------------ | ------- | -------------------------------------------------- |
| Training Plans   | `calendar_today_rounded` | primary | Good — plans are schedule-oriented                 |
| Lift Maxes       | `trending_up_rounded`    | orange  | Good — upward trend maps to strength gains         |
| Workload         | `bar_chart_rounded`      | purple  | Good — chart icon for data visualization           |
| Voice Memos      | `mic_rounded`            | teal    | Good — microphone is universally understood        |
| Video Analysis   | `videocam_rounded`       | blue    | Good — camera for video, distinct from mic         |
| Session Feedback | `rate_review_rounded`    | amber   | Good — review/rating icon, warm color for feedback |

No icon collisions. Colors are sufficiently distinct from each other.

## Trainer Dashboard Placement

The analytics section (Correlations, Audit Trail, Decision Log) is well-placed after the content sections (Programs, Exercises) and before the Trainees list. This follows a logical flow: content -> insights about content -> people who use the content.

## Exercise Quick Actions Discoverability

The exercise bank provides two discovery paths:

1. **Quick action buttons** (Lift History, Auto-Tag) shown inline in the exercise detail bottom sheet — good for power users
2. **Long-press menu** with full list (View Details, Lift History, Auto-Tag, Tag History) — good for discovery

Both paths are consistent in routing and labeling. The `Icons.history`, `Icons.auto_fix_high`, and `Icons.label` choices are appropriate.

## Trainee Detail Insights Button

The `Icons.insights` button in the trainee detail app bar is compact but discoverable via tooltip ('View Patterns'). Placement alongside the AI chat button is logical — both are analysis actions on the trainee.

---

## Files Changed

| File                                                                             | Change                                                                                |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `mobile/lib/features/home/presentation/widgets/dashboard_content.dart`           | Added "Performance" and "AI Tools" section headers; regrouped cards logically         |
| `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` | Moved Import Programs to Programs section; added Semantics wrapper to analytics cards |

## Overall UX Score: 8/10

The card component design is solid (consistent, accessible, clear hierarchy). The main issue was the lack of grouping on the home screen which made 6 new cards feel overwhelming. With section headers and logical grouping, the home screen now has clear information architecture. The trainer dashboard analytics section is clean and well-organized after moving Import Programs to its proper home.
