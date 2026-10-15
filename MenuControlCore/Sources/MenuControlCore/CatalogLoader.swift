import Foundation

/// Age bands used by the school caterer's "grammature" tables (data/grammature_estate_2026.json).
/// The catalog JSON carries carbs for all three; the app picks one per Elena's school level.
public enum AgeGroup: String, Codable, CaseIterable, Sendable {
    case infanzia
    case primaria
    case secondariaAdulti = "secondaria_adulti"
}

public enum CatalogLoaderError: Error, Equatable {
    case resourceNotFound
    case decodingFailed(String)
}

public enum CatalogLoader {
    private struct RawCatalog: Decodable {
        struct RawDish: Decodable {
            let name: String
            let category: String
            let carbs_g: [String: Double?]
        }
        let dishes: [RawDish]
    }

    /// Loads the bundled seed catalog (data/menu_catalog_carbs.json, computed by
    /// scripts/compute_dish_carbs.py from the school's published grammature + an
    /// ingredient carbs-per-100g reference table) for the given age group.
    public static func loadBundled(
        ageGroup: AgeGroup = .secondariaAdulti,
        bundle: Bundle? = nil
    ) throws -> MenuCatalog {
        let bundle = bundle ?? Bundle.module
        guard let url = bundle.url(forResource: "menu_catalog_carbs", withExtension: "json") else {
            throw CatalogLoaderError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try load(data: data, ageGroup: ageGroup)
    }

    public static func load(data: Data, ageGroup: AgeGroup = .secondariaAdulti) throws -> MenuCatalog {
        let decoder = JSONDecoder()
        let raw: RawCatalog
        do {
            raw = try decoder.decode(RawCatalog.self, from: data)
        } catch {
            throw CatalogLoaderError.decodingFailed(String(describing: error))
        }

        let dishes: [Dish] = raw.dishes.compactMap { rawDish in
            guard let carbs = rawDish.carbs_g[ageGroup.rawValue] ?? nil else { return nil }
            return Dish(name: rawDish.name, carbsG: carbs, category: rawDish.category)
        }
        return MenuCatalog(dishes: dishes)
    }
}
