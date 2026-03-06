# Focus: Firebase Cloud Messaging (FCM) for Community Events

## Priority
Critical — This is the highest-impact large effort feature remaining.

## Context
Community events (create, RSVP, cancel) were shipped in Pipeline 47. Push notifications via FCM are needed so trainees actually know when:
1. A new event is created by their trainer
2. An event they RSVP'd to is starting soon (15-min reminder)
3. An event they RSVP'd to is cancelled
4. An event they RSVP'd to is updated (time/location change)

## Scope
- Backend: FCM integration service, device token registration endpoint, notification dispatch on event lifecycle hooks
- Mobile: Firebase Messaging setup, foreground/background handlers, device token registration on login, notification tap → deep link to event detail
- Web: Optional (nice-to-have, not required this pipeline)

## What Already Exists
- Community events backend + mobile fully wired
- TrainerNotification model exists for in-app trainer notifications
- No FCM/firebase_messaging dependency in mobile yet
- No device token model in backend yet
- Apple Watch architecture plan exists but no FCM there yet

## Success Criteria
- Trainee receives push notification when trainer creates an event
- Trainee receives push notification 15 min before an RSVP'd event
- Trainee receives push notification when an RSVP'd event is cancelled/updated
- Tapping notification deep links to event detail screen
- Device tokens are registered/refreshed on login and token refresh
- Notifications work in foreground, background, and terminated states
