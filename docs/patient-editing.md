# Edit Patient and caregiver relationship label

## What the app does now
- **Edit entry point:** an edit (pencil) button in the app bar of a backend-backed patient detail page.
- **Edit Patient screen** (`presentation/people/edit_patient_page.dart`): pre-filled full name, phone, address/room, birthdate (DD/MM/YYYY boxes), sex, profile photo, emergency contact name and phone, known conditions, medications, monitoring notes, and the caregiver's relationship label. Monitoring thresholds and baseline readings are **not** part of the profile fields or the profile save. The form has a separate **Monitoring ranges** row (see below).
- **States:** validation, saving (buttons disabled, "Saving…"), failure (inline message, draft kept, button becomes "Try again"), success (screen closes, detail page and People list update immediately, "Patient updated." snackbar). If the profile saves but the new photo upload fails, the profile counts as saved and the snackbar says the photo could not be uploaded.
- **Relationship label:** optional field in Add Patient (personal step) and Edit Patient. Picked from an icon grid (3 columns, like the reminder categories): Mother, Father, Grandmother, Grandfather, Spouse, Relative, Client, Friend, plus Other, which reveals a text box for custom text. Tapping the selected tile clears it. Icons are placeholders (`assets/icons/relationships/*.svg`, copies of `status/error.svg`); see `alera-figma-assets/PLACEHOLDER_ICONS.md`. Whitespace is collapsed, blank means "not set", maximum 50 characters. It shows under the patient's name on the People list and as the chip on patient detail; with no label the detail chip keeps showing "Under your care".
- **Per-caregiver, not per-patient:** the label belongs to the assignment between the signed-in caregiver and the patient. It is carried as `relationshipLabel` on the current-caregiver patient DTOs only, never on a shared patient profile.

## Monitoring ranges (from Edit Patient)
- The **Monitoring ranges** row on Edit Patient shows the current ranges ("Alera defaults" or "Heart rate 55–105 bpm · SpO₂ 92–99%") and opens `edit_monitoring_ranges_page.dart`.
- That screen offers **Use Alera defaults** (60–100 bpm, SpO₂ minimum 95%) or **Set custom ranges** (heart rate min/max 1–999, SpO₂ min 0–100, optional SpO₂ max 0–100, min must not exceed max). It saves immediately through the existing `PATCH /api/v1/patients/{patient_id}/monitoring-settings` (`updateMonitoringSettings`); the profile `PATCH` never carries thresholds.
- "Use Alera defaults" on a patient with custom ranges **saves the built-in values** (60, 100, 95, SpO₂ max `null`) rather than calling a separate reset endpoint. Confirm with the backend that these values return `threshold_mode: DEFAULT`; if it keeps reporting `CUSTOM`, the row will say "Heart rate 60–100 bpm · SpO₂ min 95%" until a reset is added.
- Ranges save on their own screen. If the caregiver then cancels the profile form, the detail page still shows the saved ranges.

## Archive patient (from Edit Patient)
- Edit Patient ends with a quiet red **Archive patient** action. It opens a confirmation dialog (red icon and red **Archive** button, **Cancel**) naming the patient. Nothing happens until the red button is pressed; failures show inside the dialog and keep the page.
- On success the patient is removed from the People list, the detail page closes and the app shows "<name> archived."
- **Not wired to the backend yet.** No patient-archive endpoint exists in the app's API client and none was invented. The UI goes through `CaregiverPatientArchiveDataSource`; the app currently uses `UnavailablePatientArchiveDataSource`, which fails with "Archiving patients isn’t available yet. Nothing was changed." Once the contract is confirmed, add an API implementation and pass it as `patientArchiveDataSource` to `CaregiverShell` in `caregiver_auth_gate.dart`. The backend already returns `archived_at` on patient detail, so the list endpoint should stop returning archived patients (confirm).

## How saving works
Edit Patient saves through an injectable `CaregiverPatientEditDataSource`. In the app the implementation is `CaregiverPatientApiDataSource.updatePatient`, which calls the backend endpoint below. `CaregiverAuthGate` builds one `CaregiverPatientApiDataSource` for the signed-in caregiver session and passes it to `CaregiverShell` as both `patientDataSource` (read, create, photo, monitoring settings) and `patientEditDataSource`. The shell forwards it to the patient detail page, which opens Edit Patient.

