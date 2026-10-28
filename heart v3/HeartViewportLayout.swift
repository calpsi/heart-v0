import SwiftUI

/// Window anatomy sits just in front of the opaque workspace backing. Keep its
/// layout plane at zero depth: an implicit 3D layout volume projects the whole
/// viewport away from its surrounding controls, even when the mesh is centered.
private struct HeartViewportLayout: ViewModifier {
    @PhysicalMetric(from: .meters) private var pointsPerMeter: CGFloat = 1
    func body(content: Content) -> some View {
        content.frame(depth: 0)
            .preferredWindowClippingMargins(.front, pointsPerMeter * 0.6)
    }
}

extension View {
    func heartModelViewport() -> some View { modifier(HeartViewportLayout()) }
}

enum HeartViewportDepth {
    static let clearance: Float = 0.002
    static let maximum: Float = 0.50
    static func scale(_ requested: Float, depth: Float) -> Float {
        min(requested, (maximum - clearance) / max(0.001, depth))
    }
    static func offset(minimumZ: Float, scale: Float) -> Float {
        clearance - minimumZ * scale
    }
}
