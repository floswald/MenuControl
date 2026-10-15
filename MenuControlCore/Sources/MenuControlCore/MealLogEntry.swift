import Foundation

/// A snapshot of catalog values at log time (catalog may change later; the log
/// stays historically accurate) — per specs.md §4 "Meal log entry".
public struct MealLogItem: Codable, Equatable, Hashable, Sendable {
    public let name: String
    public let carbsG: Double

    enum CodingKeys: String, CodingKey {
        case name
        case carbsG = "carbs_g"
    }

    public init(name: String, carbsG: Double) {
        self.name = name
        self.carbsG = carbsG
    }

    public init(dish: Dish) {
        self.name = dish.name
        self.carbsG = dish.carbsG
    }
}

public struct MealLogEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let items: [MealLogItem]

    public var totalCarbsG: Double {
        items.reduce(0) { $0 + $1.carbsG }
    }

    public init(id: UUID = UUID(), timestamp: Date = Date(), items: [MealLogItem]) {
        self.id = id
        self.timestamp = timestamp
        self.items = items
    }

    // `id` is local-only (list identity in the app); it is not part of the
    // DiabetesControl interchange schema, so it's excluded from JSON coding.
    enum CodingKeys: String, CodingKey {
        case timestamp
        case items
        case totalCarbsG = "total_carbs_g"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.items = try container.decode([MealLogItem].self, forKey: .items)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(items, forKey: .items)
        try container.encode(totalCarbsG, forKey: .totalCarbsG)
    }
}

/// Encodes/decodes MealLogEntry using the exact wire format from specs.md §5
/// (ISO 8601 local-time timestamp, `carbs_g`, `total_carbs_g`), for exporting
/// to DiabetesControl's data pipeline.
public enum MealLogCoding {
    private static let localFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, enc in
            var container = enc.singleValueContainer()
            // specs.md §5 uses naive local timestamps like "2026-10-15T12:35:00"
            // (no "Z", no UTC offset) — must match makeDecoder()'s format exactly.
            try container.encode(Self.localFormatter.string(from: date))
        }
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = Self.localFormatter.date(from: raw) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Unrecognized date format: \(raw)"
                )
            }
            return date
        }
        return decoder
    }
}
