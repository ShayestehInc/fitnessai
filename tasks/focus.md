# Focus: Progress Photos Bug Fixes & Web Dashboard

## Priority
HIGH — Progress Photos feature exists but has 4 critical mobile bugs (broken category filters, broken trainer view, measurements format issue) and zero web dashboard implementation. Trainers cannot view trainee progress photos from either mobile or web.

## What Already Exists
- Backend: ProgressPhoto model, serializer, viewset, compare endpoint — all working
- Mobile: Gallery, Add, Comparison screens — all exist but have critical bugs
- Mobile: Router, providers, repository — all wired up

## What's Broken
1. Gallery category filter tabs are all duplicates ("All" x4 instead of All/Front/Side/Back)
2. Add photo category options missing "Other" (duplicate "Side" instead)
3. Trainer view ignores trainee_id query parameter — trainers see nothing
4. Measurements sent as string repr instead of JSON

## What's Missing
- Web dashboard: zero progress photos implementation
- Pagination on photo gallery
