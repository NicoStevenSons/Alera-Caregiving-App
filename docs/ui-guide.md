# Alera UI Laws & Guide

How Alera should look and behave. The **Laws** are the rules we do not break;
the **Guide** is how to apply them with the components and tokens that already
exist. When a screen disagrees with this document, fix the screen (or, if the
document is wrong, change the document in the same PR).

Alera is a caregiving app. The caregiver is often tired, stressed or in a
hurry, and the person being cared for may be elderly. So the design is calm,
soft, legible and predictable. Nothing should shout unless something is
genuinely wrong.

---

## Part 1: The Laws

### 1. One source for everything
Colours, spacing, radii, type styles, icons, spinners, toasts, dialogs and pills
each have exactly one home in `lib/design_system/`. If a value is not there,
**add it there first**, then use it. No literal `Color(0x…)`, no magic radius,
no raw `SnackBar`, `AlertDialog`, `CircularProgressIndicator`, `Chip` or
`ChoiceChip` in feature code.

### 2. Soft, not stark
The palette is lavender and white. We prefer low contrast and gentle depth over
hard outlines.
- One brand purple (`AleraColors.primary` / `selected`, `#AE8BEA`). No second,
  darker "action purple" and no near-black purple outlines.
- Cards are white, borderless, with a soft shadow. A border is only for a
  deliberate selected or tinted state and is never combined with a heavy shadow.
- Backgrounds are `background` (page) and `surface` (cards). `surfaceTint` is for
  selected options, QR backdrops and grouped summaries.

### 3. Colour carries meaning, so never decorate with it
- **Status colours mean status**: `critical` (needs attention now), `warning`,
  `success`, `information`. Do not use them for decoration.
- **Category colours mean category** (medication, meal, hydration…). They appear
  only on the category tile, the card wash and the category icon, never on
  meta text, time, repeat or chevron icons.
- Meta details (time, repeat, date, actor) are always **neutral grey**: icon
  `mutedIcon`, text `textSecondary`. The same fact must look identical on every
  card.

### 4. Same thing, same look, on every screen
The same reminder, alert, patient or status must render with the same
structure wherever it appears (Home, patient page, Reminders tab, history). If
two screens show the same object differently, one is wrong. Reuse the shared
widget; do not fork a near-copy.

### 5. Chevrons and back arrows are quiet
- Navigation is a **bare chevron**, no label, no circle, no coloured fill:
  `AleraBackButton` / `AleraChevronAppBar`.
- Chevrons are always the same grey (`mutedIcon`; list-row chevrons use
  `mutedChevron`) and always `chevron_right` for "go deeper" and `expand_more`
  for dropdowns. No `arrow_forward_ios`, no mixed sizes.

### 6. Icons are filled
Use filled Material icons (`Icons.check_circle`, not `check_circle_outline`).
Prefer the Figma icon set (`alera-figma-assets/assets/icons/…`) through
`AleraSvgIcon` whenever one exists. Where a Figma icon does not exist yet, use
`status/error.svg` as an obvious placeholder, not an unrelated Material icon.
The only outline we keep is the unselected state of a radio-style marker.
Navigation uses an outline icon when idle and the filled twin when selected.

### 7. Three radii, a few exceptions
`radiusSmall` 8 (chips, inputs, small tiles), `cardRadius` 12 (cards, rows),
`radiusLarge` 20 (dialogs, sheets, hero cards), `radiusPill` 999 (pills,
avatars). Tiny shapes (progress bars, indicator dots) may use 2-5. Anything
else is a bug.

### 8. Type has a ladder
Pick the nearest rung of `AleraTypography`; do not invent a size.

| Style | Size / weight | Use |
|---|---|---|
| `pageTitle` | 24 / 700 | App-bar and screen titles |
| `heading` | 22 / 700 | In-page hero headings |
| `sectionTitle` | 18 / 700 | Section headers |
| `cardTitle` | 16 / 700 | Card titles |
| `rowTitle` | 15 / 700 | Title inside a compact row |
| `body` | 15 / 400 | Paragraph text |
| `bodyStrong` | 14 / 600 | Menu items, option labels |
| `bodySmall` | 13 / 400 | Secondary paragraph text |
| `label` | 13 / 600 | Labels, pills |
| `caption` | 12 / 400 | Subtitle under a title, times, helper text |
| `micro` | 11 / 400 | Timestamps, tiny captions |
| `errorText` | 12 / 400 critical | Inline validation and failure |

