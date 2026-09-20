# Add Patient / Patient Access icon audit

Everywhere the setup flow (`add_patient_page.dart`, `patient_access_setup_page.dart`,
`widgets/patient_access_views.dart`) needed an icon, two things happened:

1. **A branded SVG already existed** for it (elsewhere in the app) → the flow was
   updated to use that real asset via `AleraSvgIcon`, not a Material icon. Done,
   no action needed:
   - The smartwatch row now uses `assets/icons/devices/watch-monitoring.svg`
     (the same asset `monitoring_devices_card.dart` uses).
   - Every "success" checkmark (patient created, patient access connected —
     four places total) now uses `assets/icons/status/no-active-alerts.svg`,
     the same purple checkmark badge the Active Alerts empty state uses.
2. **No branded asset exists yet** → the flow still falls back to a plain
   Material icon (`Icons.*`), same as the rest of the app does before its own
   "UI icon replacement pass" (see `../FIGMA_ICON_README.md`). Those are listed
   below so they're easy to find and swap in one pass, the same way the
   `status/`, `vitals/` and `mini_status/` folders were.

Nothing below is wired up as a missing file — the code still renders the
Material icon named in each row until you drop in a real SVG and update the
one line noted. Suggested filenames follow the existing kebab-case convention
and a new `assets/icons/setup/` folder, but the code doesn't assume that
location; use whatever path makes sense once the assets exist.

## Icon-in-circle badges (the "what you're setting up" motif)

These render inside a 36–64px `AleraColors.primarySoft` circle, matching the
`_IntroRow` / `_CreatedRow` / notice-card pattern used throughout the flow.

| Where it appears | Current Material icon | Suggested asset | Notes |
|---|---|---|---|
| "Add Patient" intro list — Personal information | `Icons.person_outline` | `setup/personal-information.svg` | |
| "Add Patient" intro list — Care information | `Icons.description_outlined` | `setup/care-information.svg` | Same icon reused on the "Created" screen's "Profile" row |
| "Add Patient" intro list — Monitoring settings | `Icons.monitor_heart_outlined` | `setup/monitoring-settings.svg` | Same icon reused on the "Created" screen's "Monitoring" row |
| "Add Patient" intro list — Patient access | `Icons.people_outline` | `setup/patient-access.svg` | Same icon reused on the "Created" screen's "Patient access" row, and on the patient-access intro card's "For the patient" row |
| Personal Information step — empty photo avatar | `Icons.person_outline` | `setup/profile-placeholder.svg` | Shown until a photo is chosen |
| Monitoring step (custom ranges) — "Critical safety limits" note | `Icons.info_outline` | `setup/info.svg` | |
| Patient-access intro card — "Valid for 24 hours" | `Icons.schedule_outlined` | `setup/valid-24h.svg` | Also used in the smaller validity strip on the issued-code screen |
| Patient-access intro card — "One-time use only" | `Icons.verified_user_outlined` | `setup/one-time-use.svg` | Also used in the smaller validity strip on the issued-code screen |
| "Finish setup for now?" confirmation dialog | `Icons.watch_later_outlined` | `setup/finish-later.svg` | |
| "Create patient?" confirmation dialog | `Icons.person_add_alt_outlined` | `setup/create-patient.svg` | |
| "Replace invitation?" / "Generate a new login code?" confirmation dialog | `Icons.autorenew` | `setup/renew-code.svg` | |
| "The invitation expired" notice | `Icons.timer_off_outlined` | `setup/expired.svg` | Appears on both the Add Patient pairing step and the standalone Patient Access page |
| "Invitation pending" notice | `Icons.schedule_outlined` | `setup/pending.svg` | |
| "Patient access status is unavailable" notice | `Icons.help_outline` | `setup/unavailable.svg` | Edge-case fallback; low priority |

## Left as plain Material icons on purpose

These are small inline/utility icons (button glyphs, chevrons, a dropdown
arrow) rather than the badge motif above, and match how the rest of the app
already treats icons of this kind (e.g. the back chevron, which
`FIGMA_ICON_README.md` already calls out as intentionally unchanged):

- Back button chevron (`Icons.chevron_left`)
- "Choose/Change photo" button (`Icons.photo_library_outlined`)
- Sex dropdown arrow (`Icons.keyboard_arrow_down`)
- Copy code / Copy (`Icons.content_copy_outlined`)
- Share (`Icons.share_outlined`)

## Already using a real asset (reference only, nothing to do)

- Smartwatch row, "Created" screen → `assets/icons/devices/watch-monitoring.svg`
- "Patient added" checkmark → `assets/icons/status/no-active-alerts.svg`
- "Patient access connected" checkmark (3 places: pairing flow, and both
  "already connected" / "just connected" states on the standalone Patient
  Access page) → `assets/icons/status/no-active-alerts.svg`
