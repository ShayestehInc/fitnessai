# Focus: Community Events — Trainer Create & Trainee RSVP (Mobile)

## Priority
The backend for Community Events is 100% built (models, serializers, trainer CRUD views, trainee list/detail/RSVP views, API endpoints all wired in urls.py). API constants are already defined in the mobile app. But there are ZERO mobile screens — trainers cannot create events and trainees cannot browse or RSVP.

## Scope
- Trainer: create/edit/delete events from trainer community management
- Trainee: browse upcoming events, view event details, RSVP (going/interested/not going)
- Both: event list with date grouping, event detail with description, location, attendee count
- Wire into existing navigation (trainer dashboard community section, trainee SchoolHomeScreen)
- No backend changes needed — all APIs exist
