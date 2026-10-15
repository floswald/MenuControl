#!/usr/bin/env python3
"""
Computes total carbs per dish (by age group) from data/grammature_estate_2026.json
ingredient grams and data/ingredient_carbs_per_100g.json reference values.

Writes data/menu_catalog_carbs.json in the Menu catalog shape from specs.md:
one entry per dish, carbs_g per age group, category.
"""
import json
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
AGE_GROUPS = ["infanzia", "primaria", "secondaria_adulti"]


def load_json(name):
    with open(DATA_DIR / name, encoding="utf-8") as f:
        return json.load(f)


def dish_carbs(dish, carb_table):
    totals = {g: 0.0 for g in AGE_GROUPS}
    missing = []
    for ing in dish["ingredients"]:
        name = ing["name"]
        carbs_per_100g = carb_table.get(name)
        if carbs_per_100g is None:
            missing.append(name)
            continue
        for g in AGE_GROUPS:
            grams = ing.get(g)
            if isinstance(grams, (int, float)):
                totals[g] += grams * carbs_per_100g / 100
    return {g: round(v, 1) for g, v in totals.items()}, missing


def main():
    grammature = load_json("grammature_estate_2026.json")
    carb_table = load_json("ingredient_carbs_per_100g.json")["values"]

    categories = grammature["categories"]
    catalog = []
    all_missing = set()

    for cat_key in ["primi_piatti", "secondi_piatti", "contorni"]:
        for dish in categories.get(cat_key, []):
            carbs, missing = dish_carbs(dish, carb_table)
            all_missing.update(missing)
            catalog.append({
                "name": dish["dish"],
                "category": cat_key,
                "carbs_g": carbs,
            })

    # simple non-recipe items with flat per-age-group grams (pane, dessert)
    for cat_key in ["pane", "dessert"]:
        for item in categories.get(cat_key, []):
            name = item["name"]
            carbs_per_100g = carb_table.get(name)
            if carbs_per_100g is None:
                all_missing.add(name)
                continue
            carbs = {g: round(item.get(g, 0) * carbs_per_100g / 100, 1) for g in AGE_GROUPS}
            catalog.append({"name": name, "category": cat_key, "carbs_g": carbs})

    # fresh fruit: edible (netto) grams = first number in "a/b" range
    for item in categories.get("frutta_fresca", {}).get("items", []):
        name = item["name"]
        carbs_per_100g = carb_table.get(name)
        if carbs_per_100g is None:
            all_missing.add(name)
            continue
        carbs = {}
        for g in AGE_GROUPS:
            key = f"{g}_g"
            raw = item.get(key, "")
            netto = float(raw.split("/")[0]) if "/" in raw else None
            carbs[g] = round(netto * carbs_per_100g / 100, 1) if netto else None
        catalog.append({"name": name, "category": "frutta_fresca", "carbs_g": carbs})

    out = {
        "_source": "Computed from data/grammature_estate_2026.json x data/ingredient_carbs_per_100g.json. Approximate reference values, not lab-measured — see ingredient_carbs_per_100g.json _note.",
        "dishes": catalog,
    }

    with open(DATA_DIR / "menu_catalog_carbs.json", "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2, ensure_ascii=False)

    print(f"Wrote {len(catalog)} dishes to menu_catalog_carbs.json")
    if all_missing:
        print("Missing ingredient carb values (treated as 0):")
        for m in sorted(all_missing):
            print(f"  - {m}")


if __name__ == "__main__":
    main()
