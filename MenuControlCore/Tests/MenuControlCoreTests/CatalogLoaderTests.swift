import XCTest
@testable import MenuControlCore

final class CatalogLoaderTests: XCTestCase {
    func testLoadsBundledCatalogForSecondariaAdulti() throws {
        let catalog = try CatalogLoader.loadBundled(ageGroup: .secondariaAdulti)
        XCTAssertGreaterThan(catalog.dishes.count, 50)
    }

    func testKnownDishHasExpectedCarbs() throws {
        let catalog = try CatalogLoader.loadBundled(ageGroup: .secondariaAdulti)
        let dish = try XCTUnwrap(catalog.dish(named: "Riso all'olio"))
        // 90g rice @ 80g carbs/100g = 72g, no other carb-bearing ingredients.
        XCTAssertEqual(dish.carbsG, 72.0, accuracy: 0.5)
        XCTAssertEqual(dish.category, "primi_piatti")
    }

    func testLookupIsCaseInsensitive() throws {
        let catalog = try CatalogLoader.loadBundled(ageGroup: .secondariaAdulti)
        XCTAssertNotNil(catalog.dish(named: "riso all'olio"))
        XCTAssertNotNil(catalog.dish(named: "RISO ALL'OLIO"))
    }

    func testUnknownDishReturnsNil() throws {
        let catalog = try CatalogLoader.loadBundled(ageGroup: .secondariaAdulti)
        XCTAssertNil(catalog.dish(named: "Dish that does not exist"))
    }

    func testDifferentAgeGroupsYieldDifferentCarbs() throws {
        let infanzia = try CatalogLoader.loadBundled(ageGroup: .infanzia)
        let secondaria = try CatalogLoader.loadBundled(ageGroup: .secondariaAdulti)

        let infanziaDish = try XCTUnwrap(infanzia.dish(named: "Riso all'olio"))
        let secondariaDish = try XCTUnwrap(secondaria.dish(named: "Riso all'olio"))

        // infanzia portion (50g rice) is smaller than secondaria (90g rice).
        XCTAssertLessThan(infanziaDish.carbsG, secondariaDish.carbsG)
    }

    func testDishesWithoutCarbsForAgeGroupAreOmitted() throws {
        // A dish with a null carbs_g for one age group (as merende entries do,
        // since "secondaria/adulti" doesn't get an afternoon snack) must not
        // appear in that age group's catalog.
        let json = """
        {"dishes": [
            {"name": "Yogurt BIO", "category": "merende", "carbs_g": {"infanzia": 5.6, "primaria": 5.6, "secondaria_adulti": null}}
        ]}
        """
        let data = Data(json.utf8)

        let secondaria = try CatalogLoader.load(data: data, ageGroup: .secondariaAdulti)
        XCTAssertNil(secondaria.dish(named: "Yogurt BIO"))

        let infanzia = try CatalogLoader.load(data: data, ageGroup: .infanzia)
        XCTAssertNotNil(infanzia.dish(named: "Yogurt BIO"))
    }

    func testMalformedJSONThrowsDecodingFailed() {
        let badData = Data("{ not valid json".utf8)
        XCTAssertThrowsError(try CatalogLoader.load(data: badData)) { error in
            guard case CatalogLoaderError.decodingFailed = error else {
                return XCTFail("expected decodingFailed, got \(error)")
            }
        }
    }
}
