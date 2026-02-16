import Combine
import Foundation

enum AppTab: Hashable {
    case cabinet
    case log
    case insights
    case settings
}

@MainActor
final class AppTabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .cabinet
}
