import Foundation

/// The editable, pre-loaded set of dishes Elena can pick from at the table.
public struct MenuCatalog: Sendable {
    public private(set) var dishes: [Dish]

    public init(dishes: [Dish]) {
        self.dishes = dishes
    }

    /// Lookup is by dish name (the join key between "what's on the tray today"
    /// and "what carbs that dish has"), matching how specs.md describes picking
    /// items at the table regardless of which day's published menu was followed.
    public func dish(named name: String) -> Dish? {
        dishes.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    public func dishes(inCategory category: String) -> [Dish] {
        dishes.filter { $0.category == category }
    }

    public mutating func add(_ dish: Dish) {
        dishes.append(dish)
    }

    public mutating func remove(id: Dish.ID) {
        dishes.removeAll { $0.id == id }
    }
}
