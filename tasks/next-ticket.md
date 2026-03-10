# Feature: Wire All v6.5 Features Into Mobile Navigation

## Priority

Critical — All v6.5 feature screens exist but are orphaned with no UI entry points.

## User Story

As a trainee, I want to discover and access all v6.5 features (training plans, lift maxes, workload, voice memos, video analysis, session feedback) from the home screen so that I can use them without needing direct URLs.

As a trainer, I want to access analytics, audit trail, decision log, and program import from my dashboard so that I can monitor trainee progress and manage programs.

## Acceptance Criteria

- [ ] Trainee home screen has cards for: Training Plans, Lift Maxes, Workload, Voice Memos, Video Analysis, Session Feedback
- [ ] Each card navigates to the correct route when tapped
- [ ] Cards follow existing design patterns (Card > InkWell > Row with icon, title, subtitle, chevron)
- [ ] Trainer dashboard has Analytics & Insights section with: Correlations, Audit Trail, Decision Log, Import Programs
- [ ] Trainee detail screen has "View Patterns" action button in app bar
- [ ] Exercise bank long-press menu has: Lift History, Auto-Tag, Tag History options
- [ ] Exercise detail sheet has Lift History and Auto-Tag buttons
- [ ] All navigation uses go_router context.push()
- [ ] No compilation errors
- [ ] No new warnings introduced

## Edge Cases

1. Cards should be const where possible for performance
2. Route parameters must match router definitions (int vs string IDs)
3. Exercise name must be URI-encoded when passed as query parameter
4. Cards should work in both light and dark themes
5. Long lists of cards should not cause scroll performance issues

## UX Requirements

- **Loading state:** N/A — cards are static navigation links
- **Empty state:** N/A — cards always visible
- **Error state:** N/A — no data fetching
- **Success feedback:** Navigation occurs on tap
- **Mobile behavior:** Cards are full-width, follow existing spacing

## Technical Approach

- Files created: `v65_feature_cards.dart` (6 card widgets)
- Files modified: `dashboard_content.dart`, `trainer_dashboard_screen.dart`, `trainee_detail_screen.dart`, `exercise_bank_screen.dart`
- No new dependencies

## Out of Scope

- Changing the screens themselves
- Adding new routes (all routes already exist)
- Backend changes
