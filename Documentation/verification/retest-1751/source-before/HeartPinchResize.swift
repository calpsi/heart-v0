import SwiftUI

/// Shared bounded resizing for procedural morphs and source specimen viewers.
struct HeartPinchResize: ViewModifier {
    @Binding var zoom: Double
    var enabled = true
    var resetRevision = 0
    var onBegin: () -> Void = {}
    @Environment(\.scenePhase) private var scenePhase
    @GestureState private var active = false
    @State private var session = HeartPinchResizeSession()

    func body(content: Content) -> some View {
        content.simultaneousGesture(MagnifyGesture()
            .updating($active) { _, active, _ in active = true }
            .onChanged { value in
                guard enabled, scenePhase == .active else { return }
                if session.start == nil { onBegin() }
                zoom = session.resize(current: zoom, magnification: value.magnification)
            }
            .onEnded { _ in session.end() }, including: enabled ? .all : .subviews)
            .onChange(of: active) { _, active in if !active { session.end() } }
            .onChange(of: enabled) { _, enabled in if !enabled { session.interrupt(active: active) } }
            .onChange(of: resetRevision) { _, _ in session.interrupt(active: active) }
            .onChange(of: scenePhase) { _, phase in if phase != .active { session.interrupt(active: active) } }
            .onDisappear { session.end() }
    }
}
