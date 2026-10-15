import XCTest
@testable import MenuControlUI
import MenuControlCore

@MainActor
final class TraySelectionViewModelTests: XCTestCase {
    private func makeCatalog() -> MenuCatalog {
        MenuCatalog(dishes: [
            Dish(name: "Pasta al pomodoro", carbsG: 45, category: "primi_piatti"),
            Dish(name: "Mela", carbsG: 20, category: "frutta_fresca"),
            Dish(name: "Bocconcini di tacchino", carbsG: 6, category: "secondi_piatti"),
        ])
    }

    func testTogglingSelectsAndDeselects() {
        let viewModel = TraySelectionViewModel(catalog: makeCatalog())
        let dish = viewModel.catalog.dishes[0]

        XCTAssertFalse(viewModel.isSelected(dish))
        viewModel.toggle(dish)
        XCTAssertTrue(viewModel.isSelected(dish))
        viewModel.toggle(dish)
        XCTAssertFalse(viewModel.isSelected(dish))
    }

    func testTotalCarbsSumsSelectedDishesOnly() {
        let viewModel = TraySelectionViewModel(catalog: makeCatalog())
        let pasta = viewModel.catalog.dishes[0]
        let mela = viewModel.catalog.dishes[1]

        viewModel.toggle(pasta)
        viewModel.toggle(mela)

        XCTAssertEqual(viewModel.totalCarbsG, 65)
    }

    func testMakeLogEntryReturnsNilWhenNothingSelected() {
        let viewModel = TraySelectionViewModel(catalog: makeCatalog())
        XCTAssertNil(viewModel.makeLogEntry())
    }

    func testMakeLogEntrySnapshotsSelectedDishes() {
        let viewModel = TraySelectionViewModel(catalog: makeCatalog())
        let pasta = viewModel.catalog.dishes[0]
        viewModel.toggle(pasta)

        let entry = viewModel.makeLogEntry()
        XCTAssertEqual(entry?.items, [MealLogItem(name: "Pasta al pomodoro", carbsG: 45)])
        XCTAssertEqual(entry?.totalCarbsG, 45)
    }

    func testClearSelectionEmptiesSelectionButNotCatalog() {
        let viewModel = TraySelectionViewModel(catalog: makeCatalog())
        viewModel.toggle(viewModel.catalog.dishes[0])
        viewModel.clearSelection()

        XCTAssertTrue(viewModel.selectedDishes.isEmpty)
        XCTAssertEqual(viewModel.catalog.dishes.count, 3)
    }

    func testCategoriesPreservesFirstSeenOrderWithoutDuplicates() {
        let viewModel = TraySelectionViewModel(catalog: makeCatalog())
        XCTAssertEqual(viewModel.categories(), ["primi_piatti", "frutta_fresca", "secondi_piatti"])
    }
}
