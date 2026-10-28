import Foundation

/// Presentation timing for illustrative morphs, not a biological growth rate.
/// Zero endpoint velocity lets independently authored processes meet without
/// a sudden change in direction at their shared anatomical pose.
enum HeartMorphTiming {
    static func eased(_ progress: Double) -> Double {
        let p = progress.isFinite ? min(1, max(0, progress)) : 0
        return p * p * (3 - 2 * p)
    }

    /// Inspection transitions use elapsed time, so a delayed render cannot
    /// stretch a short motion into a sequence of slow frame-counted steps.
    @MainActor static func animate(duration: Double, onFrame: (Double) -> Void) async {
        guard !Task.isCancelled else { return }
        let clock = ContinuousClock(), began = ContinuousClock.now
        while !Task.isCancelled {
            let elapsed = began.duration(to: clock.now).components
            let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
            let progress = min(1, seconds / max(0.001, duration))
            onFrame(eased(progress))
            if progress == 1 { return }
            do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
        }
    }
}
