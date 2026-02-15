import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            BottlesListView()
                .tabItem {
                    Label("Bottles", systemImage: "wineglass")
                }

            PoursTimelineView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.rectangle.portrait")
                }

            InsightsDashboardView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(TraquilaTheme.terracotta)
    }
}
