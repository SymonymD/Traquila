import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var tabRouter: AppTabRouter

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            BottlesListView()
                .tabItem {
                    Label("Cabinet", image: "CabinetTabIcon")
                }
                .tag(AppTab.cabinet)

            PoursTimelineView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(AppTab.log)

            InsightsDashboardView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.insights)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(TraquilaTheme.terracotta)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
