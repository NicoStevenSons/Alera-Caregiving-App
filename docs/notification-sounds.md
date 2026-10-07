# Notification sounds

## Behaviour
- **Fixed alert sounds** (not user-selectable), one Android channel each:

| Category | Channel ID | Resource (`res/raw`) |
|---|---|---|
| Warning health alert | `alera_alert_warning_v1` | `alera_alert_warning` |
| Critical health alert | `alera_alert_critical_v1` | `alera_alert_critical` |
| Help request | `alera_help_request_v1` | `alera_help_request` |
| Device / system status | `alera_device_status_v1` | `alera_device_status` |
| Missed-reminder escalation | `alera_missed_reminder_v1` | `alera_missed_reminder` |

- **Reminder sounds** (user-selectable in More > Reminder Sound): `chime`, `bell`, `marimba`, `breeze`, `pulse`, plus `vibrate` (Vibrate Only) and `silent`.
  Channel ID is `alera_reminder_<id>_v1`, created lazily when selected.
- Selection is stored in secure storage under `alera_reminder_sound_v1` (readable from the background isolate).
- Channel sounds are immutable once created. To change a sound, ship a new version suffix (`_v2`); never edit a channel in place.
- Users can override any channel in Android system settings; the app does not bypass this.
- Reminders already scheduled locally keep the sound chosen at scheduling time.
- Legacy channels (`alera_alerts`, `alera_patient_reminders_v2`, `alera_nudges`) are kept for compatibility.

## Replacing the audio
The bundled WAVs are synthesized placeholders. Drop in files with the same names in `android/app/src/main/res/raw/` (keep names lowercase, no extension changes needed beyond wav/ogg/mp3). `keep.xml` prevents resource shrinking from removing them. Bump the channel version when replacing a sound that has already shipped.

## Backend payload requirements (cannot be completed in Flutter)
- **ALERT** (data-only): add `severity` = `WARNING` | `CRITICAL`; optional `alert_category` = `DEVICE_STATUS` | `MISSED_REMINDER`; optional explicit `sound_category` overriding inference. Without `severity` the app falls back to warning.
- **HELP_REQUEST**: if sent with a `notification` block, set `android.notification.channel_id = alera_help_request_v1` (otherwise Android uses the default channel, and the fixed sound is lost when the app is backgrounded/terminated). Data-only is preferred.
- **REMINDER_DUE**: must stay data-only so the app can choose the user's selected channel. A `notification` block would bypass the user's choice.
- **NUDGE**: out of scope; unchanged.
- Any backgrounded/terminated notification that includes a `notification` block is displayed by the OS using the channel in the payload, not by app code.
