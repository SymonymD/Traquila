import SwiftUI

struct AppCoordinatorView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    private var selectedColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        if settings.onboardingComplete {
            RootTabView()
                .transition(.opacity)
        } else {
            OnboardingFlowView()
                .transition(.opacity)
        }
    }

    var body: some View {
        Group {
            if let selectedColorScheme {
                routedContent
                    .environment(\.colorScheme, selectedColorScheme)
                    .preferredColorScheme(selectedColorScheme)
            } else {
                routedContent
                    .preferredColorScheme(nil)
            }
        }
        .id(settings.themeMode.rawValue)
        .animation(.easeInOut(duration: 0.25), value: settings.onboardingComplete)
        .task {
            #if DEBUG
            try? MockDataSeeder.seedIfNeeded(context: modelContext)
            #endif
        }
    }
}
