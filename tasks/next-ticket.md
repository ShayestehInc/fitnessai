# Feature: Web Dashboard Full Parity + UI/UX Polish + E2E Test Suite

## Priority
Critical

## User Story
As a **Trainer**, I want the web dashboard to have every feature the mobile app has so I can manage my entire business from my desktop without needing the phone app.

As an **Admin**, I want to manage ambassadors, commissions, and platform settings from the web dashboard so I have a single pane of glass for platform operations.

As an **Ambassador**, I want a dedicated web dashboard to view my referrals, earnings, and share my referral code so I can work from any device.

As a **platform user**, I want a visually polished, animated login experience and smooth page transitions so the product feels world-class.

As a **developer**, I want comprehensive E2E tests covering every role and feature so regressions are caught automatically.

---

## Workstream 1: Feature Parity

### Trainer Features (AC-1 through AC-16)

---

#### AC-1: Trainer Announcements Page

**Route:** `/announcements`
**Page file:** `web/src/app/(dashboard)/announcements/page.tsx`
**Components:**
- `web/src/components/announcements/announcement-list.tsx` -- DataTable listing all announcements with columns: Title, Pinned (pin icon), Content preview (truncated), Created date. Sort by pinned first, then date desc.
- `web/src/components/announcements/announcement-form-dialog.tsx` -- Dialog for create/edit. Fields: Title (required, max 200 chars), Body (required, max 2000 chars, textarea), Content format (plain/markdown toggle), Pinned checkbox. Character counters on both fields.
- `web/src/components/announcements/announcement-delete-dialog.tsx` -- Confirmation dialog with "Cannot be undone" warning.
- `web/src/components/announcements/announcement-list-skeleton.tsx` -- Shimmer skeleton matching table layout.
**Hook:** `web/src/hooks/use-announcements.ts`
- `useAnnouncements()` -- `GET /api/trainer/announcements/` with pagination
- `useCreateAnnouncement()` -- `POST /api/trainer/announcements/`
- `useUpdateAnnouncement(id)` -- `PUT /api/trainer/announcements/:id/`
- `useDeleteAnnouncement()` -- `DELETE /api/trainer/announcements/:id/`
**Type:** `web/src/types/announcement.ts` -- `Announcement { id, title, body, content_format, is_pinned, created_at, updated_at }`
**Nav:** Add "Announcements" link to `web/src/components/layout/nav-links.tsx` with `Megaphone` icon, between Analytics and Notifications.
**API Constants:** Add to `web/src/lib/constants.ts`:
```
ANNOUNCEMENTS: `${API_BASE}/api/trainer/announcements/`
announcementDetail: (id: number) => `${API_BASE}/api/trainer/announcements/${id}/`
```
**States:**
- Loading: Skeleton table with 5 shimmer rows
- Empty: EmptyState with Megaphone icon, "No announcements yet", "Create your first announcement to broadcast to all trainees", CTA button "Create Announcement"
- Error: ErrorState with retry
- Success: Toast "Announcement created" / "Announcement updated" / "Announcement deleted"
**Edge cases:**
1. Creating with only whitespace title/body shows inline validation error
2. Editing a pinned announcement preserves pin state
3. Deleting the only announcement shows empty state
4. Markdown preview toggle in form (show raw / rendered side-by-side)
5. Long title truncates in table with ellipsis and tooltip on hover

---

#### AC-2: Trainer AI Chat Page

**Route:** `/ai-chat`
**Page file:** `web/src/app/(dashboard)/ai-chat/page.tsx`
**Components:**
- `web/src/components/ai-chat/chat-container.tsx` -- Full-height chat layout with message list and input area. Scrolls to bottom on new message.
- `web/src/components/ai-chat/chat-message.tsx` -- Message bubble. User messages right-aligned (primary bg), AI messages left-aligned (muted bg). Copy button on hover. Markdown rendering for AI responses.
- `web/src/components/ai-chat/trainee-selector.tsx` -- Dropdown at top to select a trainee for context. Shows "All trainees" by default. Uses existing `useAllTrainees()` hook from `use-trainees.ts`.
- `web/src/components/ai-chat/suggestion-chips.tsx` -- Quick-start prompts: "Who needs attention this week?", "Generate a weekly summary", "Compare trainee compliance". Shown in empty state.
- `web/src/components/ai-chat/chat-skeleton.tsx` -- Shimmer skeleton for loading state.
**Hook:** `web/src/hooks/use-ai-chat.ts`
- `useAiChat()` -- manages local message state (not server-persisted). `sendMessage()` calls `POST /api/trainer/ai/chat/` with `{ message, trainee_id? }`. Returns full response.
- `useAiProviders()` -- `GET /api/trainer/ai/providers/` to check if AI is configured.
**Type:** `web/src/types/ai-chat.ts` -- `ChatMessage { role: 'user' | 'assistant', content: string, timestamp: string }`, `AiChatRequest { message: string, trainee_id?: number }`, `AiChatResponse { response: string }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
AI_CHAT: `${API_BASE}/api/trainer/ai/chat/`
AI_CONTEXT: (traineeId: number) => `${API_BASE}/api/trainer/ai/context/${traineeId}/`
AI_PROVIDERS: `${API_BASE}/api/trainer/ai/providers/`
```
**Nav:** Add "AI Chat" link to `nav-links.tsx` with `BrainCircuit` icon, after Programs.
**States:**
- Empty: Centered AI icon (psychology_outlined equivalent), "AI Assistant" title, description, suggestion chips
- Loading (sending): Spinner on send button, input disabled, typing indicator bubble in message list
- Error: Red banner at top with error text, dismiss X button
- Clear conversation: Confirmation dialog "Clear all messages?"
**Edge cases:**
1. Sending empty message does nothing (button disabled for empty input)
2. Network error during send shows error banner, message stays in input
3. Very long AI response renders with proper word wrap and scroll
4. Switching trainee context clears conversation with confirmation if messages exist
5. Copy button copies message content to clipboard with toast "Copied to clipboard"
6. AI not configured (no providers): Show warning "AI is not configured. Contact your admin."

---

#### AC-3: Trainer Branding/White-Label Settings

**Route:** `/settings` (add new "Branding" section to existing settings page)
**Component:** `web/src/components/settings/branding-section.tsx`
- Card with sections:
  - App Name input (max 50 chars, character counter)
  - Primary Color: 12 preset color swatches (clickable circles) + hex input with # prefix. Live color preview.
  - Secondary Color: Same UI as primary.
  - Logo Upload: Drop zone (dashed border, drag-over highlight) accepting JPEG/PNG/WebP, 5MB max. Current logo preview with "Remove" button. Upload progress indicator.
  - Live Preview: Mini card mockup showing how the branding looks (app name in header, primary color applied, logo if present).
  - Save button (disabled when no changes). Reset to Defaults button.
**Hook:** `web/src/hooks/use-branding.ts`
- `useBranding()` -- `GET /api/trainer/branding/`
- `useUpdateBranding()` -- `PUT /api/trainer/branding/`
- `useUploadLogo()` -- `POST /api/trainer/branding/logo/` (multipart FormData)
- `useRemoveLogo()` -- `DELETE /api/trainer/branding/logo/`
**Type:** `web/src/types/branding.ts` -- `TrainerBranding { app_name: string, primary_color: string, secondary_color: string, logo: string | null }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
TRAINER_BRANDING: `${API_BASE}/api/trainer/branding/`
TRAINER_BRANDING_LOGO: `${API_BASE}/api/trainer/branding/logo/`
```
**States:**
- Loading: Skeleton card with shimmer placeholders for each section
- Save success: Toast "Branding updated"
- Logo upload success: Toast "Logo uploaded", preview refreshes
- Logo remove: Confirmation dialog "Remove your logo?", then Toast "Logo removed"
- Reset to defaults: Confirmation dialog "Reset all branding to FitnessAI defaults?", clears all fields
**Edge cases:**
1. Invalid hex color (not 6 hex chars) shows inline validation "Enter a valid hex color"
2. Logo over 5MB shows error "File must be under 5MB" before upload starts
3. Non-image file type rejected with "Only JPEG, PNG, and WebP images are accepted"
4. Unsaved changes warning on browser navigation (beforeunload event)
5. Color preview updates live as user types hex code
6. Preset colors: 12 fitness-appropriate colors (indigo, blue, green, teal, purple, pink, red, orange, amber, slate, zinc, emerald)

---

#### AC-4: Exercise Bank Page

**Route:** `/exercises`
**Page file:** `web/src/app/(dashboard)/exercises/page.tsx`
**Components:**
- `web/src/components/exercises/exercise-list.tsx` -- Responsive grid of exercise cards. Search input (debounced 300ms). Muscle group filter chips (All, Chest, Back, Shoulders, Arms, Legs, Glutes, Core, Cardio, Full Body, Other). Pagination footer. "Create Exercise" button in header.
- `web/src/components/exercises/exercise-card.tsx` -- Card: thumbnail image (64x48, fallback dumbbell icon on error), name (bold), muscle group badge. Click opens detail dialog. Hover: shadow lift + slight scale.
- `web/src/components/exercises/exercise-detail-dialog.tsx` -- Dialog: Large image (or placeholder), name, muscle group, description text, video URL (if YouTube: thumbnail with play overlay linking externally). "Edit Image" and "Edit Video" buttons at bottom.
- `web/src/components/exercises/create-exercise-dialog.tsx` -- Dialog form: Name (required, max 100 chars), Muscle Group dropdown (all 11 options + Other with custom input), Description (optional, textarea max 500 chars), Video URL (optional), Image URL (optional). Character counters. Create button with loading.
- `web/src/components/exercises/exercise-grid-skeleton.tsx` -- 8 skeleton cards in grid matching card dimensions.
**Hook:** Extend existing `web/src/hooks/use-exercises.ts`:
- Add `useCreateExercise()` -- `POST /api/workouts/exercises/`
- Add `useUpdateExercise(id)` -- `PATCH /api/workouts/exercises/:id/`
**Type:** Already exists in `web/src/types/program.ts` as `Exercise`. No new type file needed.
**Nav:** Add "Exercises" link to `nav-links.tsx` with `Dumbbell` icon (from lucide-react), between Programs and Invitations.
**States:**
- Loading: Grid of 8 skeleton cards
- Empty (no exercises at all): EmptyState with Dumbbell icon, "No exercises yet", "Add your first custom exercise to get started", CTA "Create Exercise"
- Empty (search/filter no results): EmptyState "No exercises match your search", "Try adjusting your search or filters"
- Error: ErrorState with retry
- Create success: Toast "Exercise '[name]' created", grid refreshes
**Edge cases:**
1. Creating exercise with duplicate name shows server error inline in dialog
2. Image URL that returns 404 shows fallback dumbbell icon gracefully
3. Filter + search combined: search within filtered muscle group
4. YouTube video URL in detail: extract video ID, show hqdefault thumbnail with play button overlay
5. "Other" muscle group selection shows custom text input for muscle group name

