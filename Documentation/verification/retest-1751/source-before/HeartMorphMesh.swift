#if os(visionOS)
import RealityKit
import Metal
import simd

/// Keep one GPU mesh for each topology. Progress updates positions/normals in
/// place instead of constructing a new MeshResource for every animation frame.
@MainActor final class HeartMorphMeshCache {
    private struct Key: Hashable {
        let joining: Bool
        let cutaway: Bool
        let outflow: Bool
        let layers: Bool
    }
    private struct Entry {
        let storage: LowLevelMesh
        let resource: MeshResource
        var progress: Double
        var opening: Double
        var separation: Double
        var offsets: [Int: SIMD3<Float>]
        var visibleLayer: HeartTubeLayer?
        let parts: [LowLevelMesh.Part]
        var surfaceBounds: BoundingBox
    }
    private var entries: [Key: Entry] = [:]
    private var layerBase: (progress: Double, opening: Double, surface: HeartLoopingGeometry.Surface)?
    private var outflowBase: (progress: Double, opening: Double, surface: HeartOutflowGeometry.Surface)?
    private(set) var layerDeformationBuildCount = 0
    private(set) var outflowDeformationBuildCount = 0
    private(set) var surfaceBounds = BoundingBox(min: [-0.25, -0.25, -0.25], max: [0.25, 0.25, 0.25])
    static let bounds = BoundingBox(min: [-0.30, -0.30, -0.30], max: [0.30, 0.30, 0.30])

    func resource(progress: Double, cutaway: Bool, outflow: Bool) throws -> MeshResource {
        try resource(progress: progress, opening: cutaway ? 1 : 0, outflow: outflow)
    }

    func resource(progress: Double, opening: Double, outflow: Bool, layers: Bool = false, separation: Double = 0, offsets: [Int: SIMD3<Float>] = [:], visibleLayer: HeartTubeLayer? = nil) throws -> MeshResource {
        let joining = !outflow && progress < 0
        let layers = layers && !outflow
        let visibleLayer = layers ? visibleLayer : nil
        let separation = (layers || outflow) && separation.isFinite ? min(1, max(0, separation)) : 0
        let offsets: [Int: SIMD3<Float>] = layers ? Dictionary(uniqueKeysWithValues: HeartTubeLayer.allCases.map {
            ($0.rawValue, HeartTubeLayer.boundedMove(offsets[$0.rawValue] ?? .zero))
        }) : [:]
        // Geometry uses Float. Match its rounded endpoints before choosing a
        // topology, including Double values immediately below full opening.
        let opening = outflow ? Double(HeartOutflowGeometry.inspectionOpening(opening))
            : Double(Float(joining ? 0 : opening.isFinite ? min(1, max(0, opening)) : 0))
        // Only the endpoint changes connectivity: looping adds cut rims as it
        // opens; outflow removes its anterior panel when fully opened.
        let key = Key(joining: joining, cutaway: outflow ? opening == 1 : opening > 0, outflow: outflow, layers: layers)
        if var entry = entries[key], entry.progress == progress, entry.opening == opening, entry.separation == separation, entry.offsets == offsets {
            if entry.visibleLayer != visibleLayer {
                entry.storage.parts.replaceAll(Self.visibleParts(entry.parts, layer: visibleLayer))
                entry.visibleLayer = visibleLayer
                entries[key] = entry
            }
            surfaceBounds = entry.surfaceBounds
            return entry.resource
        }
        let surface: HeartLoopingGeometry.Surface
        if layers {
            if layerBase?.progress != progress || layerBase?.opening != opening {
                layerBase = (progress, opening, HeartTubeLayerGeometry.surface(progress: progress, opening: opening, separation: 0))
                layerDeformationBuildCount += 1
            }
            surface = HeartTubeLayerGeometry.placing(layerBase!.surface, separation: separation, offsets: offsets)
        } else if outflow {
            if outflowBase?.progress != progress || outflowBase?.opening != opening {
                outflowBase = (progress, opening, HeartOutflowGeometry.surface(progress: progress, opening: opening))
                outflowDeformationBuildCount += 1
            }
            let result = HeartOutflowGeometry.placing(outflowBase!.surface, separation: separation)
            surface = .init(positions: result.positions, normals: result.normals,
                            triangles: result.triangles, materials: result.materials, textureCoordinates: result.textureCoordinates)
        } else if progress < 0 {
            surface = HeartTubeFusionGeometry.surface(progress: progress + 1)
        } else {
            surface = HeartLoopingGeometry.surface(progress: progress, opening: opening)
        }
        var minimum = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maximum = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        // Visibility is independent of placement. Keep the whole arrangement's
        // envelope so isolation cannot make the remaining layer jump in depth.
        for point in surface.positions { minimum = simd_min(minimum, point); maximum = simd_max(maximum, point) }
        surfaceBounds = BoundingBox(min: minimum, max: maximum)
        if var entry = entries[key] {
            precondition(surface.positions.count == entry.storage.vertexCapacity, "Morph topology changed")
            Self.update(entry.storage, surface: surface)
            entry.progress = progress
            entry.opening = opening
            entry.separation = separation
            entry.offsets = offsets
            if entry.visibleLayer != visibleLayer {
                entry.storage.parts.replaceAll(Self.visibleParts(entry.parts, layer: visibleLayer))
                entry.visibleLayer = visibleLayer
            }
            entry.surfaceBounds = surfaceBounds
            entries[key] = entry
            return entry.resource
        }
        let descriptor = LowLevelMesh.Descriptor(
            vertexCapacity: surface.positions.count,
            vertexAttributes: [
                .init(semantic: .position, format: .float3, layoutIndex: 0, offset: 0),
                .init(semantic: .normal, format: .float3, layoutIndex: 1, offset: 0),
                .init(semantic: .uv0, format: .float2, layoutIndex: 2, offset: 0)
            ],
            vertexLayouts: [
                .init(bufferIndex: 0, bufferStride: MemoryLayout<SIMD3<Float>>.stride),
                .init(bufferIndex: 1, bufferStride: MemoryLayout<SIMD3<Float>>.stride),
                .init(bufferIndex: 2, bufferStride: MemoryLayout<SIMD2<Float>>.stride)
            ], indexCapacity: surface.triangles.count, indexType: .uint32)
        let storage = try LowLevelMesh(descriptor: descriptor)
        // Each part uses one material. Group faces once, retaining their winding.
        var groups: [UInt32: [UInt32]] = [:]
        for face in 0..<(surface.triangles.count / 3) {
            let material = surface.materials.isEmpty ? UInt32(HeartAnatomyRegion.ventricular.rawValue) : surface.materials[face]
            groups[material, default: []].append(contentsOf: surface.triangles[(face * 3)..<(face * 3 + 3)])
        }
        var indices: [UInt32] = [], parts: [LowLevelMesh.Part] = []
        for material in groups.keys.sorted() {
            let group = groups[material]!
            parts.append(.init(indexOffset: indices.count * MemoryLayout<UInt32>.stride,
                               indexCount: group.count, materialIndex: Int(material), bounds: Self.bounds))
            indices.append(contentsOf: group)
        }
        storage.withUnsafeMutableIndices { bytes in
            indices.withUnsafeBytes { bytes.copyMemory(from: $0) }
        }
        storage.parts.replaceAll(Self.visibleParts(parts, layer: visibleLayer))
        Self.update(storage, surface: surface)
        let resource = try MeshResource(from: storage)
        entries[key] = Entry(storage: storage, resource: resource, progress: progress, opening: opening, separation: separation, offsets: offsets, visibleLayer: visibleLayer, parts: parts, surfaceBounds: surfaceBounds)
        return resource
    }

