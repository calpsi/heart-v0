import Foundation
import RealityKit
import Observation

/// Retains the displayed specimen while a replacement loads. Source specimens
/// never interpolate vertices: fade out, swap the fitted source, fade in.
/// A superseded or cancelled load cannot install geometry into this workspace.
@MainActor @Observable final class HeartSpecimenPresentation {
    @ObservationIgnored let root = Entity()
    private(set) var scene = HeartProjectScene()
    private(set) var displayedID: String?
    private(set) var loading = false
    private(set) var failed = false
    @ObservationIgnored private let load: @MainActor (HeartProjectScene, HeartProjectModel) async -> Void
    init(load: @escaping @MainActor (HeartProjectScene, HeartProjectModel) async -> Void = { scene, model in
        await scene.load(model.id, uniformTissue: model.usesUniformTissueColor)
    }) { self.load = load }
    @ObservationIgnored private var request = UUID()
    @ObservationIgnored private var frame: BoundingBox?
    @ObservationIgnored private var inspectionRotation: simd_quatf?
    @ObservationIgnored private var pose = (zoom: 1.0, yaw: 0.0, pitch: 0.0)

    func fit(_ bounds: BoundingBox, zoom: Double, yaw: Double, pitch: Double, inspectionRotation: simd_quatf? = nil) {
        self.inspectionRotation = inspectionRotation
        frame = bounds; pose = (zoom, yaw, pitch)
        if scene.ready { scene.fit(bounds, zoom: zoom, yaw: yaw, pitch: pitch, inspectionRotation: inspectionRotation) }
    }

    func present(_ model: HeartProjectModel, reducedMotion: Bool) async {
        let token = UUID(); request = token
        loading = true; failed = false
        scene.stop()
        // A rapid switch back to the currently displayed source need not reload it.
        if displayedID == model.id {
            scene.spin.components.set(OpacityComponent(opacity: 1))
            loading = false
            return
        }
        let next = HeartProjectScene()
        await load(next, model)
        guard request == token, !Task.isCancelled else { next.stop(); return }
        guard next.ready else {
            next.stop(); failed = true; loading = false
            scene.spin.components.set(OpacityComponent(opacity: 1))
            return
        }
        do {
            // Matched ductal reconstructions share coordinates: retain the cut
            // plane so comparison reveals the changed channel, not a new view.
            if displayedID?.hasPrefix("PDA_") == true, model.id.hasPrefix("PDA_"), scene.sectionAxis >= 0 {
                try await next.prepareSection(scene.sectionAxis)
                try Task.checkCancellation()
                guard request == token else { next.stop(); return }
            }
            if scene.ready && !reducedMotion {
                let initial = scene.spin.components[OpacityComponent.self]?.opacity ?? 1
                try await fade(scene, from: initial, to: 0, token: token)
            }
            try Task.checkCancellation()
            guard request == token else { return }
            scene.stop(); scene.root.removeFromParent()
            scene = next; displayedID = model.id
            if let frame { next.fit(frame, zoom: pose.zoom, yaw: pose.yaw, pitch: pose.pitch, inspectionRotation: inspectionRotation) }
            root.addChild(next.root)
            if reducedMotion { next.spin.components.set(OpacityComponent(opacity: 1)) }
            else { try await fade(next, from: 0, to: 1, token: token) }
            guard request == token else { return }
            loading = false
        } catch {
            next.stop()
            // Leave the last installed source coherent until the next request.
            if request == token {
                scene.spin.components.set(OpacityComponent(opacity: 1))
                loading = false
            }
        }
    }

    private func fade(_ target: HeartProjectScene, from start: Float, to end: Float, token: UUID) async throws {
        let clock = ContinuousClock()
        let began = clock.now
        while true {
            try Task.checkCancellation()
            guard request == token else { throw CancellationError() }
            let elapsed = began.duration(to: clock.now).components
            let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
            let t = Float(min(1, seconds / 0.16))
            let eased = t * t * (3 - 2 * t)
            target.spin.components.set(OpacityComponent(opacity: start + (end - start) * eased))
            if t >= 1 { return }
            try await Task.sleep(for: .milliseconds(16))
        }
    }
    func cancel() {
        request = UUID(); loading = false
        scene.stop(); scene.spin.components.set(OpacityComponent(opacity: 1))
    }
}
