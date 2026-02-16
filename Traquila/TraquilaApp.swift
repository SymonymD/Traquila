import SwiftData
import SwiftUI

@main
struct TraquilaApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var discoverSession = DiscoverSession()
    @StateObject private var tabRouter = AppTabRouter()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bottle.self,
            PourEntry.self,
            BottlePhoto.self,
            WishlistItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(settings)
                .environmentObject(discoverSession)
                .environmentObject(tabRouter)
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }

    private var colorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
