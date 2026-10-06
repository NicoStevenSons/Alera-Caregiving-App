# Placeholder icons (`status/error.svg`)

Anywhere a Figma icon doesn't exist yet, the app shows
`alera-figma-assets/assets/icons/status/error.svg` (a grey question mark).
Each occurrence below is an icon that still needs to be designed. Replace the
file (or the path) and the placeholder disappears.

## Reminder categories

Each category has its own file in `assets/icons/reminders/`. Five of them are
currently **byte-for-byte copies of `status/error.svg`**. Overwrite the file
with the real icon; no code change is needed. These files are shown in the
create-reminder category dropdown, the reminders timeline and Manage schedules.

| Category     | File to replace                                     |
| ------------ | --------------------------------------------------- |
| Medication   | `assets/icons/reminders/medication.svg`             |
| Hydration    | `assets/icons/reminders/hydration.svg`              |
| Meal         | `assets/icons/reminders/meal.svg`                   |
| Check In     | `assets/icons/reminders/check_in.svg`               |
| Other        | `assets/icons/reminders/other.svg`                  |

Categories that already use a matching Figma icon (replace only if you want a
dedicated one): Health Check (`vitals/heart_rate.svg`), Mobility
(`vitals/activity.svg`), Device Task (`devices/watch-monitoring.svg`),
Appointment (`status/reminder.svg`).

## Filter alerts drawer

`lib/features/caregiver/presentation/alerts/caregiver_alerts_page.dart`
defines `_filterIconPlaceholder`, which points at `status/error.svg`. It is used
by:

| Filter       | Where                                   |
| ------------ | --------------------------------------- |
| Watch Battery | `_filterIconBattery` (own constant)    |
| Acknowledged | `option('Acknowledged', ...)`           |
| False Alarm  | `option('False Alarm', ...)`            |

To fix, add a new constant (e.g. `_filterIconAcknowledged`) pointing at the new
SVG and use it in that `option(...)` call. Once neither filter uses
`_filterIconPlaceholder`, delete it.

Filters that already use a matching Figma icon: Warning, Critical (`status/*`),
Heart Rate, SpO2 (`vitals/*`), Unacknowledged (`status/alert.svg`), Resolved
(`status/stable.svg`). Watch Battery has no tile in `status/` or `vitals/`, so it
uses the placeholder via its own `_filterIconBattery` constant (a battery SVG
exists at `device_status/batterylvl-high.svg` if you'd rather reuse it).

## Not covered

The small status badge on patient avatars (Switch patient drawer, Alerts list)
still uses Material glyphs, because that badge tints a single-colour glyph white
on a solid circle, and the Figma icons are full-colour.
