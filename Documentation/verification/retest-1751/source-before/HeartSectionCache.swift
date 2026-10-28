import RealityKit
import simd

/// A reversible geometric section in the assembled specimen's coordinates.
/// Keep source instances, UVs and materials; never treat a clipped opening as
/// evidence of a real cavity or fill it with invented tissue.
@MainActor final class HeartSectionCache {
    struct Entry {
        let entity: Entity
        let original: ModelComponent
        let toSpecimen: simd_float4x4
    }
    private(set) var entries: [Entry] = []
    private var results: [Int: [MeshResource?]] = [:]
    private var active = -1
    private var centre = SIMD3<Float>.zero
    var meshCount: Int { entries.count }

    func capture(_ model: Entity) {
        entries = []; results = [:]; active = -1
        centre = model.visualBounds(relativeTo: model).center
        func visit(_ entity: Entity) {
            if let component = entity.components[ModelComponent.self] {
                entries.append(Entry(entity: entity, original: component, toSpecimen: entity.transformMatrix(relativeTo: model)))
            }
            for child in entity.children { visit(child) }
        }
        visit(model)
    }
    func prepare(axis: Int) async throws {
        guard axis >= 0 && results[axis] == nil else { return }
        precondition((0...2).contains(axis))
        var plane = SIMD4<Float>.zero; plane[axis] = 1; plane.w = -centre[axis]
        var section: [MeshResource?] = []
        for entry in entries {
            try Task.checkCancellation()
            let sources = snapshot(entry)
            let worker = Task.detached(priority: .userInitiated) { try Self.makeDescriptors(sources, plane: plane) }
            let descriptors = try await withTaskCancellationHandler {
                try await worker.value
            } onCancel: { worker.cancel() }
            try Task.checkCancellation()
            section.append(descriptors.isEmpty ? nil : try await MeshResource(from: descriptors))
        }
        try Task.checkCancellation()
        results[axis] = section
    }
    func apply(axis: Int) throws {
        guard axis != active else { return }
        guard axis < 0 || results[axis] != nil else { throw SectionError.notPrepared }
        for (i, entry) in entries.enumerated() {
            if axis < 0 {
                var restored = entry.entity.components[ModelComponent.self] ?? entry.original
                restored.mesh = entry.original.mesh
                // Restore the original culling, without losing a current selection tint.
                restored.materials = restored.materials.enumerated().map { index, material in
                    guard var pbr = material as? PhysicallyBasedMaterial,
                          index < entry.original.materials.count,
                          let original = entry.original.materials[index] as? PhysicallyBasedMaterial else { return material }
                    pbr.faceCulling = original.faceCulling
                    return pbr
                }
                entry.entity.components.set(restored)
            } else if let mesh = results[axis]?[i] {
                var component = entry.entity.components[ModelComponent.self] ?? entry.original
                component.mesh = mesh
                component.materials = component.materials.map { material in
                    guard var pbr = material as? PhysicallyBasedMaterial else { return material }
                    pbr.faceCulling = .none
                    return pbr
                }
                entry.entity.components.set(component)
            } else {
                entry.entity.components.remove(ModelComponent.self)
            }
        }
        active = axis
    }
    private enum SectionError: Error { case notPrepared }
    nonisolated private struct Source: Sendable {
        let name: String
        let positions: [SIMD3<Float>]
        let normals: [SIMD3<Float>]?
        let uv: [SIMD2<Float>]?
        let triangles: [UInt32]
        let transform: simd_float4x4
        let toSpecimen: simd_float4x4
        let material: Int
    }
    private func snapshot(_ entry: Entry) -> [Source] {
        let contents = entry.original.mesh.contents
        var sources: [Source] = []
        for instance in contents.instances {
            guard let model = contents.models.first(where: { $0.id == instance.model }) else { continue }
            for part in model.parts {
                guard let indices = part.triangleIndices else { continue }
                sources.append(Source(name: instance.id + "/" + part.id, positions: Array(part.positions),
                    normals: part.normals.map { Array($0) }, uv: part.textureCoordinates.map { Array($0) },
                    triangles: Array(indices), transform: instance.transform, toSpecimen: entry.toSpecimen,
                    material: part.materialIndex))
            }
        }
        return sources
    }
    nonisolated private static func makeDescriptors(_ sources: [Source], plane: SIMD4<Float>) throws -> [MeshDescriptor] {
        var descriptors: [MeshDescriptor] = []
        for source in sources {
            let localPlane = simd_transpose(source.toSpecimen * source.transform) * plane
            let normalMatrix = simd_transpose(simd_inverse(source.transform))
            let positions = source.positions, normals = source.normals, uv = source.uv, triangles = source.triangles
            var vertices: [HeartSectionGeometry.Vertex] = []
            vertices.reserveCapacity(triangles.count)
            for i in stride(from: 0, to: triangles.count - 2, by: 3) {
                if i % 3072 == 0 { try Task.checkCancellation() }
                let ids = [Int(triangles[i]), Int(triangles[i + 1]), Int(triangles[i + 2])]
                guard ids.allSatisfy({ $0 < positions.count }) else { continue }
                let face = simd_cross(positions[ids[1]] - positions[ids[0]], positions[ids[2]] - positions[ids[0]])
                let fallback = simd_length_squared(face) > 1e-20 ? simd_normalize(face) : SIMD3<Float>(0, 0, 1)
                let triangle = ids.map { id in HeartSectionGeometry.Vertex(position: positions[id], normal: normals?[id] ?? fallback, uv: uv?[id] ?? .zero) }
                vertices += HeartSectionGeometry.clip(triangle, plane: localPlane)
            }
            guard !vertices.isEmpty else { continue }
            var descriptor = MeshDescriptor(name: source.name)
            descriptor.positions = .init(vertices.map { v in let p = source.transform * SIMD4(v.position, 1); return SIMD3(p.x, p.y, p.z) })
            descriptor.normals = .init(vertices.map { v in let n = normalMatrix * SIMD4(v.normal, 0); return simd_normalize(SIMD3(n.x, n.y, n.z)) })
            if uv != nil { descriptor.textureCoordinates = .init(vertices.map(\.uv)) }
            var winding = (0..<vertices.count).map(UInt32.init)
            if simd_determinant(source.transform) < 0 {
                for i in stride(from: 0, to: winding.count, by: 3) { winding.swapAt(i + 1, i + 2) }
            }
            descriptor.primitives = .triangles(winding)
            descriptor.materials = .allFaces(UInt32(source.material))
            descriptors.append(descriptor)
        }
        return descriptors
    }
}
