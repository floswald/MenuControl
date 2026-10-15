import Foundation
import MenuControlCore

/// Drives the "pick what's actually on the tray" screen (specs.md §3 use case).
/// Kept separate from SwiftUI `View` bodies so the selection/total logic is
/// unit-testable without rendering anything.
@MainActor
public final class TraySelectionViewModel: ObservableObject {
    @Published public private(set) var catalog: MenuCatalog
    @Published public private(set) var selectedDishIDs: Set<Dish.ID> = []

    public init(catalog: MenuCatalog) {
        self.catalog = catalog
    }

    public var selectedDishes: [Dish] {
        catalog.dishes.filter { selectedDishIDs.contains($0.id) }
    }

    public var totalCarbsG: Double {
        selectedDishes.reduce(0) { $0 + $1.carbsG }
    }

    public func isSelected(_ dish: Dish) -> Bool {
        selectedDishIDs.contains(dish.id)
    }

    public func toggle(_ dish: Dish) {
        if selectedDishIDs.contains(dish.id) {
            selectedDishIDs.remove(dish.id)
        } else {
            selectedDishIDs.insert(dish.id)
        }
    }

    public func clearSelection() {
        selectedDishIDs.removeAll()
    }

    /// Snapshots the current selection into a loggable entry, per specs.md §4
    /// (the log keeps catalog values at log time, independent of later catalog edits).
    public func makeLogEntry(timestamp: Date = Date()) -> MealLogEntry? {
        guard !selectedDishIDs.isEmpty else { return nil }
        let items = selectedDishes.map(MealLogItem.init(dish:))
        return MealLogEntry(timestamp: timestamp, items: items)
    }

    public func categories() -> [String] {
        let known = catalog.dishes.compactMap(\.category)
        var seen = Set<String>()
        var ordered: [String] = []
        for category in known where seen.insert(category).inserted {
            ordered.append(category)
        }
        return ordered
    }
}
