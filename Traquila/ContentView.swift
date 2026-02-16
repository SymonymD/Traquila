import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        AppCoordinatorView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .environmentObject(DiscoverSession())
        .environmentObject(AppTabRouter())
        .modelContainer(PreviewData.sharedContainer)
}

private enum PreviewData {
    static let sharedContainer: ModelContainer = {
        let schema = Schema([
            Bottle.self,
            PourEntry.self,
            BottlePhoto.self,
            WishlistItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}
