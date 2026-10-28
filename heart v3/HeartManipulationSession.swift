import simd

/// One gesture contract for stage anatomy, animated development and specimens.
/// Translation is always measured from the start of the drag. A pinch owns the
/// rest of that gesture, so releasing one hand cannot resume a stale rotation.
struct HeartManipulationSession {
    private var rotationStart: simd_quatf?
    private var resizeSession = HeartPinchResizeSession()
    private(set) var pinched = false
    private(set) var manipulated = false
    private(set) var blocked = false

    static func rotated(from start: simd_quatf, horizontal: Float, vertical: Float) -> simd_quatf {
        guard horizontal.isFinite, vertical.isFinite else { return start }
        let delta = simd_quatf(angle: vertical * 0.005, axis: [1, 0, 0])
            * simd_quatf(angle: horizontal * 0.005, axis: [0, 1, 0])
        return simd_normalize(delta * start)
    }

    mutating func rotate(current: simd_quatf, horizontal: Float, vertical: Float) -> simd_quatf {
        guard !blocked, !pinched else { return current }
        if rotationStart == nil { rotationStart = current }
        manipulated = true
        return Self.rotated(from: rotationStart ?? current, horizontal: horizontal, vertical: vertical)
    }

    mutating func resize(current: Double, magnification: Double) -> Double {
        guard !blocked else { return current }
        pinched = true; manipulated = true
        return resizeSession.resize(current: current, magnification: magnification)
    }

    mutating func interrupt(active: Bool) {
        self = Self()
        blocked = active
    }

    mutating func finish() { self = Self() }
}
