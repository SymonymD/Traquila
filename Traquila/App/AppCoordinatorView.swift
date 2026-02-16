import SwiftUI

struct AppCoordinatorView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Group {
            if settings.onboardingComplete {
                RootTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: settings.onboardingComplete)
        .task {
            #if DEBUG
            try? MockDataSeeder.seedIfNeeded(context: modelContext)
            #endif
        }
    }
}
