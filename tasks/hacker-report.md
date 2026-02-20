# Hacker Report: Ambassador Dashboard Enhancement (Pipeline 25)

## Date: 2026-02-20

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| — | — | — | — | — | — |

No dead buttons found. All filter tabs, pagination buttons, and search input are functional.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | EarningsChart X-axis | 12 month labels may overlap on small mobile screens | **FIXED**: Added `interval="preserveStartEnd"` to X-axis to auto-thin intermediate labels on small viewports while always showing first and last month |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| — | — | — | — | — | — |

Tested flows:
- Rapid filter tab switching: React Query handles via cache key change, no stale data flash
- Pagination during fetch: Buttons correctly disabled, keepPreviousData shows stale data with opacity fade
- Empty first_name + last_name: Falls back to email correctly
- Error state: Shows error EmptyState while tabs remain interactive
- Search → filter change: Search text clears and page resets to 1 correctly

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | Medium | Referral list | Show referral count in each filter tab (e.g., "Active (5)") | Gives instant visibility into distribution without needing the breakdown chart. Would require fetching total counts from dashboard data or a separate endpoint. |
| 2 | Low | Earnings chart | Add "Total" summary below chart showing sum of visible months | Context for the chart — "Total: $4,250.00 over 12 months". Easy to compute from existing data. |
| 3 | Low | Referral list | Keyboard shortcut to focus search (e.g., "/" key) | Standard pattern from GitHub, Linear. Low effort, high polish. |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 1
- Logic bugs found: 0
- Improvements suggested: 3
- Items fixed by hacker: 1

## Chaos Score: 8/10
Clean implementation with good state management and edge case handling. The `keepPreviousData` + opacity fade pattern works well for pagination. Status filter tabs correctly reset page and clear search. The only fix needed was X-axis label overlap on mobile, resolved with `interval="preserveStartEnd"`.