---

#### AC-5: Program Assignment from Trainee Detail

**Location:** Existing trainee detail page `web/src/app/(dashboard)/trainees/[id]/page.tsx`, Overview tab, Programs section
**Components:**
- `web/src/components/trainees/assign-program-action.tsx` -- "Assign Program" button visible when trainee has no active program. Opens assign dialog. If trainee already has a program, shows "Change Program" button instead.
- `web/src/components/trainees/change-program-dialog.tsx` -- Dialog: Current program display (if any), program dropdown (from `useProgramTemplates()`), start date picker (date input, defaults to today, cannot be in past), "End Current Program" destructive button (if has active program). Submit: calls `POST /api/trainer/program-templates/:id/assign/`.
**Hook:** Reuse existing `useAssignProgram()` from `use-programs.ts`. No new hook needed.
**States:**
- Dialog loading: Spinner in program dropdown while programs load
- No programs available: "No programs yet" with link "Create a program" pointing to /programs/new
- Assign success: Toast "Program assigned to [name]", trainee detail refreshes
- Error: Inline error in dialog footer
**Edge cases:**
1. Assigning to trainee who already has a program shows confirmation "This will replace the current program"
2. Start date defaults to today (local timezone)
3. Start date validation: cannot be before today
4. Empty program list: CTA to create program first
5. Program dropdown shows difficulty badge and duration for each option

---

#### AC-6: Edit Trainee Goals from Trainee Detail

**Location:** Existing trainee detail page, Overview tab, Nutrition Goals section
**Component:** `web/src/components/trainees/edit-goals-dialog.tsx` -- Dialog form: Daily Calories (number input, min 0, max 10000), Protein in grams (number, min 0, max 1000), Carbs in grams (same), Fat in grams (same), Weight Target (number with lbs/kg unit selector). Pre-populated with current values. Save/Cancel buttons.
**Hook:** `web/src/hooks/use-trainee-goals.ts`
- `useUpdateTraineeGoals(traineeId)` -- `PUT /api/trainer/trainees/:id/goals/`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
traineeGoals: (id: number) => `${API_BASE}/api/trainer/trainees/${id}/goals/`
```
**States:**
- Loading: Spinner in save button
- Success: Toast "Goals updated for [name]", section data refreshes
- Validation error: Inline errors under each field for out-of-range values
**Edge cases:**
1. Setting calories to 0 shows inline warning "Are you sure you want to set calories to 0?"
2. Macro totals (protein*4 + carbs*4 + fat*9) that differ from calorie target by >10% shows info banner "Macro totals don't match calorie target"
3. Negative values rejected at form level (min 0 on inputs)
4. Empty fields retain previous values (pre-populated, not cleared on open)
5. Non-numeric input rejected (type=number enforces)

---

#### AC-7: Remove/Deactivate Trainee from Trainee Detail

**Location:** Trainee detail page, action dropdown in page header (three-dot menu or explicit button)
**Component:** `web/src/components/trainees/remove-trainee-dialog.tsx` -- Destructive confirmation dialog: Title "Remove [First Name Last Name]?", body text "This will end their program and remove them from your trainee list. Their workout and nutrition data will be retained.", type-to-confirm input "Type '[trainee email]' to confirm", red "Remove Trainee" button (disabled until confirmation text matches).
**Hook:**
- `useRemoveTrainee()` -- `POST /api/trainer/trainees/:id/remove/`
**API Constants:** Already exists: `traineeDetail` is used, plus add:
```
traineeRemove: (id: number) => `${API_BASE}/api/trainer/trainees/${id}/remove/`
```
**States:**
- Confirm text must match exactly before remove button enables
- Remove in progress: Spinner in button, dialog cannot close
- Success: Redirect to `/trainees` with toast "Trainee removed"
- Error: Inline error in dialog (e.g., "Failed to remove trainee")
**Edge cases:**
1. Type-to-confirm is case-insensitive
2. Dialog cannot be closed (Escape, backdrop click) while remove is in progress
3. After removal, trainee no longer appears in list or search
4. Accidental close before confirming: no action taken (safe by design)

---

#### AC-8: Trainer Subscription Management Page

**Route:** `/subscription`
**Page file:** `web/src/app/(dashboard)/subscription/page.tsx`
**Components:**
- `web/src/components/subscription/subscription-overview.tsx` -- Card: Current plan tier name + price + features list. Next payment date. Trainee count vs limit (with progress bar). "Manage in Stripe" button (link to Stripe dashboard).
- `web/src/components/subscription/stripe-connect-card.tsx` -- Stripe Connect status card: Not started ("Set up Stripe to accept payments from trainees" + "Connect Stripe" button), Pending ("Complete your Stripe verification" + "Continue Setup" button), Connected ("Payments enabled" green badge + "Open Stripe Dashboard" link).
- `web/src/components/subscription/payment-history.tsx` -- DataTable: Date, Amount, Status badge, Description. Paginated.
- `web/src/components/subscription/subscriber-list.tsx` -- DataTable: Trainee Name, Plan, Status, Last Payment. Shows who is paying the trainer.
- `web/src/components/subscription/subscription-skeleton.tsx` -- Full page skeleton.
**Hook:** `web/src/hooks/use-subscription.ts`
- `useStripeConnectStatus()` -- `GET /api/payments/connect/status/`
- `useStripeConnectOnboard()` -- `POST /api/payments/connect/onboard/` (returns redirect URL)
- `useStripeConnectDashboard()` -- `GET /api/payments/connect/dashboard/` (returns dashboard link)
- `useTrainerPricing()` -- `GET /api/payments/pricing/`
- `useTrainerPayments()` -- `GET /api/payments/trainer/payments/`
- `useTrainerSubscribers()` -- `GET /api/payments/trainer/subscribers/`
**Type:** `web/src/types/subscription.ts` -- `StripeConnectStatus { has_account, charges_enabled, payouts_enabled, details_submitted }`, `TrainerPayment { id, amount, status, description, payment_date }`, `TrainerSubscriber { id, trainee_name, plan, status, last_payment_date }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
STRIPE_CONNECT_STATUS: `${API_BASE}/api/payments/connect/status/`
STRIPE_CONNECT_ONBOARD: `${API_BASE}/api/payments/connect/onboard/`
STRIPE_CONNECT_DASHBOARD: `${API_BASE}/api/payments/connect/dashboard/`
TRAINER_PRICING: `${API_BASE}/api/payments/pricing/`
TRAINER_PAYMENTS: `${API_BASE}/api/payments/trainer/payments/`
TRAINER_SUBSCRIBERS: `${API_BASE}/api/payments/trainer/subscribers/`
```
**Nav:** Add "Subscription" link to `nav-links.tsx` with `CreditCard` icon, before Settings.
**States:**
- Loading: Full page skeleton
- No Stripe Connect: Prominent CTA card "Connect Stripe to start accepting payments"
- Stripe onboarding pending: Amber warning "Complete your Stripe setup to accept payments"
- Connected: Green status, all sections visible
- No subscribers: EmptyState "No subscribers yet" in subscriber list
- No payment history: EmptyState "No payments received yet"
**Edge cases:**
1. Stripe Connect onboard button opens redirect URL in new tab (window.open)
2. Returning from Stripe (e.g., via browser tab switch) triggers refetch of connect status
3. Payment amounts formatted as currency ($X.XX)
4. Stripe dashboard link opens in new tab

---

#### AC-9: Calendar Integration Page

**Route:** `/calendar`
**Page file:** `web/src/app/(dashboard)/calendar/page.tsx`
**Components:**
- `web/src/components/calendar/calendar-connections.tsx` -- Card per provider (Google, Microsoft). Status: Connected (green) / Disconnected (grey) / Expired (amber). "Connect" / "Disconnect" / "Reconnect" buttons.
- `web/src/components/calendar/calendar-events-list.tsx` -- List of upcoming events grouped by date. Each event: title, time range, calendar source badge (Google/Microsoft icon). Infinite scroll or pagination.
- `web/src/components/calendar/calendar-skeleton.tsx` -- Skeleton for connections + events.
**Hook:** `web/src/hooks/use-calendar.ts`
- `useCalendarConnections()` -- `GET /api/calendar/connections/`
- `useGoogleCalendarAuth()` -- `GET /api/calendar/google/auth/` (returns OAuth redirect URL)
- `useCalendarEvents()` -- `GET /api/calendar/events/`
- `useDisconnectCalendar(connectionId)` -- `DELETE /api/calendar/connections/:id/`
**Type:** `web/src/types/calendar.ts` -- `CalendarConnection { id, provider, status, email, created_at }`, `CalendarEvent { id, title, start_time, end_time, calendar_provider }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
CALENDAR_CONNECTIONS: `${API_BASE}/api/calendar/connections/`
GOOGLE_CALENDAR_AUTH: `${API_BASE}/api/calendar/google/auth/`
CALENDAR_EVENTS: `${API_BASE}/api/calendar/events/`
```
**Nav:** Add "Calendar" link to `nav-links.tsx` with `CalendarDays` icon (from lucide-react), between Notifications and Settings.
**States:**
- No connections: EmptyState "Connect your calendar to see upcoming events", CTA buttons "Connect Google" and "Connect Microsoft"
- Loading: Skeleton cards
- Connected with events: Event list grouped by date
- Connected with no events: "No upcoming events this week"
- Error: ErrorState with retry
**Edge cases:**
1. OAuth opens in popup window (window.open centered). Polls for completion.
2. If popup blocked: fallback to same-tab redirect with return URL
3. Expired OAuth token: Show "Reconnect" button (amber status)
4. Disconnect: Confirmation dialog "Disconnect [provider] calendar?"
5. Events show in user's local timezone

---

#### AC-10: Trainee Detail -- Edit Layout Config

**Location:** Existing trainee detail page, Overview tab, new "Workout Display" section
**Component:** `web/src/components/trainees/layout-config-selector.tsx` -- Card section with 3 option cards in a row (radio group pattern): Classic (list icon, "Scrollable exercise list"), Card (cards icon, "One exercise at a time"), Minimal (compress icon, "Compact collapsible list"). Selected option has primary border + checkmark. Click triggers immediate save.
**Hook:**
- `useTraineeLayoutConfig(traineeId)` -- `GET /api/trainer/trainees/:trainee_id/layout-config/`
- `useUpdateLayoutConfig(traineeId)` -- `PUT /api/trainer/trainees/:trainee_id/layout-config/`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
traineeLayoutConfig: (traineeId: number) => `${API_BASE}/api/trainer/trainees/${traineeId}/layout-config/`
```
**States:**
- Loading: 3 skeleton option cards
- Success: Toast "Layout updated to [type]" with optimistic UI
- Error: Revert selection with toast error
**Edge cases:**
1. Default is "classic" for all trainees (API returns default if not set)
2. Change is optimistic with rollback on error
3. Layout descriptions help trainer understand what each looks like
4. ARIA: radio group with role="radiogroup", each option role="radio"