    private static func visibleParts(_ parts: [LowLevelMesh.Part], layer: HeartTubeLayer?) -> [LowLevelMesh.Part] {
        guard let layer else { return parts }
        return parts.filter { $0.materialIndex / HeartAnatomyRegion.allCases.count == layer.rawValue }
    }

    /// Fit the current surface in front of the backing at every rotation and zoom.
    /// The cached drawing envelope is intentionally larger than this surface.
    func placement(in frame: BoundingBox, zoom: Double, yaw: Double, pitch: Double, outflow: Bool) -> Transform {
        var scale = min(frame.extents.x, frame.extents.y) * (outflow ? 1.05 : 0.90) / 0.37 * Float(HeartModelZoom.clamped(zoom))
        let orientation = simd_quatf(angle: Float(yaw) + (outflow ? -Float.pi / 4 : 0), axis: [0, 1, 0])
            * simd_quatf(angle: Float(max(-1.3, min(1.3, pitch))) + (outflow ? 0.22 : 0), axis: [1, 0, 0])
        var farthest = Float.infinity
        var nearest = -Float.infinity
        for x in [surfaceBounds.min.x, surfaceBounds.max.x] {
            for y in [surfaceBounds.min.y, surfaceBounds.max.y] {
                for z in [surfaceBounds.min.z, surfaceBounds.max.z] {
                    let z = orientation.act([x, y, z]).z
                    farthest = min(farthest, z); nearest = max(nearest, z)
                }
            }
        }
        scale = HeartViewportDepth.scale(scale, depth: nearest - farthest)
        return Transform(scale: SIMD3(repeating: scale), rotation: orientation,
                         translation: [0, 0, HeartViewportDepth.offset(minimumZ: farthest, scale: scale)])
    }

    private static func update(_ storage: LowLevelMesh, surface: HeartLoopingGeometry.Surface) {
        precondition(surface.textureCoordinates.count == surface.positions.count)
        storage.replaceUnsafeMutableBytes(bufferIndex: 2) { bytes in
            surface.textureCoordinates.withUnsafeBytes { bytes.copyMemory(from: $0) }
        }
        storage.replaceUnsafeMutableBytes(bufferIndex: 0) { bytes in
            surface.positions.withUnsafeBytes { bytes.copyMemory(from: $0) }
        }
        storage.replaceUnsafeMutableBytes(bufferIndex: 1) { bytes in
            surface.normals.withUnsafeBytes { bytes.copyMemory(from: $0) }
        }
    }
}
#endif
