import SwiftUI
import MenuControlCore

/// Wires the tray-selection screen and meal-log history into one tab view.
/// This is the one thing the eventual Xcode App target needs to instantiate
/// (see App/MenuControlApp.swift for the @main wrapper).
public struct MenuControlRootView: View {
    @StateObject private var traySelection: TraySelectionViewModel
    @StateObject private var logStore: MealLogStore

    public init(catalog: MenuCatalog, persistence: MealLogPersisting) {
        _traySelection = StateObject(wrappedValue: TraySelectionViewModel(catalog: catalog))
        _logStore = StateObject(wrappedValue: MealLogStore(persistence: persistence))
    }

    public var body: some View {
        TabView {
            NavigationStack {
                TraySelectionView(viewModel: traySelection) { entry in
                    Task { await logStore.add(entry) }
                }
            }
            .tabItem { Label("Vassoio", systemImage: "fork.knife.circle") }

            NavigationStack {
                MealLogHistoryView(store: logStore)
            }
            .tabItem { Label("Storico", systemImage: "clock") }
        }
    }
}
