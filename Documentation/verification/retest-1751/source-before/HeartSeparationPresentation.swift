import Foundation
import Observation

/// Cancelled transitions leave their current value available for a smooth reversal.
@MainActor @Observable
final class HeartSeparationPresentation {
    private(set) var value: Double = 0

    func update(to target: Double, animated: Bool, onFrame: ((Double) -> Void)? = nil) async {
        guard !Task.isCancelled else { return }
        let target = min(1, max(0, target))
        let start = value
        guard animated, abs(target - start) > 0.001 else { value = target; return }
        let clock = ContinuousClock()
        let began = clock.now
        while !Task.isCancelled {
            let elapsed = began.duration(to: clock.now).components
            let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
            let progress = min(1, seconds / 0.32)
            let eased = progress * progress * (3 - 2 * progress)
            value = start + (target - start) * eased
            onFrame?(value)
            if progress == 1 { value = target; return }
            do { try await Task.sleep(for: .milliseconds(16)) }
            catch { return }
        }
    }
}
