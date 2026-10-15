// MenuControl PWA — mirrors MenuControlCore's logic (Dish, MenuCatalog,
// TraySelectionViewModel, MealLogStore) in vanilla JS, reusing the same
// data/menu_catalog_carbs.json catalog. No build step, no framework.

const AGE_GROUP = "secondaria_adulti"; // Elena's school level — see specs.md
const STORAGE_KEY = "menucontrol.mealLog.v1";

const CATEGORY_NAMES = {
  primi_piatti: "Primi",
  secondi_piatti: "Secondi",
  contorni: "Contorni",
  frutta_fresca: "Frutta",
  pane: "Pane",
  dessert: "Dessert",
};

let catalog = []; // [{id, name, carbsG, category}]
let selectedIds = new Set();
let entries = []; // meal log, newest first

// ---------- catalog loading ----------

async function loadCatalog() {
  const res = await fetch("data/menu_catalog_carbs.json");
  const json = await res.json();
  catalog = json.dishes
    .filter((d) => d.carbs_g[AGE_GROUP] !== null && d.carbs_g[AGE_GROUP] !== undefined)
    .map((d, i) => ({
      id: `${d.category}:${d.name}:${i}`,
      name: d.name,
      carbsG: d.carbs_g[AGE_GROUP],
      category: d.category,
    }));
}

function categoriesInOrder() {
  const seen = new Set();
  const ordered = [];
  for (const dish of catalog) {
    if (!seen.has(dish.category)) {
      seen.add(dish.category);
      ordered.push(dish.category);
    }
  }
  return ordered;
}

// ---------- selection / totals ----------

function toggle(dishId) {
  if (selectedIds.has(dishId)) {
    selectedIds.delete(dishId);
  } else {
    selectedIds.add(dishId);
  }
  renderTray();
}

function selectedDishes() {
  return catalog.filter((d) => selectedIds.has(d.id));
}

function totalCarbsG() {
  return selectedDishes().reduce((sum, d) => sum + d.carbsG, 0);
}

function clearSelection() {
  selectedIds.clear();
}

// ---------- meal log (persisted) ----------

function loadEntries() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    entries = raw ? JSON.parse(raw) : [];
  } catch {
    entries = [];
  }
}

function saveEntries() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
}

// Local naive timestamp "yyyy-MM-ddTHH:mm:ss" (no offset), matching
// specs.md §5 and MealLogCoding in the Swift package.
function localTimestamp(date) {
  const pad = (n) => String(n).padStart(2, "0");
  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
  );
}

function logCurrentSelection() {
  const dishes = selectedDishes();
  if (dishes.length === 0) return;

  const items = dishes.map((d) => ({ name: d.name, carbs_g: d.carbsG }));
  const total_carbs_g = items.reduce((sum, it) => sum + it.carbs_g, 0);
  const entry = {
    timestamp: localTimestamp(new Date()),
    items,
    total_carbs_g,
  };

  entries.unshift(entry); // newest first
  saveEntries();
  clearSelection();
  renderTray();
  renderHistory();
}

// ---------- rendering ----------

function renderTray() {
  const container = document.getElementById("catalog-list");
  container.innerHTML = "";

  for (const category of categoriesInOrder()) {
    const section = document.createElement("div");
    section.className = "category-section";

    const title = document.createElement("div");
    title.className = "category-title";
    title.textContent = CATEGORY_NAMES[category] || category;
    section.appendChild(title);

    const card = document.createElement("div");
    card.className = "category-card";

    for (const dish of catalog.filter((d) => d.category === category)) {
      const row = document.createElement("div");
      row.className = "dish-row" + (selectedIds.has(dish.id) ? " selected" : "");
      row.innerHTML = `
        <div class="checkbox">${selectedIds.has(dish.id) ? "✓" : ""}</div>
        <div class="dish-info">
          <div class="dish-name">${escapeHtml(dish.name)}</div>
          <div class="dish-carbs">${Math.round(dish.carbsG)} g carboidrati</div>
        </div>`;
      row.addEventListener("click", () => toggle(dish.id));
      card.appendChild(row);
    }

    section.appendChild(card);
    container.appendChild(section);
  }

  document.getElementById("total-carbs").textContent = Math.round(totalCarbsG());
  document.getElementById("log-button").disabled = selectedIds.size === 0;
}

function renderHistory() {
  const list = document.getElementById("history-list");
  const empty = document.getElementById("history-empty");
  list.innerHTML = "";

  if (entries.length === 0) {
    empty.classList.remove("hidden");
    return;
  }
  empty.classList.add("hidden");

  for (const entry of entries) {
    const [datePart, timePart] = entry.timestamp.split("T");
    const el = document.createElement("div");
    el.className = "history-entry";
    el.innerHTML = `
      <div class="row">
        <span><span class="date">${datePart}</span><span class="time">${timePart.slice(0, 5)}</span></span>
        <span class="total">${Math.round(entry.total_carbs_g)} g</span>
      </div>
      <div class="items">${entry.items.map((i) => escapeHtml(i.name)).join(", ")}</div>`;
    list.appendChild(el);
  }
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

// ---------- tabs ----------

function showTab(tab) {
  const isTray = tab === "tray";
  document.getElementById("tray-screen").classList.toggle("hidden", !isTray);
  document.getElementById("history-screen").classList.toggle("hidden", isTray);
  document.getElementById("tray-footer").classList.toggle("hidden", !isTray);
  document.getElementById("screen-title").textContent = isTray ? "Il vassoio di oggi" : "Storico pasti";
  document.querySelectorAll(".tab-button").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.tab === tab);
  });
}

// ---------- init ----------

async function init() {
  loadEntries();
  await loadCatalog();
  renderTray();
  renderHistory();

  document.getElementById("log-button").addEventListener("click", logCurrentSelection);
  document.querySelectorAll(".tab-button").forEach((btn) => {
    btn.addEventListener("click", () => showTab(btn.dataset.tab));
  });

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
}

init();
