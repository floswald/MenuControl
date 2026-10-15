# MenuControl — Project Specs

## 1. Title
**MenuControl**

## 2. Purpose
iOS app to estimate total carbohydrate intake for a meal (primarily school lunch) when the exact dish composition isn't known in advance. Elena (T1D patient) picks, at the table, which items from a pre-loaded menu are actually on her tray; the app sums carbs for just those items. Companion to [DiabetesControl](https://github.com/) (sibling repo `~/git/DiabetesControl`), which models insulin dosing from pump/CGM data — this app is the missing food-intake input for days without a Bolus.csv carb entry, or for cross-checking what was logged at bolus time against what was actually eaten.

## 3. Use Cases

- Parent/caregiver pre-loads a week's school menu (dish names + carb counts) ahead of time, sourced from the school's published menu.
- At lunch, Elena (or caregiver) opens the app, taps the specific dishes on her tray that day (composition/portions not always exactly as published), app totals carbs instantly.
- Resulting meal log (items + total carbs + timestamp) is available to inform a manual bolus carb entry on the pump, and/or exported for later cross-reference against `DiabetesControl`'s ingested `Bolus.csv` carb sizes.

## 4. Data Model

### Menu catalog (pre-loaded, editable)

One entry per dish:

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `name` | string | e.g. "Pasta al pomodoro" |
| `carbs_g` | float | carbs per standard school-serving portion |
| `category` | string | optional grouping, e.g. "primo", "secondo", "contorno", "frutta" |
| `active_from` / `active_until` | date, optional | for menus that rotate termly |

Carb count is a single point estimate per dish (the school serving is fairly standardized) — portion-size override is a stretch goal, not v1.

### Meal log entry (one per tray, created at the table)
| Field | Type | Notes |
|---|---|---|
| `timestamp` | ISO 8601, local time | when logged |
| `items` | list of `{name, carbs_g}` | snapshot of catalog values at log time (catalog may change later; log stays historically accurate) |
| `total_carbs_g` | float | sum of `items[].carbs_g` |

## 5. Interchange with DiabetesControl
Meal logs export as JSON, one file per meal or a rolling log file — exact transport TBD (iCloud Drive file, Shortcuts automation, or manual export + copy into `DiabetesControl/data/raw` convention). Schema:

```json
{
  "timestamp": "2026-10-15T12:35:00",
  "items": [
    {"name": "Pasta al pomodoro", "carbs_g": 45},
    {"name": "Mela", "carbs_g": 20}
  ],
  "total_carbs_g": 65
}
```

This is intentionally decoupled from the pump's own `Bolus.csv` `Carb Size` field — the two are reconciled downstream in `DiabetesControl`, not merged at the source.

## 6. Open Design Questions

- Transport mechanism for getting meal logs from the phone into `DiabetesControl`'s data pipeline (manual export vs. automatic sync).
- Menu entry workflow: manual typing each week vs. parsing a photo/PDF of the school's published menu (OCR/LLM-assisted extraction) vs. a simple spreadsheet import.
- Whether to support portion-size scaling (half portion, double portion) in v1 or defer.
- Local-only storage (no account/cloud) vs. iCloud sync if multiple caregivers need to log meals.
- Platform/framework: SwiftUI native app assumed; confirm minimum iOS version target.