---

#### AC-11: Trainee Detail -- Impersonation

**Location:** Trainee detail page header, actions dropdown menu
**Component:** `web/src/components/trainees/impersonate-trainee-button.tsx` -- Menu item "Login as [First Name]" with Eye icon. Opens confirmation dialog: "You will see the app as [full name] sees it. Your session will be restored when you end impersonation."
**Implementation:**
- `POST /api/trainer/impersonate/:trainee_id/start/` returns JWT tokens for the trainee session
- Store current trainer tokens in sessionStorage key `impersonation_original_tokens`
- Set trainee tokens as active tokens
- Show impersonation banner (reuse `ImpersonationBanner` component pattern from admin)
- "End Session" in banner calls `POST /api/trainer/impersonate/end/`, restores trainer tokens, redirects back to trainee detail
**API Constants:** Add to `web/src/lib/constants.ts`:
```
trainerImpersonateStart: (traineeId: number) => `${API_BASE}/api/trainer/impersonate/${traineeId}/start/`
TRAINER_IMPERSONATE_END: `${API_BASE}/api/trainer/impersonate/end/`
```
**States:**
- During impersonation: Yellow banner at top of page "Viewing as [trainee name] -- [End Session]"
- End: Restore tokens, redirect, toast "Returned to your account"
**Edge cases:**
1. Browser refresh during impersonation: Check sessionStorage for original tokens, maintain banner
2. Logout during impersonation: Clear both token sets
3. Multiple impersonation without ending: Prevent (check if already impersonating)
4. Banner visible on all pages during impersonation

---

#### AC-12: Mark Missed Day

**Location:** Trainee detail page, Programs section or Activity tab
**Component:** `web/src/components/trainees/mark-missed-day-dialog.tsx` -- Dialog: Date picker for missed day, Action radio group: "Skip" (mark as rest day, no schedule change) / "Push" (shift remaining days forward by one), explanation text for each option, confirm button.
**Hook:**
- `useMarkMissedDay()` -- `POST /api/trainer/programs/:program_id/mark-missed/` with `{ date, action }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
programMarkMissed: (programId: number) => `${API_BASE}/api/trainer/programs/${programId}/mark-missed/`
```
**States:**
- Success: Toast "Day marked as [skipped/pushed]"
- Error: Inline error in dialog
**Edge cases:**
1. Cannot mark future dates as missed (date picker max = today)
2. Cannot mark a day that already has logged workout data (API validates)
3. Push action shows info text: "This will shift all remaining program days forward by one day"
4. Requires selecting which program (if trainee has multiple -- use dropdown)

---

#### AC-13: Feature Requests Page

**Route:** `/feature-requests`
**Page file:** `web/src/app/(dashboard)/feature-requests/page.tsx`
**Components:**
- `web/src/components/feature-requests/feature-request-list.tsx` -- List of cards (not DataTable -- more visual). Each card: Vote button (chevron-up + count, toggle), Title (bold), Description preview (2 lines, truncated), Status badge (Open/Planned/In Progress/Done/Closed), Comment count, Author, Date. Sort options: Most Voted, Newest, Status.
- `web/src/components/feature-requests/feature-request-detail-dialog.tsx` -- Full dialog: Title, Description (full, markdown rendered), Status badge, Vote button, Comments thread below.
- `web/src/components/feature-requests/create-feature-request-dialog.tsx` -- Dialog form: Title (required, max 200 chars), Description (textarea, max 2000 chars, markdown supported).
- `web/src/components/feature-requests/feature-comment-thread.tsx` -- Comment list with author avatar/initials, name, date, content. "Add comment" input at bottom.
- `web/src/components/feature-requests/feature-list-skeleton.tsx` -- Shimmer skeleton for card list.
**Hook:** `web/src/hooks/use-feature-requests.ts`
- `useFeatureRequests(sort?, status?)` -- `GET /api/features/` with pagination, sort, status filter
- `useFeatureRequest(id)` -- `GET /api/features/:id/`
- `useCreateFeatureRequest()` -- `POST /api/features/`
- `useVoteFeatureRequest(id)` -- `POST /api/features/:id/vote/` (toggle)
- `useFeatureComments(id)` -- `GET /api/features/:id/comments/`
- `useCreateFeatureComment(id)` -- `POST /api/features/:id/comments/`
**Type:** `web/src/types/feature-request.ts` -- `FeatureRequest { id, title, description, status, vote_count, has_voted, comment_count, author_name, created_at }`, `FeatureComment { id, author_name, content, created_at }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
FEATURE_REQUESTS: `${API_BASE}/api/features/`
featureRequestDetail: (id: number) => `${API_BASE}/api/features/${id}/`
featureRequestVote: (id: number) => `${API_BASE}/api/features/${id}/vote/`
featureRequestComments: (id: number) => `${API_BASE}/api/features/${id}/comments/`
```
**Nav:** Add "Feature Requests" link to `nav-links.tsx` with `Lightbulb` icon, before Settings.
**States:**
- AC-14: Loading: Skeleton card list
- AC-15: Empty: EmptyState "No feature requests yet", CTA "Submit a Request"
- AC-16: Vote toggle: Optimistic update with rollback on error. Filled chevron = voted, outline = not voted.
**Edge cases:**
1. Vote is idempotent toggle (vote/unvote)
2. Long descriptions truncate in list card, show full in detail
3. Status filter chips: All, Open, Planned, In Progress, Done
4. Sort persists in URL query params
5. Comments load paginated (page size 20)

---

### Admin Features (AC-17 through AC-26)

---

#### AC-17: Admin Ambassador Management Page

**Route:** `/admin/ambassadors`
**Page file:** `web/src/app/(admin-dashboard)/admin/ambassadors/page.tsx`
**Components:**
- `web/src/components/admin/ambassador-list.tsx` -- DataTable: Name, Email, Referral Code, Commission Rate (%), Total Earnings ($), Active Referrals, Status badge (Active green / Suspended red). Search by name/email. Filter by status (All/Active/Suspended). Row click opens detail dialog. Pagination.
- `web/src/components/admin/ambassador-detail-dialog.tsx` -- Dialog with 3 tabs:
  - Overview: Profile info card (name, email, referral code, commission rate with inline edit, total/pending earnings, Stripe Connect status badge). Active/Suspend toggle switch.
  - Referrals: DataTable of referrals (Trainer Name, Email, Status, Tier, Commission, Referred Date). Status filter.
  - Commissions: DataTable (Month, Trainer, Amount, Status with approve/pay action buttons). Bulk action bar: "Approve All Pending", "Pay All Approved".
