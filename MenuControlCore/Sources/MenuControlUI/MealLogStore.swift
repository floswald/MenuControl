import Foundation
import MenuControlCore

/// Swappable persistence so tests can use an in-memory stand-in instead of disk.
public protocol MealLogPersisting: Sendable {
    func loadAll() async throws -> [MealLogEntry]
    func saveAll(_ entries: [MealLogEntry]) async throws
}

/// One JSON array file in the app's Documents directory. Simple on purpose —
/// meal-log volume is a handful of entries a day, not a dataset.
public struct FileMealLogPersistence: MealLogPersisting {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func loadAll() async throws -> [MealLogEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try MealLogCoding.makeDecoder().decode([MealLogEntry].self, from: data)
    }

    public func saveAll(_ entries: [MealLogEntry]) async throws {
        let data = try MealLogCoding.makeEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// In-memory persistence, for previews and tests.
public actor InMemoryMealLogPersistence: MealLogPersisting {
    private var stored: [MealLogEntry]

    public init(seed: [MealLogEntry] = []) {
        self.stored = seed
    }

    public func loadAll() throws -> [MealLogEntry] { stored }
    public func saveAll(_ entries: [MealLogEntry]) throws { stored = entries }
}

@MainActor
public final class MealLogStore: ObservableObject {
    @Published public private(set) var entries: [MealLogEntry] = []
    @Published public private(set) var lastError: Error?

    private let persistence: MealLogPersisting

    public init(persistence: MealLogPersisting) {
        self.persistence = persistence
    }

    public func load() async {
        do {
            entries = try await persistence.loadAll().sorted { $0.timestamp > $1.timestamp }
        } catch {
            lastError = error
        }
    }

    public func add(_ entry: MealLogEntry) async {
        var updated = entries
        updated.append(entry)
        do {
            try await persistence.saveAll(updated)
            entries = updated.sorted { $0.timestamp > $1.timestamp }
        } catch {
            lastError = error
        }
    }

    public func exportJSON(_ entry: MealLogEntry) throws -> Data {
        try MealLogCoding.makeEncoder().encode(entry)
    }
}
