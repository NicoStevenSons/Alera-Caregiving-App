# Reminder occurrence timeline

Frontend for `GET /api/v1/reminders/{occurrence_id}/events?limit=50&offset=0` (already built on the backend).

- **One shared implementation** for both roles: `ReminderEventsDataSource` (implemented by `ReminderApiDataSource.fetchEvents`) uses whichever session token is signed in (caregiver or elderly patient), so the backend decides what is visible.
- `ReminderEvent` / `ReminderEventDto` (`reminders/domain|data`): unknown `event_type` becomes `ReminderEventType.unknown` and unknown `actor_role` becomes `ReminderActorRole.unknown`; actor id, display name, note and metadata are optional. Required: `event_id`, `reminder_occurrence_id`, `occurred_at`.
- `ReminderTimelineController`: loading, empty, retryable failure, 404 (no retry), "load more" pagination. Order is the backend's (oldest first); pages are appended.
- `ReminderHistorySection`: the shared list widget. Caregiver: title "Timeline". Elderly (`elderly: true`): title "History", larger text, plain wording, "Alera" for system events, no technical terms.
- **Caregiver:** tapping any reminder card (including completed/canceled ones) opens `ReminderOccurrenceDetailPage`: title, category, status, scheduled and due times, instructions, the existing Complete / Snooze / Cancel actions (for upcoming, due and snoozed reminders) and the Timeline. The history reloads after an action.
- **Elderly:** `PatientReminderDetailPage` shows the existing card (Complete and Snooze unchanged) followed by "History". No caregiver-only controls.
- Only meaningful metadata is shown: `snoozed_until` on snoozes, audience/channel on notifications. Nothing else from `metadata` is rendered.

Not changed: backend, authentication, notification sounds, alert behavior, monitoring thresholds, relationship/edit-patient code.
