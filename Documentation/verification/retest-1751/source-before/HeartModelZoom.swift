import Foundation

/// Shared limits for sliders, gestures, viewing state and renderer fitting.
enum HeartModelZoom {
    static let range: ClosedRange<Double> = 0.4...2.5
    static let overviewMaximum = range.upperBound

    static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 1 }
        return min(range.upperBound, max(range.lowerBound, value))
    }
    /// SwiftUI exposes magnification, not hand-tracking confidence. Ignore invalid
    /// samples and rate-limit discontinuities; never infer tracking confidence.
    static func resized(start: Double, current: Double, magnification: Double, maximum: Double) -> Double {
        let safeCurrent = min(maximum, clamped(current))
        guard start.isFinite, current.isFinite, magnification.isFinite, magnification > 0 else { return safeCurrent }
        let desired = min(maximum, clamped(start * magnification))
        return min(maximum, clamped(min(safeCurrent * 1.15, max(safeCurrent / 1.15, desired))))
    }
}

/// A reset or suspension during a pinch must survive the remaining samples
/// from that gesture. A fresh gesture starts from the current visible size.
struct HeartPinchResizeSession {
    private(set) var start: Double?
    private var suppressed = false
    mutating func resize(current: Double, magnification: Double) -> Double {
        guard !suppressed else { return HeartModelZoom.clamped(current) }
        if start == nil { start = HeartModelZoom.clamped(current) }
        return HeartModelZoom.resized(start: start ?? current, current: current,
            magnification: magnification, maximum: HeartModelZoom.overviewMaximum)
    }
    mutating func interrupt(active: Bool) {
        start = nil; suppressed = active
    }
    mutating func end() { start = nil; suppressed = false }
}

