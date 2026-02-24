# Pipeline 36 Focus: Web App Mobile Responsiveness

## Priority
Make the entire trainee web dashboard fully mobile-friendly. Every page must work beautifully on phones (320px–480px) and tablets (768px–1024px), not just desktop. Currently the web app is built for desktop viewports — tables overflow, sidebar doesn't collapse, touch targets are too small, and content doesn't reflow on narrow screens.

## Key Changes
- Navigation: Sidebar must collapse to hamburger menu or bottom nav on mobile
- Tables: Convert to card-based layouts on small screens (no horizontal scroll)
- Forms/inputs: Touch-friendly sizing (min 44px tap targets)
- Charts/visualizations: Must resize and remain readable
- Typography/spacing: Scale appropriately for mobile viewports
- Modals/dialogs: Full-screen or properly constrained on mobile
- All trainee web pages: Dashboard, Workouts, Nutrition, Settings, etc.

## Scope
- Trainee web portal — all pages
- CSS/layout changes only — no backend work
- Use Tailwind responsive utilities (sm:, md:, lg:) consistently
- Test at 375px (iPhone), 768px (tablet), 1024px+ (desktop) breakpoints
- Maintain existing desktop experience — only enhance for smaller screens
