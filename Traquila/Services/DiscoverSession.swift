import Combine
import Foundation

@MainActor
final class DiscoverSession: ObservableObject {
    @Published var query: String = "" {
        didSet { scheduleSearch() }
    }
    @Published var results: [DiscoverBottle] = []
    @Published var isLoading: Bool = false

    private var searchTask: Task<Void, Never>?

    private func scheduleSearch() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isLoading = false
            return
        }

        searchTask = Task { [query] in
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled else { return }

            await MainActor.run { self.isLoading = true }
            let loaded = await DiscoverService.search(query)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.results = loaded
                self.isLoading = false
            }
        }
    }
}
