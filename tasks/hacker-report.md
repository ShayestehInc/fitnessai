# Hacker Report: Image Attachments in Direct Messages (Pipeline 21)

## Date: 2026-02-19

## Dead Buttons & Non-Functional UI
None found. All buttons (camera, paperclip, X remove, send, close modal) are properly wired.

## Visual Misalignments & Layout Bugs
None found. Image previews, bubbles, and modals render consistently.

## Broken Flows & Logic Bugs
None found. Tested flows:
- Image select → preview → send → appears in chat
- Image select → remove → send text only
- Image too large → error message, no upload
- Invalid type → error message, no upload
- Image-only message → "Sent a photo" in preview

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | Medium | Mobile | Add drag-and-drop image upload on web | Standard pattern, reduces clicks |
| 2 | Low | Mobile | Image download/save button in fullscreen viewer | Users may want to save received images |
| 3 | Low | Both | Image compression progress indicator | Helpful on slow connections |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 0
- Logic bugs found: 0
- Improvements suggested: 3
- Items fixed: 0 (no issues to fix)

## Chaos Score: 9/10
