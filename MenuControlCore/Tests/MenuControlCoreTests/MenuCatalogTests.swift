import XCTest
@testable import MenuControlCore

final class MenuCatalogTests: XCTestCase {
    func testAddAndRemoveDish() {
        var catalog = MenuCatalog(dishes: [])
        let dish = Dish(name: "Pasta al pomodoro", carbsG: 45, category: "primi_piatti")
        catalog.add(dish)
        XCTAssertEqual(catalog.dishes.count, 1)

        catalog.remove(id: dish.id)
        XCTAssertTrue(catalog.dishes.isEmpty)
    }

    func testDishesInCategoryFiltersCorrectly() {
        let catalog = MenuCatalog(dishes: [
            Dish(name: "Pasta al pomodoro", carbsG: 45, category: "primi_piatti"),
            Dish(name: "Mela", carbsG: 20, category: "frutta_fresca"),
        ])
        XCTAssertEqual(catalog.dishes(inCategory: "primi_piatti").map(\.name), ["Pasta al pomodoro"])
    }
}
