# Focus: Trainer Notifications Dashboard + Ambassador Commission Webhook

## Priority: HIGH

## What
Two related features around event-driven actions:
1. **Trainer Notifications Dashboard** — Mobile screen for trainers to view workout notifications (readiness surveys, post-workout completions) that are already being created in the DB but have no way to be viewed. Includes badge counts, mark-as-read, and a dedicated notifications screen.
2. **Ambassador Commission Webhook** — Wire the existing `ReferralService.create_commission()` into Stripe webhook handlers so ambassadors actually earn commissions when referred trainers pay.

## Why
- **Notifications**: Trainers (paying customers) have zero visibility into trainee activity unless they manually refresh the dashboard. Notifications are already being created (BUG-2 fix) but never displayed. This is the #1 engagement feature for trainer retention.
- **Commissions**: The entire ambassador referral system is built but commissions are never created because the Stripe webhook doesn't call the commission service. Ambassadors refer trainers but never see earnings.

## Who Benefits
- **Trainers**: See real-time trainee activity, feel connected, stay engaged
- **Ambassadors**: Actually earn commissions for referrals
- **Platform**: Higher trainer retention (notifications), activated revenue channel (commissions)

## Success Metric
- Trainer opens notifications tab → sees list of trainee workout events with timestamps
- Referred trainer pays subscription → ambassador dashboard shows commission earned
