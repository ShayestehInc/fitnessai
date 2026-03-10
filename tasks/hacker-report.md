# Hacker Report: v6.5 Navigation Wiring

## Dead Buttons & Non-Functional UI

| #   | Severity | Screen/Component    | Element    | Expected                                 | Actual                                                                   |
| --- | -------- | ------------------- | ---------- | ---------------------------------------- | ------------------------------------------------------------------------ |
| 1   | Medium   | VoiceMemoListScreen | Upload FAB | Opens file picker to upload a voice memo | Shows snackbar "Upload not yet wired to file picker." -- completely dead |

## Visual Misalignments & Layout Bugs

| #   | Severity | Screen/Component        | Issue                                                                                  | Fix                                          |
| --- | -------- | ----------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------- |
| 1   | Low      | VideoAnalysisListScreen | Uses raw `CircularProgressIndicator` instead of `AdaptiveSpinner` used everywhere else | **FIXED** -- replaced with `AdaptiveSpinner` |

## Broken Flows & Logic Bugs

| #   | Severity | Flow                               | Steps to Reproduce             | Expected                                                                                   | Actual                                                                                                                                                                                                                                |
| --- | -------- | ---------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Medium   | VoiceMemoListScreen -> Detail      | Tap a voice memo card          | Navigates via go_router (`/voice-memos/:id`) for consistent deep-linking and back behavior | Used `Navigator.of(context).push(MaterialPageRoute(...))` bypassing go_router entirely. This breaks deep-link support and produces inconsistent back-button behavior. **FIXED** -- now uses `context.push('/voice-memos/${memo.id}')` |
| 2   | Low      | DashboardContent.\_workoutWeekdays | Parse a malformed workout date | Error handled gracefully                                                                   | Used `debugPrint()` which violates project "No debug prints" rule. **FIXED** -- removed `debugPrint`, kept catch with explanatory comment                                                                                             |

## Product Improvement Suggestions

| #   | Impact | Area                  | Suggestion                                                                                                              | Rationale                                                                                                                          |
| --- | ------ | --------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Medium | FeedbackHistoryScreen | Add pull-to-refresh (`RefreshIndicator`). Every other list screen has it. **FIXED**                                     | Users expect swipe-to-refresh on list screens. Without it, the only way to reload is leaving and re-entering the screen.           |
| 2   | Medium | VoiceMemoListScreen   | Wire the upload FAB to an actual file picker or audio recorder                                                          | The feature is prominently surfaced from the home dashboard but the primary action does nothing. First-time users will lose trust. |
| 3   | Low    | V65FeatureSection     | Consider collapsing the "Performance" and "AI Tools" sections when user has no data (zero plans, zero lift maxes, etc.) | Avoids showing a wall of navigation cards to a brand-new user who has no data in any of these screens yet. Progressive disclosure. |
| 4   | Low    | All target screens    | Add hero/shared-element transitions from the nav cards to the target screen app bars                                    | Would make navigation feel polished and connected rather than abrupt.                                                              |

## Screens Verified (NOT Dead UI)

All six v6.5 feature card routes are wired and render real content:

- `/my-plans` -> `MyPlansScreen` -- full CRUD with filter chips, loading/empty/error states
- `/lift-maxes` -> `LiftMaxScreen` -- exercise list with e1RM/TM values, bottom sheet history charts
- `/workload` -> `WorkloadScreen` -- ACWR indicator, weekly overview, muscle group and daily breakdowns
- `/voice-memos` -> `VoiceMemoListScreen` -- memo list with cards, empty/error states
- `/video-analysis` -> `VideoAnalysisListScreen` -- analysis list with upload FAB and overlay
- `/feedback-history` -> `FeedbackHistoryScreen` -- feedback cards with ratings, pain events, completion badges

All routes are registered in `app_router.dart` and point to real screen implementations with proper loading, empty, and error states.

## Summary

- Dead UI elements found: 1 (Voice memo upload FAB -- not fixed, needs design decision on recorder vs file picker)
- Visual bugs found: 1 (fixed)
- Logic bugs found: 2 (both fixed)
- Improvements suggested: 4
- Items fixed by hacker: 4

## Chaos Score: 7/10

Navigation wiring is solid -- all cards navigate to real screens with real data. The main gaps are the dead upload FAB on voice memos and the missing pull-to-refresh on feedback history (now fixed). No crashes, no missing routes, no "Coming Soon" placeholders on target screens.
