import SwiftUI
import RealityKit
import simd

/// Attach only to the 3D viewport, never to its buttons, sliders or popovers.
struct HeartModelGestures: ViewModifier {
    @Binding var orientation: simd_quatf
    @Binding var zoom: Double
    var enabled = true
    var resetRevision = 0
    var targetsEntities = true
    var onBegin: () -> Void = {}
    var onEnd: () -> Void = {}
    var onTap: (Entity) -> Void = { _ in }
    /// Return true when an explicit part-movement mode owns this drag.
    var movePart: (EntityTargetValue<DragGesture.Value>) -> Bool = { _ in false }
    @Environment(\.scenePhase) private var scenePhase
    @GestureState private var dragging = false
    @GestureState private var pinching = false
    private var active: Bool { dragging || pinching }
    @State private var session = HeartManipulationSession()
    @State private var began = false

    private func begin() {
        if !began { began = true; onBegin() }
    }
    private func interrupt() {
        session.interrupt(active: active)
        began = false
        onEnd()
    }

    func body(content: Content) -> some View {
        interactionSurface(content)
            .onChange(of: active) { _, active in
                if !active { session.finish(); began = false; onEnd() }
            }
            .onChange(of: enabled) { _, enabled in if !enabled { interrupt() } }
            .onChange(of: resetRevision) { _, _ in interrupt() }
            .onChange(of: scenePhase) { _, phase in if phase != .active { interrupt() } }
            .onDisappear { interrupt() }
            .modifier(HeartGestureTestValue(orientation: orientation, zoom: zoom, enabled: enabled, phase: scenePhase))
    }

    @ViewBuilder private func interactionSurface(_ content: Content) -> some View {
        if targetsEntities {
        content.gesture(
            DragGesture(minimumDistance: 8).targetedToAnyEntity()
                .exclusively(before: SpatialTapGesture().targetedToAnyEntity())
                .updating($dragging) { _, active, _ in active = true }
                .onChanged { value in
                    guard enabled, scenePhase == .active, !session.blocked, !session.pinched, !pinching else { return }
                    if case .first(let drag) = value {
                        begin()
                        if !movePart(drag) {
                            orientation = session.rotate(current: orientation,
                                horizontal: Float(drag.translation.width), vertical: Float(drag.translation.height))
                        }
                    }
                }
                .onEnded { value in
                    if enabled, scenePhase == .active, !session.blocked,
                       !session.manipulated, !session.pinched, !pinching,
                       case .second(let tap) = value { onTap(tap.entity) }
                    onEnd()
                }, including: enabled ? .all : .subviews)
            .simultaneousGesture(MagnifyGesture().targetedToAnyEntity()
                .updating($pinching) { _, active, _ in active = true }
                .onChanged { value in
                    guard enabled, scenePhase == .active, !session.blocked else { return }
                    begin()
                    zoom = session.resize(current: zoom, magnification: value.magnification)
                }, including: enabled ? .all : .subviews)
        } else {
            // Source specimens and procedural surfaces have no selectable tissue
            // targets. Keep their viewport input path, scoped above controls.
            content.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 8)
                    .updating($dragging) { _, active, _ in active = true }
                    .onChanged { drag in
                        guard enabled, scenePhase == .active, !session.blocked, !session.pinched, !pinching else { return }
                        begin()
                        orientation = session.rotate(current: orientation,
                            horizontal: Float(drag.translation.width), vertical: Float(drag.translation.height))
                    }, including: enabled ? .all : .subviews)
                .simultaneousGesture(MagnifyGesture()
                    .updating($pinching) { _, active, _ in active = true }
                    .onChanged { value in
                        guard enabled, scenePhase == .active, !session.blocked else { return }
                        begin()
                        zoom = session.resize(current: zoom, magnification: value.magnification)
                    }, including: enabled ? .all : .subviews)
        }
    }
}

private struct HeartGestureTestValue: ViewModifier {
    let orientation: simd_quatf
    let zoom: Double
    let enabled: Bool
    let phase: ScenePhase
    func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            content.background(alignment: .topLeading) {
                Color.clear
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Interaction state")
                    .accessibilityIdentifier("interaction.state")
                    .accessibilityValue("\(orientation.vector.x),\(orientation.vector.y),\(orientation.vector.z),\(orientation.vector.w);\(zoom);enabled=\(enabled);phase=\(phase)")
                    .allowsHitTesting(false)
            }
        } else { content }
        #else
        content
        #endif
    }
}

