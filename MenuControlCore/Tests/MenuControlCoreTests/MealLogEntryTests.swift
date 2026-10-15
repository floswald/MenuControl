import XCTest
@testable import MenuControlCore

final class MealLogEntryTests: XCTestCase {
    func testTotalCarbsSumsItems() {
        let entry = MealLogEntry(items: [
            MealLogItem(name: "Pasta al pomodoro", carbsG: 45),
            MealLogItem(name: "Mela", carbsG: 20),
        ])
        XCTAssertEqual(entry.totalCarbsG, 65)
    }

    func testTotalCarbsIsZeroForEmptyTray() {
        let entry = MealLogEntry(items: [])
        XCTAssertEqual(entry.totalCarbsG, 0)
    }

    func testItemFromDishCopiesNameAndCarbs() {
        let dish = Dish(name: "Riso all'olio", carbsG: 72, category: "primi_piatti")
        let item = MealLogItem(dish: dish)
        XCTAssertEqual(item.name, "Riso all'olio")
        XCTAssertEqual(item.carbsG, 72)
    }

    /// Matches the exact interchange schema in specs.md §5, for export into
    /// DiabetesControl's data/raw convention.
    func testEncodesSpecSchema() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 15
        components.hour = 12
        components.minute = 35
        components.second = 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let date = try XCTUnwrap(calendar.date(from: components))

        let entry = MealLogEntry(timestamp: date, items: [
            MealLogItem(name: "Pasta al pomodoro", carbsG: 45),
            MealLogItem(name: "Mela", carbsG: 20),
        ])

        let data = try MealLogCoding.makeEncoder().encode(entry)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["total_carbs_g"] as? Double, 65)
        let items = try XCTUnwrap(json["items"] as? [[String: Any]])
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0]["name"] as? String, "Pasta al pomodoro")
        XCTAssertEqual(items[0]["carbs_g"] as? Double, 45)
        XCTAssertEqual(json["timestamp"] as? String, "2026-10-15T12:35:00")
    }

    func testRoundTripThroughSpecSchema() throws {
        let original = MealLogEntry(items: [
            MealLogItem(name: "Pasta al pomodoro", carbsG: 45),
            MealLogItem(name: "Mela", carbsG: 20),
        ])

        let data = try MealLogCoding.makeEncoder().encode(original)
        let decoded = try MealLogCoding.makeDecoder().decode(MealLogEntry.self, from: data)

        XCTAssertEqual(decoded.items, original.items)
        XCTAssertEqual(decoded.totalCarbsG, original.totalCarbsG)
        // Round-trip through a seconds-precision string, so compare at that granularity.
        XCTAssertEqual(
            decoded.timestamp.timeIntervalSince1970,
            original.timestamp.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testDecodeRejectsMalformedTimestamp() {
        let json = """
        {"timestamp": "not-a-date", "items": [], "total_carbs_g": 0}
        """
        let data = Data(json.utf8)
        XCTAssertThrowsError(try MealLogCoding.makeDecoder().decode(MealLogEntry.self, from: data))
    }
}
