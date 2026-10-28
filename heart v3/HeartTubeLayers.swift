import RealityKit
import simd

/// Early tube architecture only. Radii are the existing build_batch02.py
/// teaching proportions, not histological measurements or later-heart layers.
enum HeartTubeLayer: Int, CaseIterable {
    case myocardium, cardiacJelly, endocardium
    var title: String {
        switch self {
        case .myocardium: "Myocardium"
        case .cardiacJelly: "Cardiac jelly"
        case .endocardium: "Endocardium"
        }
    }
    var inner: Float { switch self { case .myocardium: 0.78; case .cardiacJelly: 0.61; case .endocardium: 0.54 } }
    var outer: Float { switch self { case .myocardium: 1; case .cardiacJelly: 0.78; case .endocardium: 0.61 } }
    var lightening: Double { switch self { case .myocardium: 0; case .cardiacJelly: 0.22; case .endocardium: 0.12 } }
    var explanation: String {
        switch self {
        case .myocardium: "Outer muscle layer"
        case .cardiacJelly: "Extracellular matrix between the two cell layers"
        case .endocardium: "Inner cell layer lining the blood channel"
        }
    }
    func offset(separation: Double) -> SIMD3<Float> {
        let value = Float(separation.isFinite ? min(1, max(0, separation)) : 0)
        // Keep the inner lining at the anatomical origin. Lift the enclosing
        // shells locally in depth, as in the earlier posterior-panel inspection,
        // rather than turning the layers into three hearts across the viewport.
        let distance = Float(2 - rawValue) * value
        return [-0.018 * distance, 0, -0.025 * distance]
    }
    static func boundedMove(_ value: SIMD3<Float>) -> SIMD3<Float> {
        guard value.x.isFinite, value.y.isFinite, value.z.isFinite else { return .zero }
        let distance = simd_length(value)
        return distance > 0.04 ? value * (0.04 / distance) : value
    }
    static func draggedOffset(from start: SIMD3<Float>, translation: SIMD3<Float>, unitsPerPoint: Float,
                              orientation: simd_quatf) -> SIMD3<Float> {
        guard unitsPerPoint.isFinite, unitsPerPoint > 0,
              translation.x.isFinite, translation.y.isFinite, translation.z.isFinite else { return boundedMove(start) }
        return boundedMove(start + orientation.inverse.act(translation * unitsPerPoint))
    }
}

enum HeartTubeLayerGeometry {
    static func surface(progress: Double, opening: Double, separation: Double, offsets: [Int: SIMD3<Float>] = [:]) -> HeartLoopingGeometry.Surface {
        var result = HeartLoopingGeometry.Surface(positions: [], normals: [], triangles: [])
        // All wall layers follow the same centreline and transported frame.
        // Build it once per developmental frame rather than once per shell.
        let frames = HeartLoopingGeometry.frames(progress: progress < 0 ? 0 : Float(progress))
        for layer in HeartTubeLayer.allCases {
            let surface = progress < 0
                ? HeartTubeFusionGeometry.surface(progress: progress + 1, outerRadius: layer.outer, innerRadius: layer.inner, preparedFrames: frames)
                : HeartLoopingGeometry.surface(progress: progress, opening: opening, outerRadius: layer.outer, innerRadius: layer.inner, preparedFrames: frames)
            let base = UInt32(result.positions.count)
            result.positions += surface.positions
            result.normals += surface.normals
            result.textureCoordinates += surface.textureCoordinates
            result.triangles += surface.triangles.map { $0 + base }
            let regions = surface.materials.isEmpty
                ? Array(repeating: UInt32(HeartAnatomyRegion.ventricular.rawValue), count: surface.triangles.count / 3)
                : surface.materials
            result.materials += regions.map { $0 + UInt32(layer.rawValue * HeartAnatomyRegion.allCases.count) }
        }
        return placing(result, separation: separation, offsets: offsets)
    }

    /// Translation-only inspection can reuse the current deformation and its
    /// normals/topology rather than rebuilding all three shells every frame.
    static func placing(_ assembled: HeartLoopingGeometry.Surface, separation: Double,
                        offsets: [Int: SIMD3<Float>]) -> HeartLoopingGeometry.Surface {
        precondition(assembled.positions.count % HeartTubeLayer.allCases.count == 0)
        var result = assembled
        let count = assembled.positions.count / HeartTubeLayer.allCases.count
        for layer in HeartTubeLayer.allCases {
            let offset = layer.offset(separation: separation) + HeartTubeLayer.boundedMove(offsets[layer.rawValue] ?? .zero)
            guard offset != .zero else { continue }
            for i in (layer.rawValue * count)..<((layer.rawValue + 1) * count) {
                result.positions[i] += offset
            }
        }
        return result
    }
}
