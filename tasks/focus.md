# Pipeline 29 Focus: CSV Data Export for Trainer Dashboard

## Priority
Add CSV export capabilities to the trainer web dashboard so trainers can download their payment history, subscriber list, and trainee roster for bookkeeping, tax filing, and business planning.

## Why This Feature
1. **Trainers need to export financial data** — For tax filing, accountant handoff, and business records, trainers need downloadable CSV files of their payment and subscriber data.
2. **Data is visible but not extractable** — Pipeline 28 added the Revenue Analytics section showing payments and subscribers, but there's no way to download that data.
3. **Zero export functionality exists** — The entire platform has no CSV/file export capability anywhere. This is a first.
4. **Commonly requested in business SaaS** — Every financial dashboard needs an export button. This is table-stakes for a business tool.
5. **Moderate complexity** — Backend CSV generation + 3 export endpoints + frontend download buttons following established patterns.

## Scope
- Backend: New CSV export service with Django's csv module
- Backend: 3 export endpoints: payments, subscribers, trainees
- Web: Reusable ExportButton component with download handler
- Web: Export buttons on Revenue section (payments + subscribers) and Trainee list page
- Tests: Comprehensive backend tests for export endpoints

## What NOT to build
- Ambassador export (future pipeline)
- Admin-level bulk export
- PDF reports or formatted reports
- Mobile export
- Email delivery of reports
