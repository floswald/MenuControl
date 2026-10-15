import Foundation

/// A single dish in the pre-loaded menu catalog, per specs.md §4 "Menu catalog".
public struct Dish: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let carbsG: Double
    public let category: String?
    public let activeFrom: Date?
    public let activeUntil: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        carbsG: Double,
        category: String? = nil,
        activeFrom: Date? = nil,
        activeUntil: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.carbsG = carbsG
        self.category = category
        self.activeFrom = activeFrom
        self.activeUntil = activeUntil
    }
}
