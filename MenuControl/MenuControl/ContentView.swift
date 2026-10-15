import SwiftUI
import MenuControlCore
import MenuControlUI

struct ContentView: View {
    var body: some View {
        MenuControlRootView(
            catalog: loadCatalog(),
            persistence: FileMealLogPersistence(fileURL: mealLogFileURL())
        )
    }

    private func loadCatalog() -> MenuCatalog {
        (try? CatalogLoader.loadBundled(ageGroup: .secondariaAdulti)) ?? MenuCatalog(dishes: [])
    }

    private func mealLogFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("meal_log.json")
    }
}

#Preview {
    ContentView()
}