- `web/src/components/admin/create-ambassador-dialog.tsx` -- Form: Email (required), First Name (required), Last Name (required), Password (required, min 8, not all numeric), Commission Rate % (0-100, default 20). Create button with loading.
- `web/src/components/admin/ambassador-commissions.tsx` -- Commission management sub-component used in detail dialog. Includes individual approve/pay buttons and bulk actions.
**Hook:** `web/src/hooks/use-admin-ambassadors.ts`
- `useAdminAmbassadors(search?, status?)` -- `GET /api/admin/ambassadors/` with pagination
- `useAdminAmbassadorDetail(id)` -- `GET /api/admin/ambassadors/:id/`
- `useCreateAmbassador()` -- `POST /api/admin/ambassadors/create/`
- `useUpdateAmbassador(id)` -- `PUT /api/admin/ambassadors/:id/`
- `useApproveCommission(ambassadorId, commissionId)` -- `POST /api/admin/ambassadors/:id/commissions/:cid/approve/`
- `usePayCommission(ambassadorId, commissionId)` -- `POST /api/admin/ambassadors/:id/commissions/:cid/pay/`
- `useBulkApprove(ambassadorId)` -- `POST /api/admin/ambassadors/:id/commissions/bulk-approve/`
- `useBulkPay(ambassadorId)` -- `POST /api/admin/ambassadors/:id/commissions/bulk-pay/`
- `useTriggerPayout(ambassadorId)` -- `POST /api/admin/ambassadors/:id/payout/`
**Type:** `web/src/types/ambassador.ts` -- `Ambassador { id, user: { id, email, first_name, last_name, is_active }, referral_code, commission_rate, total_earnings, pending_earnings, total_referrals, active_referrals, is_active, stripe_connect_status }`, `AmbassadorReferral { id, trainer: { name, email }, status, tier, commission_earned, referred_at }`, `AmbassadorCommission { id, month, trainer_name, amount, status, rate_snapshot }`, `CreateAmbassadorPayload { email, first_name, last_name, password, commission_rate }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
ADMIN_AMBASSADORS: `${API_BASE}/api/admin/ambassadors/`
ADMIN_AMBASSADOR_CREATE: `${API_BASE}/api/admin/ambassadors/create/`
adminAmbassadorDetail: (id: number) => `${API_BASE}/api/admin/ambassadors/${id}/`
adminCommissionApprove: (ambassadorId: number, commissionId: number) => `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/${commissionId}/approve/`
adminCommissionPay: (ambassadorId: number, commissionId: number) => `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/${commissionId}/pay/`
adminBulkApprove: (ambassadorId: number) => `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/bulk-approve/`
adminBulkPay: (ambassadorId: number) => `${API_BASE}/api/admin/ambassadors/${ambassadorId}/commissions/bulk-pay/`
adminTriggerPayout: (ambassadorId: number) => `${API_BASE}/api/admin/ambassadors/${ambassadorId}/payout/`
```
**Nav:** Add "Ambassadors" link to `web/src/components/layout/admin-nav-links.ts` with `Handshake` icon, after Users (before Settings).
**States:**
- Loading: Skeleton table
- Empty: EmptyState "No ambassadors yet", CTA "Create Ambassador"
- Create success: Toast "Ambassador created", table refreshes
- Detail loading: Skeleton in dialog tabs
- Approve success: Commission status updates to "Approved" badge
- Pay success: Confirmation dialog with amount, then "Paid" badge
- Bulk: Progress indicator, toast "X commissions approved/paid"
**Edge cases:**
1. Creating ambassador with existing email shows server error in dialog
2. Commission rate validates 0-100 range with step 0.01
3. Suspending ambassador with active referrals shows warning "This ambassador has N active referrals"
4. Password validation: min 8 chars, not entirely numeric (match Django)
5. Referral code is read-only in admin view
6. Cannot pay before approve (button disabled)
7. Bulk approve/pay caps at 200 per request (API limit)
8. Pay requires Stripe Connect onboarding complete (show warning if not)
9. Trigger Payout button: only visible when ambassador has connected Stripe + has approved commissions

---

#### AC-18: Admin Upcoming Payments Page

**Route:** `/admin/upcoming-payments`
**Page file:** `web/src/app/(admin-dashboard)/admin/upcoming-payments/page.tsx`
**Components:**
- `web/src/components/admin/upcoming-payments-list.tsx` -- Summary cards at top: "Due Today" (count + amount), "Due This Week" (count + amount), "Due This Month" (count + amount). DataTable below: Trainer Name, Email, Tier, Amount ($), Due Date, Days Until Payment. Row color-coding: green (8+ days), amber (1-7 days), red (today/overdue). Pagination.
**Hook:** Use existing admin dashboard hooks. Add if needed:
- `useUpcomingPayments()` -- `GET /api/admin/upcoming-payments/`
**Nav:** Add to admin sidebar: "Upcoming Payments" with `CalendarClock` icon, after Subscriptions. Alternatively, accessible from dashboard "Payments Due" card via "View All" link.
**States:**
- Loading: Skeleton summary cards + table
- Empty: "No upcoming payments" success state
- Error: ErrorState with retry
**Edge cases:**
1. Clicking trainer name links to trainer detail (or subscription detail)
2. Currency formatting consistent ($X,XXX.XX)
3. Date relative display ("Today", "Tomorrow", "In 5 days")

---

#### AC-19: Admin Past Due Alerts Page

**Route:** `/admin/past-due`
**Page file:** `web/src/app/(admin-dashboard)/admin/past-due/page.tsx`
**Components:**
- `web/src/components/admin/past-due-full-list.tsx` -- DataTable: Trainer Name, Email, Past Due Amount ($), Days Past Due, Failed Payment Count, Last Payment Date, Actions (View Subscription). Severity color on Days Past Due column: amber (1-7 days), red (8-30), dark red (30+). Sort by days past due descending. Pagination.
**Hook:**
- `usePastDueAlerts()` -- `GET /api/admin/past-due/` with pagination
**Nav:** Accessible from admin dashboard "Past Due" section via "View All" link. Also add "Past Due" to admin nav with `AlertTriangle` icon, after Upcoming Payments.
**States:**
- Loading: Skeleton table
- Empty: Success EmptyState with green CheckCircle icon "No past due subscriptions" with celebrate copy "All trainers are current on payments"
- Error: ErrorState with retry
**Edge cases:**
1. Click-through "View Subscription" opens subscription detail dialog
2. Past due amount formatted as currency
3. 0 past due renders the success empty state (good news)

---

#### AC-20: Admin Settings Page (Replace Placeholder)

**Route:** `/admin/settings` (replace existing "Coming soon" EmptyState)
**Components:**
- `web/src/components/admin/admin-settings-platform.tsx` -- Card: Platform Name (editable, saved to backend if API exists, otherwise display "FitnessAI" as read-only), Support Email (editable), Default Ambassador Commission Rate % (editable, 0-100, info text "Applied to newly created ambassadors only").
- `web/src/components/admin/admin-settings-security.tsx` -- Card: Read-only display fields showing current configuration: JWT Access Token Lifetime, JWT Refresh Token Lifetime, Rate Limits (anon/user), CORS Origins. Each with helper text "Configured via environment variable [VAR_NAME]". Info banner: "These settings are managed via environment variables. Restart the server after changes."
- `web/src/components/admin/admin-settings-notifications.tsx` -- Card: Notification preferences toggles: "Email on new trainer signup", "Email on past due alert", "Email on ambassador payout". Toggle switches with optimistic update.
**States:**
- Loading: Skeleton sections (3 cards)
- Save success: Toast "Settings updated"
- Read-only fields: Input with disabled state, grey background, "Env var: [NAME]" helper
**Edge cases:**
1. Invalid email format shows inline validation
2. Commission rate validates 0-100
3. Read-only security section is informational (no save needed)
4. If backend does not have admin settings API, display sensible defaults and note "Settings management API coming soon" for editable sections

---

### Ambassador Features (AC-21 through AC-28)

---

#### AC-21: Ambassador Auth & Routing Infrastructure

**Files to modify:**
- `web/src/middleware.ts` -- Add AMBASSADOR role routing:
  - Authenticated AMBASSADOR visiting `/` redirects to `/ambassador/dashboard`
  - Non-AMBASSADOR visiting `/ambassador/*` redirects to their own role's dashboard
  - Add `/ambassador/*` to protected routes
- `web/src/providers/auth-provider.tsx` -- Accept AMBASSADOR role (currently rejects non-TRAINER/ADMIN). Change role check to accept TRAINER, ADMIN, or AMBASSADOR.
- `web/src/lib/token-manager.ts` -- Ensure `setRoleCookie` handles "AMBASSADOR" value

