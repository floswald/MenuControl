import SwiftUI
import MenuControlCore

/// The at-the-table screen: tap whatever's actually on the tray today,
/// watch the running carb total, then log it. (specs.md §3.)
public struct TraySelectionView: View {
    @ObservedObject private var viewModel: TraySelectionViewModel
    private let onLog: (MealLogEntry) -> Void

    public init(viewModel: TraySelectionViewModel, onLog: @escaping (MealLogEntry) -> Void) {
        self.viewModel = viewModel
        self.onLog = onLog
    }

    public var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.categories(), id: \.self) { category in
                    Section(category.displayName) {
                        ForEach(viewModel.catalog.dishes(inCategory: category)) { dish in
                            DishToggleRow(
                                dish: dish,
                                isSelected: viewModel.isSelected(dish),
                                action: { viewModel.toggle(dish) }
                            )
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif

            TotalCarbsFooter(
                totalCarbsG: viewModel.totalCarbsG,
                itemCount: viewModel.selectedDishes.count,
                onLog: {
                    guard let entry = viewModel.makeLogEntry() else { return }
                    onLog(entry)
                    viewModel.clearSelection()
                }
            )
        }
        .navigationTitle("Il vassoio di oggi")
    }
}

private struct DishToggleRow: View {
    let dish: Dish
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading) {
                    Text(dish.name)
                        .foregroundStyle(.primary)
                    Text("\(dish.carbsG.formatted(.number.precision(.fractionLength(0)))) g carboidrati")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct TotalCarbsFooter: View {
    let totalCarbsG: Double
    let itemCount: Int
    let onLog: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Totale carboidrati")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalCarbsG.formatted(.number.precision(.fractionLength(0)))) g")
                        .font(.title2.bold())
                }
                Spacer()
                Button("Registra pasto", action: onLog)
                    .buttonStyle(.borderedProminent)
                    .disabled(itemCount == 0)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }
}

private extension String {
    /// Turns the raw category keys from the catalog JSON (e.g. "primi_piatti")
    /// into something readable in the UI.
    var displayName: String {
        switch self {
        case "primi_piatti": return "Primi"
        case "secondi_piatti": return "Secondi"
        case "contorni": return "Contorni"
        case "frutta_fresca": return "Frutta"
        case "pane": return "Pane"
        case "dessert": return "Dessert"
        default: return self.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
