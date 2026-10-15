import XCTest
@testable import MenuControlUI
import MenuControlCore

@MainActor
final class MealLogStoreTests: XCTestCase {
    func testLoadPopulatesFromPersistence() async {
        let seed = [MealLogEntry(items: [MealLogItem(name: "Mela", carbsG: 20)])]
        let persistence = InMemoryMealLogPersistence(seed: seed)
        let store = MealLogStore(persistence: persistence)

        await store.load()

        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.totalCarbsG, 20)
    }

    func testAddPersistsAndSortsNewestFirst() async {
        let older = MealLogEntry(timestamp: Date(timeIntervalSince1970: 1000), items: [])
        let persistence = InMemoryMealLogPersistence(seed: [older])
        let store = MealLogStore(persistence: persistence)
        await store.load()

        let newer = MealLogEntry(timestamp: Date(timeIntervalSince1970: 2000), items: [])
        await store.add(newer)

        XCTAssertEqual(store.entries.map(\.timestamp), [newer.timestamp, older.timestamp])
    }

    func testExportJSONMatchesEncoder() throws {
        let store = MealLogStore(persistence: InMemoryMealLogPersistence())
        let entry = MealLogEntry(items: [MealLogItem(name: "Mela", carbsG: 20)])

        let data = try store.exportJSON(entry)
        let decoded = try MealLogCoding.makeDecoder().decode(MealLogEntry.self, from: data)

        XCTAssertEqual(decoded.items, entry.items)
    }
}

final class FileMealLogPersistenceTests: XCTestCase {
    func testRoundTripsThroughDisk() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("meal_log_test_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let persistence = FileMealLogPersistence(fileURL: fileURL)
        let empty = try await persistence.loadAll()
        XCTAssertEqual(empty, [])

        let entries = [MealLogEntry(items: [MealLogItem(name: "Pasta al pomodoro", carbsG: 45)])]
        try await persistence.saveAll(entries)

        let reloaded = try await persistence.loadAll()
        XCTAssertEqual(reloaded.map(\.items), entries.map(\.items))
    }
}