**Files to create:**
- `web/src/app/(ambassador-dashboard)/layout.tsx` -- New route group layout with ambassador sidebar, header, loading guard (same pattern as trainer/admin layouts). Redirects non-AMBASSADOR users.
- `web/src/components/layout/ambassador-nav-links.ts` -- Nav links array: Dashboard (LayoutDashboard), Referrals (Users), Payouts (Wallet), Settings (Settings).
- `web/src/components/layout/ambassador-sidebar.tsx` -- Desktop sidebar (256px fixed) with ambassador nav, user info at bottom. Primary color accent different from trainer (e.g., emerald/teal).
- `web/src/components/layout/ambassador-sidebar-mobile.tsx` -- Mobile sheet drawer version.
**Edge cases:**
1. AMBASSADOR cannot access /dashboard or /admin/*
2. TRAINER cannot access /ambassador/*
3. ADMIN cannot access /ambassador/* (admins manage ambassadors from admin dashboard)
4. Login correctly routes each role to their dashboard
5. Role cookie "AMBASSADOR" handled by middleware

---

#### AC-22: Ambassador Dashboard Page

**Route:** `/ambassador/dashboard`
**Page file:** `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx`
**Components:**
- `web/src/components/ambassador/dashboard-earnings-card.tsx` -- Gradient card (emerald/teal gradient): "Total Earnings" label + large $ amount. Below: "Pending" amount + "Commission Rate" percentage. Dark mode: darker gradient.
- `web/src/components/ambassador/referral-code-card.tsx` -- Card: "Your Referral Code" heading, code in large monospace font with letter-spacing, "Copy" button (clipboard API, toast "Code copied!"), "Share" button (Web Share API with fallback to clipboard copy, toast "Share message copied!").
- `web/src/components/ambassador/monthly-earnings-chart.tsx` -- recharts BarChart: last 6 months of earnings. X-axis: month abbreviations. Y-axis: dollar amounts. Theme-aware fill color (emerald in light, lighter emerald in dark). Tooltip showing exact amount. Empty state: "No earnings data yet" centered text.
- `web/src/components/ambassador/referral-stats-row.tsx` -- 4 stat cards: Total (blue), Active (green), Pending (amber), Churned (red). Each shows count with colored number.
- `web/src/components/ambassador/recent-referrals-list.tsx` -- Card: "Recent Referrals" heading. Last 5 referrals: Avatar circle with initials, trainer name, email, status badge (color-coded). Empty: "No referrals yet. Share your code!" with link to referral code section.
- `web/src/components/ambassador/ambassador-dashboard-skeleton.tsx` -- Full page skeleton matching all above sections.
**Hook:** `web/src/hooks/use-ambassador.ts`
- `useAmbassadorDashboard()` -- `GET /api/ambassador/dashboard/`
- `useAmbassadorReferralCode()` -- `GET /api/ambassador/referral-code/`
**Type:** `web/src/types/ambassador.ts` (add ambassador-facing types alongside admin types):
```typescript
interface AmbassadorDashboardData {
  total_earnings: string;
  pending_earnings: string;
  commission_rate: number;
  referral_code: string;
  is_active: boolean;
  total_referrals: number;
  active_referrals: number;
  pending_referrals: number;
  churned_referrals: number;
  monthly_earnings: { month: string; amount: string }[];
  recent_referrals: { trainer: { first_name: string; last_name: string; email: string }; status: string; referred_at: string }[];
}
```
**API Constants:** Add to `web/src/lib/constants.ts`:
```
AMBASSADOR_DASHBOARD: `${API_BASE}/api/ambassador/dashboard/`
AMBASSADOR_REFERRAL_CODE: `${API_BASE}/api/ambassador/referral-code/`
AMBASSADOR_REFERRALS: `${API_BASE}/api/ambassador/referrals/`
AMBASSADOR_PAYOUTS: `${API_BASE}/api/ambassador/payouts/`
AMBASSADOR_CONNECT_STATUS: `${API_BASE}/api/ambassador/connect/status/`
AMBASSADOR_CONNECT_ONBOARD: `${API_BASE}/api/ambassador/connect/onboard/`
AMBASSADOR_CONNECT_RETURN: `${API_BASE}/api/ambassador/connect/return/`
```
**States:**
- Loading: Full dashboard skeleton
- Error: ErrorState with retry button
- Suspended account: Amber warning banner at top: "Your account is currently suspended. Contact admin for assistance."
- Empty (no referrals): Welcome message in recent referrals section with share CTA
**Edge cases:**
1. Suspended ambassador sees all data but with warning banner
2. Monthly chart handles months with $0 (shows 0-height bar)
3. Copy uses navigator.clipboard.writeText with fallback
4. Web Share API unavailable (most desktops): Show only copy button
5. Currency formatting uses formatCurrency from existing format-utils.ts
6. Very long referral code fits via CSS overflow-wrap

---

#### AC-23: Ambassador Referrals Page

**Route:** `/ambassador/referrals`
**Page file:** `web/src/app/(ambassador-dashboard)/ambassador/referrals/page.tsx`
**Components:**
- `web/src/components/ambassador/referral-list.tsx` -- Status filter chips at top (All, Active, Pending, Churned). DataTable: Trainer Name, Email, Status badge (green Active, amber Pending, red Churned), Subscription Tier, Commission Earned ($), Referred Date (formatted MMM d, yyyy). Pagination (page size 20). Search by trainer name/email.
- `web/src/components/ambassador/referral-list-skeleton.tsx` -- Skeleton table matching column layout.
**Hook:** Add to `use-ambassador.ts`:
- `useAmbassadorReferrals(status?, page?)` -- `GET /api/ambassador/referrals/` with query params
**States:**
- Loading: Skeleton table
- Empty (no referrals at all): EmptyState "No referrals yet", "Share your referral code to get started", CTA "Go to Dashboard" linking to /ambassador/dashboard
- Empty (filtered): EmptyState "No [status] referrals", "Try a different filter"
- Error: ErrorState with retry
**Edge cases:**
1. Changing status filter resets to page 1
2. Date formatting consistent across all views
3. Currency amounts right-aligned in column
4. Clicking "Go to Dashboard" navigates correctly

---

#### AC-24: Ambassador Payouts Page

**Route:** `/ambassador/payouts`
**Page file:** `web/src/app/(ambassador-dashboard)/ambassador/payouts/page.tsx`
**Components:**
- `web/src/components/ambassador/stripe-connect-setup.tsx` -- Top card: If no Stripe Connect account or not completed: Bank icon + "Set up your bank account to receive payouts" + "Connect with Stripe" primary button. If connected: Green check + "Bank account connected" + "Connected" badge. If pending: Amber warning + "Complete your verification" + "Continue Setup" button.
- `web/src/components/ambassador/payout-history.tsx` -- Summary row: Total Paid ($), Pending ($). DataTable below: Amount ($), Date (formatted), Status badge (green Completed, amber Pending, red Failed), Stripe Transfer ID (truncated monospace, copy on click). Pagination.
- `web/src/components/ambassador/payout-skeleton.tsx` -- Skeleton for Stripe card + table.
**Hook:** Add to `use-ambassador.ts`:
- `useAmbassadorPayouts(page?)` -- `GET /api/ambassador/payouts/`
- `useAmbassadorConnectStatus()` -- `GET /api/ambassador/connect/status/`
- `useAmbassadorConnectOnboard()` -- `POST /api/ambassador/connect/onboard/`
**States:**
- No Stripe: Large CTA card for Stripe Connect onboarding
- Stripe pending verification: Amber warning with "Continue Setup" button
- Stripe connected, no payouts: EmptyState "No payouts yet", "Payouts appear here once triggered by admin"
- Stripe connected with payouts: Summary + table
- Loading: Skeleton
- Error: ErrorState with retry
**Edge cases:**
1. Stripe onboarding button opens onboarding URL in new tab (window.open)
2. Returning from Stripe triggers status refetch via page visibility change listener
3. Failed payout shows error reason in expandable row or tooltip
4. Transfer ID copy: toast "Transfer ID copied"

---

#### AC-25: Ambassador Settings Page

**Route:** `/ambassador/settings`
**Page file:** `web/src/app/(ambassador-dashboard)/ambassador/settings/page.tsx`
**Components:**
- `web/src/components/ambassador/ambassador-profile-section.tsx` -- Card: Read-only: Name (First Last), Email, Commission Rate (%). Editable: Custom Referral Code input (4-20 chars, alphanumeric only, with save button). Validation: regex `^[a-zA-Z0-9]{4,20}$`, inline error "Code must be 4-20 alphanumeric characters" or "This code is already taken" from server.
- Reuse `web/src/components/settings/appearance-section.tsx` for theme toggle.
- Reuse `web/src/components/settings/security-section.tsx` for password change.
**Hook:** Add to `use-ambassador.ts`:
- `useUpdateReferralCode()` -- `PUT /api/ambassador/referral-code/` with `{ referral_code }`
**States:**
- Code save: Toast "Referral code updated to [CODE]"
- Code taken: Inline error "This code is not available. Try another."
- Code invalid format: Inline error "Code must be 4-20 alphanumeric characters"
- Password change: Same flow as trainer (Djoser set_password)
**Edge cases:**
1. Referral code uppercased on display, case-insensitive on save
2. Cannot change email (display only)
3. Cannot change commission rate (display only, set by admin)
4. Theme persists via same next-themes mechanism

---

### Community Features (AC-26 through AC-28)

---

#### AC-26: Trainer Announcements (Trainee-Facing Management)

Covered by AC-1 above. The trainer announcements page IS the web management interface for the announcements that trainees see on mobile. No separate community page needed on web.

---

#### AC-27: Community Feed Moderation (via Trainee Detail)

**Location:** Trainee detail page `web/src/app/(dashboard)/trainees/[id]/page.tsx` -- Add "Community" as a 4th tab alongside Overview, Activity, Progress.
**Component:** `web/src/components/trainees/trainee-community-tab.tsx` -- List of community posts by this trainee. Each post card: Content text (truncated to 3 lines, expand on click), Image thumbnail (if present, click to view full), Reaction counts (fire/thumbs/heart icons with counts), Comment count, Created date. "Delete Post" button (red, with confirmation dialog: "Delete this post? All comments will also be deleted. This cannot be undone.").
**Hook:** This can use a filtered version of the community feed API. If the API supports filtering by user:
- Community feed endpoint may need `?user_id=X` filter, or this can be shown from the trainee detail's activity data.
- Alternatively, show posts from existing trainee activity data.
**States:**
- Loading: Skeleton post cards (3 items)
- Empty: "This trainee hasn't posted in the community yet"
- Delete success: Toast "Post deleted", list refreshes
**Edge cases:**
1. Post with image shows thumbnail (120px height, rounded)
2. Trainer cannot create posts for trainee from web
3. Delete cascades comments on server (no additional action needed)

---

#### AC-28: Leaderboard Settings

**Location:** Existing settings page `/settings` -- Add "Leaderboard" section after Branding.
**Component:** `web/src/components/settings/leaderboard-section.tsx` -- Card: "Leaderboard Settings" heading. 4 toggle switches in a 2x2 grid:
- Weekly Workout Count (toggle)
- Monthly Workout Count (toggle)
- Weekly Streak (toggle)
- Monthly Streak (toggle)
Each toggle: label, description, switch. Changes save immediately (optimistic).
**Hook:**
- `useLeaderboardSettings()` -- `GET /api/trainer/leaderboard-settings/`
- `useUpdateLeaderboardSetting()` -- `PUT /api/trainer/leaderboard-settings/` with `{ metric_type, time_period, is_enabled }`
**API Constants:** Add to `web/src/lib/constants.ts`:
```
LEADERBOARD_SETTINGS: `${API_BASE}/api/trainer/leaderboard-settings/`
```
**States:**
- Loading: 4 skeleton toggle rows
- Toggle success: Immediate visual feedback (optimistic)
- Toggle error: Revert switch, toast error
**Edge cases:**
1. Disabling a leaderboard that trainees are currently viewing: they see "Leaderboard disabled by trainer" on next load
2. All 4 disabled: All switches off, no warning needed
3. First visit auto-creates all 4 settings with defaults (API handles)

---

## Workstream 2: UI/UX Polish

### AC-29: Login Page Redesign

**Files to modify:** `web/src/app/(auth)/login/page.tsx`, `web/src/app/(auth)/layout.tsx`
**New dependency:** `framer-motion` (add `"framer-motion": "^12.0.0"` to package.json dependencies)

**Design vision:** Inspired by Peloton, Nike Training Club, and Strava login pages. Two-column layout on desktop (left = animated hero, right = form). Single column on mobile (form only with gradient background).

**Left panel (hero) -- `web/src/components/auth/login-hero.tsx`:**
- Animated gradient background cycling through fitness brand colors (deep indigo to electric blue to energetic purple). CSS `@keyframes gradient-shift` with 15s duration, infinite.
- Floating fitness icons (lucide: Dumbbell, Heart, Activity, Flame, Trophy, Zap) each positioned absolutely, floating with CSS keyframes at different speeds (3-6s, ease-in-out, infinite alternate). 6 icons at 10-15% opacity, different sizes (32-64px).
- Large tagline: "Train Smarter. Grow Faster." -- framer-motion stagger: each word fades+slides up (delay 0.1s per word).
- Subtle dot grid pattern overlay at 3% opacity for depth (CSS background-image: radial-gradient).
- Feature pills: "AI-Powered", "White-Label Ready", "500+ Trainers" -- small rounded badges at bottom, fade-in sequentially.

**Right panel (form):**
- Same login form fields and logic but with animations:
  - Card: `motion.div` with `initial={{ opacity: 0, y: 20 }}` `animate={{ opacity: 1, y: 0 }}` `transition={{ duration: 0.4, delay: 0.2 }}`
  - Logo: Subtle scale bounce animation on mount.
  - Inputs: Focus ring with smooth `transition-shadow` (already in Tailwind, enhance timing).
  - Submit button: `hover:scale-[1.02] hover:shadow-lg active:scale-[0.98]` with `transition-all duration-150`.
  - Error alert: `motion.div` with slide-down entrance.
  - Loading state: Pulse ring animation around spinner.

**Responsive:**
- `lg:` and above: Two-column `grid grid-cols-2` layout. Hero left, form right.
- `md:` Hero collapses to short (200px) gradient banner at top.
- Below `md:` Hero hidden completely. Form full screen. Gradient background applied to entire page.

**Dark mode:**
- Gradient shifts to darker, muted tones (slate-900 to indigo-950).
- Floating icons at 5% opacity (dimmer).
- Form card: `bg-card` with subtle `border` glow.

**Auth layout update (`web/src/app/(auth)/layout.tsx`):**
- Change from centered card to full-screen layout with grid.

**Edge cases:**
1. `prefers-reduced-motion` media query: All CSS animations set to `animation: none`, framer-motion `transition={{ duration: 0 }}`. Static layout, no floating icons.
2. Hero panel: `aria-hidden="true"` (purely decorative).
3. Form functional without animations loading (progressive enhancement).
4. No external image/font downloads for hero (CSS-only, inline SVG icons from lucide).
5. Webkit autofill styling: override `input:-webkit-autofill` to match design.
6. Tab order: Form inputs focusable, hero not focusable.

---

#### AC-30: Page Transitions with Framer Motion

**File to create:** `web/src/components/shared/page-transition.tsx`
```tsx
"use client";
import { motion } from "framer-motion";
import type { ReactNode } from "react";

const reducedMotionQuery = "(prefers-reduced-motion: reduce)";

export function PageTransition({ children }: { children: ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}
```
**Apply to:** Wrap the main content of every page in `(dashboard)`, `(admin-dashboard)`, and `(ambassador-dashboard)` route groups. Each page.tsx wraps its return JSX in `<PageTransition>`.
**Edge cases:**
1. Respects `prefers-reduced-motion` via framer-motion's built-in support
2. No exit animations (Next.js App Router unmounts instantly)
3. Does not cause layout shift (motion.div has no explicit dimensions)
4. First render: Animation plays. Subsequent (cached): Instant.

---

#### AC-31: Skeleton Loading for All Data Views

**Ensure every page has a skeleton loader. Create new skeletons for:**
- `web/src/components/announcements/announcement-list-skeleton.tsx` -- 5 table rows shimmer
- `web/src/components/ai-chat/chat-skeleton.tsx` -- Empty state skeleton (icon + 3 text lines)
- `web/src/components/exercises/exercise-grid-skeleton.tsx` -- 8 card grid shimmer
- `web/src/components/ambassador/ambassador-dashboard-skeleton.tsx` -- Earnings card + code card + chart + stats row + list
- `web/src/components/ambassador/referral-list-skeleton.tsx` -- Filter chips + 5 table rows
- `web/src/components/ambassador/payout-skeleton.tsx` -- Stripe card + 3 table rows
- `web/src/components/feature-requests/feature-list-skeleton.tsx` -- 4 card list shimmer
- `web/src/components/subscription/subscription-skeleton.tsx` -- 3 cards shimmer
- `web/src/components/calendar/calendar-skeleton.tsx` -- 2 connection cards + 3 event items

**Pattern:** Every skeleton uses `<Skeleton />` from shadcn with `animate-pulse`. Heights match real content. No bare `<Loader2>` spinner on any page (audit existing pages too).
**Rule:** Every `isLoading` state must render a content-shaped skeleton. Replace any existing `<Loader2>` full-page spinners in `(dashboard)/layout.tsx` and `(admin-dashboard)/layout.tsx` with proper skeletons.
**Edge cases:**
1. Skeleton heights match real content heights (no layout shift on data load)
2. Dark mode: skeleton bg uses `bg-muted` which adapts automatically

---

#### AC-32: Micro-Interactions

**Button effects (apply globally via `web/src/components/ui/button.tsx` variants):**
- Primary buttons: Add `transition-all duration-150 hover:shadow-md hover:scale-[1.02] active:scale-[0.98]`
- Destructive buttons: Same but hover glow in destructive color `hover:shadow-destructive/25`
- Ghost/outline: `transition-colors duration-150`
- All: Ensure `focus-visible:ring-2 focus-visible:ring-ring` transition is smooth

**Card hover effects (apply to stat cards, exercise cards, referral cards):**
- `hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200`
- Apply via utility class `.card-hover` or directly on Card components

**Table row effects:**
- `hover:bg-accent/50 transition-colors duration-100` (already partially present, audit consistency)

**Input focus:**
- `transition-shadow duration-150` on focus ring (audit `web/src/components/ui/input.tsx`)

**Tooltip/popover entrance:**
- Already handled by Radix primitives. Ensure `data-[state=open]:animate-in` classes present.

**Implementation:** Modify shared UI components (`button.tsx`, `card.tsx`, `input.tsx`) to include transition classes. Add `.card-hover` utility to `globals.css` if needed.
**Edge cases:**
1. `prefers-reduced-motion`: Wrap hover transforms in `@media (hover: hover) and (prefers-reduced-motion: no-preference)`
2. Touch devices: hover effects don't trigger on tap (use `@media (hover: hover)`)
3. Active state is instant (no perceptible delay)

---

#### AC-33: Dashboard UX Improvements

**Specific changes to existing dashboard (`web/src/app/(dashboard)/dashboard/page.tsx` and components):**

1. **Stat cards trend indicators:** Modify `web/src/components/dashboard/stat-card.tsx` to accept optional `trend` prop: `{ direction: 'up' | 'down' | 'flat', percentage: number, label: string }`. Render: TrendingUp/TrendingDown/Minus icon + "+12%" text. Colors: green (up if positive metric), red (down), grey (flat). Data source: Compare current period to previous period from dashboard stats API.

2. **Recent trainees table:** Add avatar column (Avatar with initials fallback) to `web/src/components/dashboard/recent-trainees.tsx`. Add "last active" column with relative time ("2 hours ago", "5 days ago") using date-fns `formatDistanceToNow`.

3. **Inactive trainees alert:** In `web/src/components/dashboard/inactive-trainees.tsx`, add inactivity duration badge: amber for 3-7 days, red for 7+ days. Show "Inactive for X days" text.

4. **New trainer onboarding checklist:** Create `web/src/components/dashboard/onboarding-checklist.tsx`. Show ONLY when trainer has 0 trainees AND 0 programs. Checklist:
   - [ ] Create your first program -> /programs/new
   - [ ] Invite your first trainee -> /invitations (with create dialog auto-open)
   - [ ] Set up Stripe payments -> /subscription
   - [ ] Customize your branding -> /settings#branding
   Progress bar at top (N/4 complete). Dismiss with "I'll do this later" link (saved to localStorage).

5. **Typography audit:** Verify all pages use: `text-2xl font-bold` for page titles (h1), `text-lg font-semibold` for section headers, `text-sm` for body. Fix any deviations.

6. **Spacing audit:** All card padding: 24px (`p-6`). Gap between sections: 24px (`space-y-6`). Gap between stat cards: 16px (`gap-4`). Fix any deviations.

---

#### AC-34: Consistent Error States Audit

Audit ALL existing pages and ensure they use `<ErrorState>` component from `web/src/components/shared/error-state.tsx` for error rendering. No page should show raw error text, console.error only, or blank screen on API failure.

Pages to audit:
- `/dashboard` -- stat cards, recent trainees, inactive alerts
- `/trainees` -- list, detail (all tabs)
- `/programs` -- list, builder, assign
- `/invitations` -- list
- `/analytics` -- adherence, progress
- `/notifications` -- list
- `/settings` -- profile, appearance, security
- All admin pages
- All new pages (covered by per-page ACs above)

---

#### AC-35: Consistent Empty States Audit

Audit ALL existing pages and ensure they use `<EmptyState>` component with contextual icon, clear title, helpful description, and CTA button. No page should show "No data" or a blank space.

---

## Workstream 3: E2E Test Suite

### AC-36: Playwright Setup

**Files to create:**
- `web/playwright.config.ts` -- Configuration:
  ```
  baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:3000"
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }]
  timeout: 30000
  retries: process.env.CI ? 1 : 0
  reporter: [["html", { open: "never" }]]
  use: { screenshot: "only-on-failure", video: "retain-on-failure", trace: "retain-on-failure" }
  webServer: { command: "npm run dev", port: 3000, reuseExistingServer: !process.env.CI }
  ```
- `web/e2e/helpers/auth.ts` -- Helper functions:
  - `loginAsTrainer(page: Page)` -- Navigates to /login, fills trainer credentials, submits, waits for /dashboard
  - `loginAsAdmin(page: Page)` -- Same but admin credentials, waits for /admin/dashboard
  - `loginAsAmbassador(page: Page)` -- Same but ambassador credentials, waits for /ambassador/dashboard
  - Credentials from env vars: `E2E_TRAINER_EMAIL`, `E2E_TRAINER_PASSWORD`, etc.
- `web/e2e/helpers/fixtures.ts` -- Test data constants: emails, expected names, etc.
- `web/e2e/helpers/utils.ts` -- Common utilities: `waitForToast(page, text)`, `expectEmptyState(page)`, `expectSkeleton(page)`.

**Dependencies:** Add to `web/package.json` devDependencies: `"@playwright/test": "^1.50.0"`
**Scripts:** Add to package.json: `"test:e2e": "playwright test"`, `"test:e2e:headed": "playwright test --headed"`

---

#### AC-37: Auth E2E Tests

**File:** `web/e2e/auth.spec.ts`
**Tests (13):**
1. `should login with valid trainer credentials and redirect to /dashboard`
2. `should login with valid admin credentials and redirect to /admin/dashboard`
3. `should login with valid ambassador credentials and redirect to /ambassador/dashboard`
4. `should show error for invalid credentials`
5. `should show validation error for empty email`
6. `should show validation error for empty password`
7. `should redirect unauthenticated user from /dashboard to /login`
8. `should redirect unauthenticated user from /admin/dashboard to /login`
9. `should redirect trainer from /admin/dashboard to /dashboard`
10. `should redirect admin from /dashboard to /admin/dashboard`
11. `should redirect ambassador from /dashboard to /ambassador/dashboard`
12. `should logout and redirect to /login`
13. `should show login page with animated hero on desktop viewport`

---

#### AC-38: Trainer Dashboard E2E Tests

**File:** `web/e2e/trainer/dashboard.spec.ts`
**Tests (6):**
1. `should show stat cards on dashboard`
2. `should show recent trainees table`
3. `should navigate to trainee detail on row click`
4. `should show trainee detail overview tab`
5. `should switch to activity tab and show data`
6. `should switch to progress tab and show charts`

---

#### AC-39: Trainer Trainee Management E2E Tests

**File:** `web/e2e/trainer/trainees.spec.ts`
**Tests (7):**
1. `should load trainee list with pagination`
2. `should filter trainees with search`
3. `should navigate to detail on click`
4. `should show nutrition goals in overview`
5. `should open edit goals dialog and validate inputs`
6. `should open assign program dialog`
7. `should open remove trainee dialog with confirmation`

---

#### AC-40: Trainer Programs E2E Tests

**File:** `web/e2e/trainer/programs.spec.ts`
**Tests (8):**
1. `should show program list with search`
2. `should navigate to new program builder`
3. `should show metadata and schedule sections in builder`
4. `should add exercise to a day`
5. `should save program and redirect to list`
6. `should load existing data in edit mode`
7. `should show delete confirmation dialog`
8. `should open assign dialog with trainee dropdown`

---

#### AC-41: Trainer Invitations E2E Tests

**File:** `web/e2e/trainer/invitations.spec.ts`
**Tests (5):**
1. `should show invitation list with status badges`
2. `should open create dialog and validate email`
3. `should copy invitation code to clipboard`
4. `should show resend option for pending invitations`
5. `should show cancel confirmation dialog`

---

#### AC-42: Trainer Notifications E2E Tests

**File:** `web/e2e/trainer/notifications.spec.ts`
**Tests (5):**
1. `should show notification bell with count`
2. `should open notification popover on click`
3. `should navigate to full notifications page`
4. `should mark notification as read`
5. `should mark all as read`

---

#### AC-43: Trainer Analytics E2E Tests

**File:** `web/e2e/trainer/analytics.spec.ts`
**Tests (4):**
1. `should show adherence stat cards`
2. `should change period selector and refetch`
3. `should show progress table with trainees`
4. `should navigate to trainee from chart click`

---

#### AC-44: Trainer Announcements E2E Tests

**File:** `web/e2e/trainer/announcements.spec.ts`
**Tests (6):**
1. `should show announcements list`
2. `should open create dialog and validate fields`
3. `should create announcement with title and body`
4. `should edit existing announcement`
5. `should delete with confirmation`
6. `should show pinned announcements first`

---

#### AC-45: Trainer AI Chat E2E Tests

**File:** `web/e2e/trainer/ai-chat.spec.ts`
**Tests (6):**
1. `should show empty state with suggestions`
2. `should populate input from suggestion chip click`
3. `should show user message bubble after send`
4. `should show trainee selector dropdown`
5. `should show clear conversation dialog`
6. `should disable send button when input empty`

---

#### AC-46: Trainer Exercise Bank E2E Tests

**File:** `web/e2e/trainer/exercises.spec.ts`
**Tests (6):**
1. `should show exercise grid with cards`
2. `should filter by search text`
3. `should filter by muscle group chip`
4. `should open detail dialog on card click`
5. `should open create exercise dialog`
6. `should validate required name field in create`

---

#### AC-47: Trainer Settings E2E Tests

**File:** `web/e2e/trainer/settings.spec.ts`
**Tests (7):**
1. `should show profile, appearance, security, branding sections`
2. `should edit profile name`
3. `should toggle theme (light/dark/system)`
4. `should validate password change fields`
5. `should show branding section with color pickers`
6. `should show leaderboard toggles`
7. `should persist theme across navigation`

---

#### AC-48: Admin Dashboard E2E Tests

**File:** `web/e2e/admin/dashboard.spec.ts`
**Tests (4):**
1. `should show admin stat cards (MRR, trainers, trainees)`
2. `should show revenue cards`
3. `should show tier breakdown`
4. `should show past due alerts section`

---

#### AC-49: Admin Trainer Management E2E Tests

**File:** `web/e2e/admin/trainers.spec.ts`
**Tests (5):**
1. `should show trainer list with search`
2. `should open trainer detail dialog`
3. `should toggle activate/suspend`
4. `should impersonate trainer (stores admin tokens)`
5. `should end impersonation and restore admin session`

---

#### AC-50: Admin Subscription Management E2E Tests

**File:** `web/e2e/admin/subscriptions.spec.ts`
**Tests (6):**
1. `should show subscription list with filters`
2. `should open detail dialog on row click`
3. `should submit change tier form`
4. `should submit change status form`
5. `should show payment history tab`
6. `should show change history tab`

---

#### AC-51: Admin Tier Management E2E Tests

**File:** `web/e2e/admin/tiers.spec.ts`
**Tests (4):**
1. `should show tier list`
2. `should open create tier dialog`
3. `should toggle tier active state`
4. `should block deletion of tier with subscriptions`

---

#### AC-52: Admin Coupon Management E2E Tests

**File:** `web/e2e/admin/coupons.spec.ts`
**Tests (5):**
1. `should show coupon list with filters`
2. `should create coupon with validation`
3. `should open detail dialog with usage history`
4. `should revoke coupon with confirmation`
5. `should reactivate revoked coupon`

---

#### AC-53: Admin User Management E2E Tests

**File:** `web/e2e/admin/users.spec.ts`
**Tests (4):**
1. `should show user list with role filter`
2. `should create admin user`
3. `should edit user name`
4. `should prevent self-deletion`

---

#### AC-54: Admin Ambassador Management E2E Tests

**File:** `web/e2e/admin/ambassadors.spec.ts`
**Tests (6):**
1. `should show ambassador list`
2. `should create ambassador with validation`
3. `should open detail dialog with tabs`
4. `should approve commission`
5. `should process bulk approve`
6. `should toggle suspend/activate`

---

#### AC-55: Ambassador Dashboard E2E Tests

**File:** `web/e2e/ambassador/dashboard.spec.ts`
**Tests (6):**
1. `should show earnings card with amounts`
2. `should show referral code`
3. `should copy code to clipboard`
4. `should show referral stats row`
5. `should render monthly earnings chart`
6. `should show recent referrals`

---

#### AC-56: Ambassador Referrals E2E Tests

**File:** `web/e2e/ambassador/referrals.spec.ts`
**Tests (3):**
1. `should show referral list`
2. `should filter by status chip`
3. `should show empty state with no referrals after filter`

---

#### AC-57: Ambassador Settings E2E Tests

**File:** `web/e2e/ambassador/settings.spec.ts`
**Tests (5):**
1. `should show profile info (read-only fields)`
2. `should edit custom referral code`
3. `should validate code format (min 4 chars)`
4. `should toggle theme`
5. `should show password change section`

---

#### AC-58: Responsive Layout E2E Tests

**File:** `web/e2e/responsive.spec.ts`
**Tests (6):**
1. `mobile (375px): should show hamburger menu`
2. `mobile: should open sidebar as sheet drawer`
3. `tablet (768px): should render tables responsively`
4. `desktop (1280px): should show fixed sidebar`
5. `mobile: no horizontal scroll on dashboard`
6. `mobile: no horizontal scroll on trainee list`

---

#### AC-59: Error State E2E Tests

**File:** `web/e2e/errors.spec.ts`
**Tests (4):**
1. `should show error state on API failure (mock 500)`
2. `should show retry button in error state`
3. `should redirect on 403 (unauthorized role)`
4. `should trigger token refresh on 401`

---

#### AC-60: Dark Mode E2E Tests

**File:** `web/e2e/dark-mode.spec.ts`
**Tests (4):**
1. `should toggle to dark mode and update background`
2. `should persist dark mode across navigation`
3. `should persist dark mode across reload`
4. `should render form inputs visible in dark mode`

---

## Edge Cases (Global)

1. **Token refresh race condition:** Multiple simultaneous API calls that get 401 should all wait for a single refresh. Already handled by refresh mutex in `token-manager.ts`.
2. **Role mismatch after impersonation end:** AuthProvider is source of truth. Middleware is convenience only.
3. **Concurrent tabs:** Refresh mutex uses localStorage lock. Multiple tabs won't conflict.
4. **Very slow network:** All API calls have 10s timeout (apiClient). Skeletons show immediately.
5. **Browser back/forward:** React Query cache serves stale-while-revalidate. No blank screens.
6. **CSP:** framer-motion uses CSS transforms, no `eval` or inline scripts needed.
7. **Large data sets:** All list pages paginate (page_size=20 for tables, 200 for dropdowns). Never unbounded.
8. **Empty string vs null:** All display code handles both (`value ?? "N/A"` or `value || fallback`).
9. **Unicode/emoji in names:** All text fields render international characters. CSS `word-break: break-word`.
10. **SessionStorage limits:** Impersonation stores ~2KB. Well within limits.

---

## Error States Table (All Pages)

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network offline | Banner "You appear to be offline" | Disable mutations, serve cached queries |
| API 401 | Nothing (silent refresh) or redirect to login | Token refresh, retry original request |
| API 403 | ErrorState "You don't have permission" | No retry button, suggest login link |
| API 404 | ErrorState "Not found" or Next.js not-found page | No retry |
| API 500 | ErrorState "Something went wrong" + "Try Again" button | Log error, allow retry |
| API timeout (10s) | ErrorState "Request timed out" + "Try Again" | Allow retry |
| Validation error | Inline field errors (red border + text below) | Zod parse, no submission |
| Empty response | Contextual EmptyState with CTA | Show empty state |

---

## UX Requirements (All Pages)

- **Loading state:** Content-shaped skeleton with pulse animation. NEVER a bare spinner.
- **Empty state:** Contextual icon + title + description + CTA. NEVER "No data."
- **Error state:** ErrorState component with icon + title + message + retry. NEVER raw error string.
- **Success feedback:** Sonner toast (bottom-right), auto-dismiss 4s, with action description.
- **Mobile behavior:** All pages responsive. Tables collapse to card lists on mobile (&lt;768px). Sidebar becomes sheet drawer. Touch targets minimum 44px.
- **Dark mode:** All new components use CSS variables only (bg-background, text-foreground, etc.). No hardcoded colors. Test both themes.
- **Accessibility:** All interactive elements have ARIA labels. Focus order logical. Keyboard navigation works. Color never the sole indicator. All dialogs have DialogDescription.

---

## Technical Approach

### Files to Create (New Pages -- 14 files)
- `web/src/app/(dashboard)/announcements/page.tsx`
- `web/src/app/(dashboard)/ai-chat/page.tsx`
- `web/src/app/(dashboard)/exercises/page.tsx`
- `web/src/app/(dashboard)/subscription/page.tsx`
- `web/src/app/(dashboard)/calendar/page.tsx`
- `web/src/app/(dashboard)/feature-requests/page.tsx`
- `web/src/app/(admin-dashboard)/admin/ambassadors/page.tsx`
- `web/src/app/(admin-dashboard)/admin/upcoming-payments/page.tsx`
- `web/src/app/(admin-dashboard)/admin/past-due/page.tsx`
- `web/src/app/(ambassador-dashboard)/layout.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/referrals/page.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/payouts/page.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/settings/page.tsx`

### Files to Create (Components -- ~55 files)
- `web/src/components/announcements/` (4 files: list, form-dialog, delete-dialog, skeleton)
- `web/src/components/ai-chat/` (5 files: container, message, trainee-selector, suggestion-chips, skeleton)
- `web/src/components/auth/login-hero.tsx` (1 file)
- `web/src/components/exercises/` (5 files: list, card, detail-dialog, create-dialog, skeleton)
- `web/src/components/subscription/` (5 files: overview, stripe-connect, payment-history, subscriber-list, skeleton)
- `web/src/components/calendar/` (3 files: connections, events, skeleton)
- `web/src/components/feature-requests/` (5 files: list, detail-dialog, create-dialog, comment-thread, skeleton)
- `web/src/components/ambassador/` (12 files: dashboard-earnings, referral-code, monthly-chart, stats-row, recent-referrals, dashboard-skeleton, referral-list, referral-skeleton, stripe-connect-setup, payout-history, payout-skeleton, ambassador-profile-section)
- `web/src/components/admin/` (6 files: ambassador-list, ambassador-detail-dialog, create-ambassador-dialog, ambassador-commissions, upcoming-payments-list, past-due-full-list, admin-settings-platform, admin-settings-security, admin-settings-notifications)
- `web/src/components/settings/branding-section.tsx`
- `web/src/components/settings/leaderboard-section.tsx`
- `web/src/components/trainees/` (8 files: assign-program-action, change-program-dialog, edit-goals-dialog, remove-trainee-dialog, layout-config-selector, impersonate-trainee-button, mark-missed-day-dialog, trainee-community-tab)
- `web/src/components/shared/page-transition.tsx`
- `web/src/components/dashboard/onboarding-checklist.tsx`
- `web/src/components/layout/` (3 files: ambassador-nav-links, ambassador-sidebar, ambassador-sidebar-mobile)

### Files to Create (Hooks -- 10 files)
- `web/src/hooks/use-announcements.ts`
- `web/src/hooks/use-ai-chat.ts`
- `web/src/hooks/use-branding.ts`
- `web/src/hooks/use-subscription.ts`
- `web/src/hooks/use-calendar.ts`
- `web/src/hooks/use-feature-requests.ts`
- `web/src/hooks/use-ambassador.ts`
- `web/src/hooks/use-admin-ambassadors.ts`
- `web/src/hooks/use-trainee-goals.ts`
- `web/src/hooks/use-leaderboard-settings.ts`

### Files to Create (Types -- 7 files)
- `web/src/types/announcement.ts`
- `web/src/types/ai-chat.ts`
- `web/src/types/branding.ts`
- `web/src/types/subscription.ts`
- `web/src/types/calendar.ts`
- `web/src/types/feature-request.ts`
- `web/src/types/ambassador.ts`

### Files to Create (E2E Tests -- ~27 files)
- `web/playwright.config.ts`
- `web/e2e/helpers/auth.ts`
- `web/e2e/helpers/fixtures.ts`
- `web/e2e/helpers/utils.ts`
- `web/e2e/auth.spec.ts`
- `web/e2e/trainer/dashboard.spec.ts`
- `web/e2e/trainer/trainees.spec.ts`
- `web/e2e/trainer/programs.spec.ts`
- `web/e2e/trainer/invitations.spec.ts`
- `web/e2e/trainer/notifications.spec.ts`
- `web/e2e/trainer/analytics.spec.ts`
- `web/e2e/trainer/announcements.spec.ts`
- `web/e2e/trainer/ai-chat.spec.ts`
- `web/e2e/trainer/exercises.spec.ts`
- `web/e2e/trainer/settings.spec.ts`
- `web/e2e/admin/dashboard.spec.ts`
- `web/e2e/admin/trainers.spec.ts`
- `web/e2e/admin/subscriptions.spec.ts`
- `web/e2e/admin/tiers.spec.ts`
- `web/e2e/admin/coupons.spec.ts`
- `web/e2e/admin/users.spec.ts`
- `web/e2e/admin/ambassadors.spec.ts`
- `web/e2e/ambassador/dashboard.spec.ts`
- `web/e2e/ambassador/referrals.spec.ts`
- `web/e2e/ambassador/settings.spec.ts`
- `web/e2e/responsive.spec.ts`
- `web/e2e/errors.spec.ts`
- `web/e2e/dark-mode.spec.ts`

### Files to Modify (~15 files)
- `web/src/lib/constants.ts` -- Add ~30 new API URL entries
- `web/src/components/layout/nav-links.tsx` -- Add 6 new trainer nav items (AI Chat, Exercises, Announcements, Subscription, Calendar, Feature Requests)
- `web/src/components/layout/admin-nav-links.ts` -- Add 3 items (Ambassadors, Upcoming Payments, Past Due)
- `web/src/middleware.ts` -- Add AMBASSADOR role routing
- `web/src/providers/auth-provider.tsx` -- Accept AMBASSADOR role
- `web/src/app/(auth)/login/page.tsx` -- Complete redesign (AC-29)
- `web/src/app/(auth)/layout.tsx` -- Two-column layout (AC-29)
- `web/src/app/(dashboard)/settings/page.tsx` -- Add BrandingSection + LeaderboardSection
- `web/src/app/(admin-dashboard)/admin/settings/page.tsx` -- Replace placeholder with real content
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` -- Add Community tab, program assignment, goal edit, remove, impersonate, layout config, mark missed day
- `web/src/hooks/use-exercises.ts` -- Add create/update mutations
- `web/src/components/ui/button.tsx` -- Add micro-interaction classes
- `web/src/components/dashboard/stat-card.tsx` -- Add trend indicator prop
- `web/src/components/dashboard/recent-trainees.tsx` -- Add avatar and last active columns
- `web/src/components/dashboard/inactive-trainees.tsx` -- Add severity color-coding
- `web/package.json` -- Add framer-motion + @playwright/test

### Dependencies to Add
- `framer-motion` -- `"framer-motion": "^12.0.0"` (page transitions, login animations)
- `@playwright/test` -- `"@playwright/test": "^1.50.0"` (devDependency, E2E testing)

---

## Out of Scope

- Trainee web access (trainee role is mobile-only)
- Real-time WebSocket on web (use polling/refresh for V1)
- New backend APIs (all APIs already exist from mobile implementation)
- Mobile-specific features (offline sync, health data, push notifications)
- Video attachments on community posts
- In-app messaging (trainer-to-trainee direct messages)
- Social auth (Apple/Google) on web
- MCP server integration in web UI
- TV mode
- Community WebSocket on web (use REST polling)
