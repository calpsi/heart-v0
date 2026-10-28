import Observation
import simd

/// Inspection context belongs to the lesson/exploration workspace, not its
/// temporary sheet. Playback and gesture samples deliberately remain local.
@Observable final class HeartMorphSession {
    var progress = 0.0
    var cutaway = false
    var layersSeparated = false
    var yaw = 0.0
    var pitch = 0.0
    var zoom = 1.0
    var rotation: SIMD4<Float>?
    var orientation: simd_quatf {
        get { rotation.map { simd_quatf(vector: $0) } ?? (simd_quatf(angle: Float(yaw), axis: [0, 1, 0]) * simd_quatf(angle: Float(pitch), axis: [1, 0, 0])) }
        set { rotation = simd_normalize(newValue).vector }
    }
    var selectedLayer = HeartTubeLayer.myocardium
    var isolatedLayer: HeartTubeLayer?
    func selectLayer(_ layer: HeartTubeLayer) {
        selectedLayer = layer
        if isolatedLayer != nil { isolatedLayer = layer }
    }
    var layerOffsets: [Int: SIMD3<Float>] = [:]
    var layersMoved: Bool { layerOffsets.values.contains { $0 != .zero } }
    func moveLayer(_ delta: SIMD3<Float>) {
        layerOffsets[selectedLayer.rawValue] = HeartTubeLayer.boundedMove((layerOffsets[selectedLayer.rawValue] ?? .zero) + delta)
    }
    func resetLayerMove() { layerOffsets.removeValue(forKey: selectedLayer.rawValue) }
    private var practices: [HeartMorphLearning.Process: HeartMorphLearning.Practice] = [:]
    func practice(_ process: HeartMorphLearning.Process) -> HeartMorphLearning.Practice {
        practices[process] ?? .init(process: process)
    }
    func updatePractice(_ process: HeartMorphLearning.Process, _ update: (inout HeartMorphLearning.Practice) -> Void) {
        var attempt = practice(process); update(&attempt); practices[process] = attempt
    }
}
