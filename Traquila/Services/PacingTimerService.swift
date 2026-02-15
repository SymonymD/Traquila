import Combine
import Foundation

@MainActor
final class PacingTimerService: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var isRunning = false

    private var timer: Timer?

    func start(minutes: Int) {
        remainingSeconds = max(0, minutes * 60)
        isRunning = remainingSeconds > 0
        timer?.invalidate()
        guard isRunning else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}