- **Request:** `PATCH /api/v1/patients/{patient_id}` with `Authorization: Bearer <caregiver token>` and the complete editable payload from `UpdatePatientRequest.toJson()`. Every editable key is always sent; a cleared or blank field is an explicit `null`. Monitoring thresholds and baselines are never sent.
- **Response:** `200` with a `PatientDetailDto`, which becomes the refreshed patient in the app.
- **After success:** the detail page shows the saved values immediately and `CaregiverPatientController.applyPatientUpdate` refreshes the People list row (name, details and the caregiver's `relationship_label`).
- **Failures** (draft is kept, button becomes "Try again"): `401` clears the session and asks the caregiver to sign in again; `403` "You do not have permission to edit this patient."; `404` "Patient not found."; `422` shows the safe validation message from `detail`; `5xx` "The server is temporarily unavailable."; timeouts and connection errors are retryable; an unparseable body is reported as an unexpected response.
- `UnavailablePatientEditDataSource` is kept only as the fallback for screens built without an edit data source (previews and tests). It is no longer used in normal app wiring.

## Backend contract
Implemented on `exzestentialcrisis/alera-backend` `master`; the app follows it as described here.

### Update patient
`PATCH /api/v1/patients/{patient_id}` with the caregiver bearer token.

Request body (full replacement of these fields; an explicit `null` clears the value):

```json
{
  "full_name": "Maria Santos",
  "birthdate": "1950-02-03",
  "sex": "FEMALE",
  "phone_number": "09123456789",
  "address_or_room": "Room 4",
  "emergency_contact_name": "Juan",
  "emergency_contact_phone": "555-0100",
  "known_conditions": "Hypertension",
  "medications": "Medication A",
  "monitoring_notes": "Morning checks",
  "relationship_label": "Mother"
}
```

- `full_name` required, max 150. `sex` is `MALE`, `FEMALE`, `OTHER` or null. `phone_number` max 11 (matches Add Patient). `emergency_contact_phone` max 30. `emergency_contact_name` max 150.
- `relationship_label`: optional, normalized by the server too (trim, collapse whitespace), max 50, blank stored as null.
- Must **not** accept or change monitoring thresholds or baseline values (those use `PATCH /api/v1/patients/{patient_id}/monitoring-settings`).
- Response: `200` with the same shape as `GET /api/v1/patients/{patient_id}` (`PatientDetailDto`), including `relationship_label`.
- Errors the app handles: `401` (sign in again), `403` (no permission), `404` (patient not found), `422` with a safe `detail` message, `5xx`.
- Authorization: only caregivers currently assigned to the patient may update. Updating profile fields affects the shared patient profile for every assigned caregiver, so the backend should decide who may do that.

### Relationship label storage
- Store it on the caregiver-patient assignment record (for example `patient_assignments.relationship_label`, nullable, 50 chars), **not** on the patient.
- `PATCH` writes it for the **requesting** caregiver's active assignment only. It must never change another caregiver's label.
- `GET /api/v1/patients` (list items) and `GET /api/v1/patients/{patient_id}` return `relationship_label` for the **requesting** caregiver (null when unset).
- `POST /api/v1/patients` (Add Patient) may include `relationship_label`; the app only sends the key when the caregiver typed one, so older backends are unaffected until a label is entered.

### Profile photo
Unchanged: `POST /api/v1/patients/{patient_id}/profile-photo` (existing upload). Edit Patient calls it after the profile update succeeds. There is no endpoint to remove an existing photo, so the screen only offers replacing it.

## Not done on purpose
- No People filtering or search by relationship. The placeholder filter and pencil buttons in the People app bar were removed; editing a patient happens from the patient detail page.
- Add Patient review screen does not list the relationship (it is optional and not part of the profile review).
- Reminder behavior, notification sounds, alert thresholds, authentication and patient access were not touched.
