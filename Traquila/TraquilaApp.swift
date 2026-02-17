import SwiftData
import SwiftUI
import UIKit

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
            WishlistItem.self,
            UserProfile.self
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
            ThemedRootView()
                .environmentObject(settings)
                .environmentObject(discoverSession)
                .environmentObject(tabRouter)
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct ThemedRootView: View {
    @EnvironmentObject private var settings: AppSettings

    @ViewBuilder
    var body: some View {
        if let colorScheme {
            AppCoordinatorView()
                .environment(\.colorScheme, colorScheme)
                .preferredColorScheme(colorScheme)
                .id(settings.themeMode.rawValue)
                .onAppear { applyInterfaceStyle() }
                .onChange(of: settings.themeMode) { _, _ in applyInterfaceStyle() }
        } else {
            AppCoordinatorView()
                .preferredColorScheme(nil)
                .id(settings.themeMode.rawValue)
                .onAppear { applyInterfaceStyle() }
                .onChange(of: settings.themeMode) { _, _ in applyInterfaceStyle() }
        }
    }

    private var colorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private func applyInterfaceStyle() {
        // Skip UIKit override during Xcode Previews to avoid preview launch instability.
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }

        let style: UIUserInterfaceStyle
        switch settings.themeMode {
        case .system:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}
