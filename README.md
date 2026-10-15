# MenuControl

iOS/web companion app for estimating carbohydrate intake at school lunch,
for a T1D patient who doesn't know in advance exactly what will be on her
tray. See [specs.md](specs.md) for the full design doc.

Elena picks, at the table, which items from a pre-loaded menu catalog are
actually on her tray that day; the app sums carbs for just those items and
keeps a log for cross-checking against
[DiabetesControl](https://github.com/)'s `Bolus.csv` carb entries.

## Live app

**https://floswald.github.io/MenuControl/** — open in Safari on her iPhone,
tap Share → **Add to Home Screen**. Works offline after first load, no
Apple Developer account needed (see "Two implementations" below for why).

## Data pipeline

The menu catalog comes from Milano Ristorazione's published school menus
(Moisè Loria / Scuola Secondaria, Estate 2026 term):

```
data/Grammature_al_crudo_Scuole_Estate_2026.pdf   — official PDF, raw ingredient grams per dish
        ↓ (manually transcribed)
data/grammature_estate_2026.json                   — structured: dish → ingredients → grams, by age group
        ↓
data/ingredient_carbs_per_100g.json                — CREA/INRAN-style reference table (g carbs per 100g)
        ↓ scripts/compute_dish_carbs.py
data/menu_catalog_carbs.json                       — final catalog: dish → carbs_g, by age group
```

Re-run the computation after editing either input:

```
python3 scripts/compute_dish_carbs.py
```

This writes `data/menu_catalog_carbs.json`, which both app versions bundle
directly (`MenuControlCore/Sources/MenuControlCore/Resources/` and
`web/data/`) — copy it to both places after regenerating.

**Caveat:** the catalog is a *lookup table* of all dishes the caterer might
serve this term, not tied to any single day's published schedule — the
whole point is that the caterer doesn't always serve what's scheduled, so
Elena looks up whatever's actually in front of her by name. Carb values
are reference estimates (not lab-measured for these specific suppliers);
treat as approximate.

The age group used for carb totals is `secondaria_adulti` (her school
level — larger portions than `infanzia`/`primaria`).

## Two implementations

| | `web/` (PWA) | `MenuControlCore` + Xcode (native) |
|---|---|---|
| Install | Safari → Add to Home Screen | Xcode → device, needs re-signing every 7 days on a free Apple ID (or $99/yr dev account) |
| Logic | vanilla JS, mirrors the Swift package | Swift, unit-tested |
| Persistence | `localStorage` | JSON file in app Documents |
| Status | **primary, in daily use** | kept for future native-only features (Shortcuts integration, etc.) |

Both read the same `menu_catalog_carbs.json` and write/read the same JSON
meal-log schema (see specs.md §5), so a log entry means the same thing in
either.

## Repo layout

```
specs.md                   — design doc
data/                       — menu source PDF + computed catalog JSON
scripts/compute_dish_carbs.py
MenuControlCore/            — Swift package: models, carb logic, SwiftUI views, tests
  Sources/MenuControlCore/    — Dish, MenuCatalog, CatalogLoader, MealLogEntry
  Sources/MenuControlUI/      — TraySelectionView, MealLogHistoryView, view models
  Tests/
MenuControl/                — Xcode project (app target wrapping MenuControlCore)
web/                         — PWA: index.html, app.js, style.css, service worker
.github/workflows/pages.yml — deploys web/ to GitHub Pages on push to main
```

## Development

Swift package tests (requires full Xcode installed, not just Command Line
Tools — `xcode-select -s /Applications/Xcode.app/Contents/Developer`):

```
cd MenuControlCore && swift test
```

PWA local testing:

```
cd web && python3 -m http.server 8765
# open http://localhost:8765/ in a browser
```
