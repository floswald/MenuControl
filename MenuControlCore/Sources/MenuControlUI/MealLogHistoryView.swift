import SwiftUI
import MenuControlCore

/// Past logged meals — for cross-checking against DiabetesControl's Bolus.csv
/// carb entries later (specs.md §3).
public struct MealLogHistoryView: View {
    @ObservedObject private var store: MealLogStore

    public init(store: MealLogStore) {
        self.store = store
    }

    public var body: some View {
        List(store.entries) { entry in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.timestamp, style: .date)
                    Text(entry.timestamp, style: .time)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.totalCarbsG.formatted(.number.precision(.fractionLength(0)))) g")
                        .font(.headline)
                }
                Text(entry.items.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .overlay {
            if store.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Nessun pasto registrato")
                        .font(.headline)
                    Text("I pasti registrati compariranno qui.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Storico pasti")
        .task { await store.load() }
    }
}