Titles are `textPrimary`; everything supporting is `textSecondary`. Never put
critical-red on a long paragraph.

### 9. Feedback is consistent and non-blocking
- **Toast**: `showAleraSnackBar` with `success`, `error` or `info`. A floating
  white card with a tinted icon tile. Never a raw `SnackBar`.
- **Confirm / input**: `AleraDialog` or `showAleraConfirmDialog`. White,
  `radiusLarge`, round icon, centred copy, pill button pair (Back / action).
  Destructive actions use the red pill and the destructive icon tint.
- **Loading**: `AleraLoader` (`.small` in buttons and rows, default inline,
  `.large` for a whole page). Prefer skeletons (`alera_skeleton`) for
  content-shaped waits.
- **Errors** say what happened in plain words and offer the next step (a Retry
  button). They are never a stack trace or an error code.

### 10. Calm layout
Pages scroll on `background`, with 16-24px side gutters. Group related things
into one card; separate groups with generous space, not dividers everywhere.
One primary action per screen or card. Destructive and rare actions live lower
and look quieter (the More page's grouped Care / App / Sign out).

### 11. Everything is tappable-sized and accessible
Tap targets at least 40px (buttons default to 40, pills 44 in dialogs). Text
must stay readable at large system font sizes: use `Expanded`/`Flexible` and
ellipsis for titles, never fixed-width text boxes. Provide `Semantics` or a
`tooltip` on icon-only buttons. Do not rely on colour alone for state; pair it
with an icon or a label.

### 12. Respect the audience split
The **caregiver** app is dense but calm and uses the standard ladder above. The
**elderly/patient** interface is deliberately large, high-contrast and simple
(its own scale in `alera_elderly_theme.dart`). Do not leak one into the other.
Shared tokens (colours, `AleraLoader`, icons) still apply to both.

---

## Part 2: The Guide

### Colour tokens (`lib/design_system/alera_colors.dart`)

| Token | Hex | Use |
|---|---|---|
| `primary` / `primaryMid` / `selected` | `#AE8BEA` | Buttons, links, focus, active tab, accents |
| `primaryLight` | `#C3A7F5` | Home header gradient, status bar |
| `primaryPressed` | `#7449C9` | Pressed state of primary buttons |
| `primarySoft` | `#E8DDFB` | Soft purple fills, label pills, selected filter |
| `background` | `#F7F4FF` | Page background |
| `surface` | white | Cards |
| `surfaceTint` | `#F8F5FE` | Selected option, tinted card |
| `textPrimary` / `textSecondary` | `#3D3459` / `#71698D` | Titles / supporting text |
| `mutedIcon` / `mutedChevron` | `#B4AEC2` / `#B7B2C3` | Chevrons, back arrows, meta icons |
| `fieldFill` / `fieldBorder` / `fieldHint` | `#F7F3FF` / `#E0D6F5` / `#B5A6DB` | Text inputs |
| `divider` | `#EDE8F7` | Hairlines |
| `success` / `successStrong` | `#08D887` / `#05A869` | Done; strong for text on tint |
| `warning` / `warningStrong` / `warningSoft` | `#FFBE18` / `#D99A00` / `#FFF1CC` | Caution |
| `critical` / `criticalStrong` | `#FF6474` / `#E04C5D` | Missed, urgent, destructive |
| `information` | `#55A5FF` | Neutral info |
| `faintIcon`, `emptyTitle`, `shadowTint` | | Empty states, soft shadow tint |

Rule of thumb: if you reach for a hex, you are in the wrong file.

### Spacing and shape
`AleraSpacing`: `xSmall` 4, `small` 8, `medium` 16, `large` 24, `xLarge` 32.
Radii: `radiusSmall` 8, `cardRadius` 12, `radiusLarge` 20, `radiusPill` 999.
Default card padding is `medium` (16); compact rows use 12.

### Components to reach for first

| Need | Use |
|---|---|
| Card | `AleraCard` (white, soft shadow, no border) |
| Grouped list with a label | `AleraSectionCard` / the More page's `_GroupLabel` + `_GroupCard` |
| Button | `AleraButton` (`primary`, `secondary`, `pill`, `lightPill`, `destructivePill`) |
| Pill / filter / status badge | `AleraPill` (`action`, `filter`, `label`), `AleraStatusChip` |
| Text field | `AleraTextField` / `aleraInputDecoration` |
| Toast | `showAleraSnackBar` (+ `showAleraSnackBarOn` after an `await`) |
| Dialog | `AleraDialog` (`showCancel: false` for acknowledge-only), `showAleraConfirmDialog` |
| Loading | `AleraLoader`, `alera_skeleton`, `AleraRefreshIndicator` |
| Empty state | `AleraEmptyState` |
| App bar | `CaregiverPageAppBar`, `AleraChevronAppBar`, `AleraBackButton` |
| Icon | `AleraSvgIcon` (Figma set) or a filled `Icons.*` |
| Avatar | `AleraPatientAvatar` |
| Sign out | `runAleraSignOutFlow` |

### Reminders: the reference pattern
Every reminder, anywhere, follows one structure:
1. Category **icon tile** (category tile colour) + **title** (`rowTitle`) +
   **subtitle** (`caption`, `textSecondary`).
2. A **meta row**: clock icon + time, optional repeat icon + label. Icons
   `mutedIcon`, text `textSecondary`, same on every category.
3. A **status pill** (`AleraPill.label`) only when the state is notable:
   missed, snoozed, canceled, completed late (and Missed/Completed on compact
   rows).
4. Card background: category wash; missed gets a faint critical wash; canceled
   is white with a strikethrough title; completed is dimmed.
5. Trailing: a complete check, or a grey chevron.

The **detail page** is a header card (icon, title, category, status), then
Details, Instructions and a Timeline card, then the action buttons. The timeline
(alert-style) is dot + connector, time on the left, bold label, "date · actor".

### Navigation
- Bottom `NavigationBar`: outline icon idle, filled icon selected, label always
  shown, selected colour `selected`.
- Sub-pages use a bare grey chevron back button with the title beside it. No
  extra "Back" text.
- The More page is grouped: **Care** (patients, help-request history),
  **App** (reminder sound, settings), then a separate **Sign out** row.

### Writing the copy
Plain, warm, short. Sentences, not codes. Sentence case ("Add note", not "Add
Note"). Say what happened and what to do next ("Unable to clear saved sign-in.
Please try signing out again."). Empty states reassure ("No active alerts").
Use the person's name or relationship, not "the patient", where we have it.

### Motion
Subtle: standard Material transitions, the shared sheet animation
(`alera_sheet_animation.dart`), no bouncing or attention-grabbing loops. Spinners
only while genuinely waiting.

### Checklist before opening a PR
- [ ] No literal colours, radii, font sizes, spinners, snackbars, dialogs or chips
- [ ] Meta icons grey; category colour only on tile/wash/icon
- [ ] Chevrons grey `chevron_right` / `expand_more`; back is `AleraBackButton`
- [ ] Icons filled (or Figma / `status/error.svg` placeholder)
- [ ] The same object looks the same as on its other screens
- [ ] Long text ellipsises; large fonts do not overflow; tap targets >= 40px
- [ ] `dart format`, `flutter analyze` clean, `flutter test` green
- [ ] Docs updated if a token or component was added

### Known open items (not yet consistent)
- Some Figma icons are missing; placeholders are in use.
- The elderly interface keeps its own radii, type scale and a few hard-coded
  colours.
- Per-metric colours (vitals charts, vital summary) are intentionally outside
  the status palette.
- Roughly 60 one-off raw `TextStyle`s remain with unique size/weight/colour
  combinations.
