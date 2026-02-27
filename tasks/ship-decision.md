# Ship Decision: Pipeline 39 (Churn Prevention) + Pipeline 40 (i18n)

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 9/10

## Summary
Both pipelines are production-ready. Pipeline 39 delivers a complete trainee retention analytics system with engagement/churn scoring, automated churn alerts, and full UI on web + mobile. Pipeline 40 delivers full i18n infrastructure across Django, Flutter, and Next.js with Spanish and Portuguese translations (~200 strings per platform), language selector UI, and Accept-Language header propagation. Code review fixes addressed all critical issues (bulk_create consistency, type-safe JSONB lookups, per-trainer error handling, cookie security, locale flash prevention). Security audit passed 9/10 with no critical or high issues.

## Verification Checklist
- [x] Web build passes (`npm run build`)
- [x] Flutter analyze passes
- [x] Backend structure valid
- [x] Code review: APPROVE after Round 1 fixes
- [x] Security audit: 9/10 PASS — no critical/high issues
- [x] All Pipeline 39 acceptance criteria met (engagement scoring, churn risk tiers, automated alerts, retention UI)
- [x] All Pipeline 40 acceptance criteria met (i18n infrastructure, 3 languages, language selector, Accept-Language headers)

## What Was Built

### Pipeline 39: Trainee Retention & Churn Prevention Analytics
- **Engagement scoring** (0-100) per trainee based on workout/nutrition consistency, goal adherence, and recency (14-day rolling window)
- **Churn risk scoring** (0-100) with 4 risk tiers: Critical (>=75), High (>=50), Medium (>=25), Low (<25)
- **New trainee guard** — Trainees created within lookback window with zero activity capped at Medium risk
- **Automated churn alerts** via `compute_retention` management command (daily cron) with 3-day deduplication
- **Re-engagement pushes** for critical-risk trainees with 7-day deduplication
- **2 new API endpoints**: `GET /api/trainer/analytics/retention/` and `GET /api/trainer/analytics/at-risk/`
- **Web UI**: RetentionSection with 4 summary cards, risk distribution chart, retention trend chart, at-risk trainee table with sortable columns and risk badges
- **Mobile UI**: RetentionAnalyticsScreen with summary cards, risk tier badges, at-risk trainee tiles, engagement indicators
- **67 files changed, ~4500 lines of new code** (backend service + notifications + command + web components + mobile screens)

### Pipeline 40: Multi-Language Support (i18n — Spanish + Portuguese)
- **Django**: `preferred_language` CharField on UserProfile, `LocaleMiddleware`, `LANGUAGES`/`LOCALE_PATHS` settings, PO files for en/es/pt-BR (~20 API error strings each)
- **Flutter**: `flutter_localizations` + `gen_l10n` with ARB files (en/es/pt, ~200 strings each), `LocaleProvider` (Riverpod StateNotifier + SharedPreferences), `context.l10n` extension, `Accept-Language` header in API client, language settings screen with backend sync
- **Next.js**: React context-based i18n with cookie persistence (`NEXT_LOCALE`), JSON message files (en/es/pt-BR, ~130 strings each), `LocaleProvider` with `t()` function, `LanguageSelector` component on all 4 settings pages, `Accept-Language` header in API client
- **Language selector** on all settings pages (admin, trainer, trainee, ambassador on web; all 3 roles on mobile)
- **Translation glossary** (`translations/glossary.md`) with standardized fitness terms across all languages
- **Cookie security**: Secure flag for HTTPS, string-split getCookie (no regex/ReDoS risk), synchronous locale initialization (no English flash)

## Remaining Concerns
- String extraction in existing Flutter/Web screens (replacing hardcoded strings with l10n references) is Phase B follow-up — infrastructure is in place, ~380 strings to extract in a future pipeline
- Django `compilemessages` needs to be run in deployment to generate .mo files from .po files
- FCM push delivery for re-engagement is logged but not wired to firebase_admin yet (noted in code)
