import SwiftUI
import MenuControlCore
import MenuControlUI

/// Drop this file (and ContentView.swift) into the Xcode iOS App target once
/// created, with MenuControlCore package added as a local Swift Package
/// dependency (File > Add Package Dependencies > Add Local... > MenuControlCore).
@main
struct MenuControlApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
