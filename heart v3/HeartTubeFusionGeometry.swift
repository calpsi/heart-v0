import RealityKit
import simd

/// A geometric union of two hollow tubes. This illustrates convergence and
/// formation of a common channel, not cellular fusion or body folding.
enum HeartTubeFusionGeometry {
    static func surface(progress: Double, outerRadius: Float = 1, innerRadius: Float = 0.72,
                        preparedFrames: [HeartLoopingGeometry.Frame]? = nil) -> HeartLoopingGeometry.Surface {
        let p = Float(HeartMorphTiming.eased(progress))
        let distance = 0.065 * (1 - p)
        let rings = 96, sides = 48, stride = sides + 1
        let layer = (rings + 1) * stride
        let frames = preparedFrames ?? HeartLoopingGeometry.frames(progress: 0, rings: rings)
        precondition(frames.count == rings + 1)
        var positions: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var triangles: [UInt32] = []
        positions.reserveCapacity(layer * 4 + sides * 16)
        textureCoordinates.reserveCapacity(layer * 4 + sides * 16)
        triangles.reserveCapacity(rings * sides * 24 + sides * 24)
        for direction: Float in [1, -1] {
            for inner in [false, true] {
                for i in 0...rings {
                    let t = Float(i) / Float(rings)
                    let frame = frames[i]
                    let centre = frame.centre * 0.1
                    let side = frame.side, dorsal = frame.dorsal
                    let radius = HeartLoopingGeometry.radius(t) * 0.1 * (inner ? innerRadius : outerRadius)
                    // Omit each circle's buried arc after contact. Both outer
                    // walls and lumens become unions, without internal duplicate walls.
                    let angle = distance >= radius ? Float.pi : acos(-distance / radius)
                    for j in 0...sides {
                        let a = -angle + 2 * angle * Float(j) / Float(sides)
                        positions.append(centre + side * direction * (distance + radius*cos(a)) + dorsal * radius*sin(a))
                        // Same angular/longitudinal mapping as the joined tube.
                        textureCoordinates.append([(direction > 0 ? a : .pi - a) / .pi, t * 6])
                    }
                }
            }
        }
        func quad(_ a: Int, _ b: Int, _ c: Int, _ d: Int, reversed: Bool) {
            triangles.append(UInt32(a)); triangles.append(UInt32(reversed ? c : b)); triangles.append(UInt32(reversed ? b : c))
            triangles.append(UInt32(a)); triangles.append(UInt32(reversed ? d : c)); triangles.append(UInt32(reversed ? c : d))
        }
        for tube in 0...1 {
            for wall in 0...1 {
                for i in 0..<rings { for j in 0..<sides {
                    let a = (tube*2 + wall)*layer + i*stride+j
                    quad(a,a+stride,a+stride+1,a+1, reversed: (tube == 1) != (wall == 1))
                } }
            }
            for end in [0, rings] { for j in 0..<sides {
                let a = tube*2*layer + end*stride+j
                // Duplicate rim vertices to retain the thickness face's shading.
                let first = positions.count
                for vertex in [a,a+1,a+1+layer,a+layer] {
                    positions.append(positions[vertex]); textureCoordinates.append(textureCoordinates[vertex])
                }
                quad(first, first+1, first+2, first+3, reversed: (tube == 1) != (end == rings))
            } }
        }
        var normals = Array(repeating: SIMD3<Float>.zero, count: positions.count)
        for index in Swift.stride(from: 0, to: triangles.count, by: 3) {
            let a = Int(triangles[index]), b = Int(triangles[index+1]), c = Int(triangles[index+2])
            let n = simd_cross(positions[b]-positions[a], positions[c]-positions[a])
            normals[a] += n; normals[b] += n; normals[c] += n
        }
        // Across the two sides, union endpoints coincide once a wall has joined.
        // Before joining, close each circle's own seam instead.
        for wall in 0...1 { for i in 0...rings {
            let r = HeartLoopingGeometry.radius(Float(i)/Float(rings)) * 0.1 * (wall == 1 ? innerRadius : outerRadius)
            let a = wall*layer+i*stride, b = (2+wall)*layer+i*stride
            let pairs = distance >= r ? [(a,a+sides),(b,b+sides)] : [(a,b),(a+sides,b+sides)]
            for (first, second) in pairs {
                let joined = normals[first]+normals[second]
                normals[first] = joined; normals[second] = joined
            }
        } }
        normals = normals.map { simd_length_squared($0) > 1e-20 ? simd_normalize($0) : SIMD3<Float>(0,0,1) }
        return .init(positions: positions, normals: normals, triangles: triangles, textureCoordinates: textureCoordinates)
    }
    static func mesh(progress: Double) throws -> MeshResource {
        let surface = surface(progress: progress)
        var descriptor = MeshDescriptor(name: "Paired tubes joining")
        descriptor.positions = MeshBuffers.Positions(surface.positions)
        descriptor.normals = MeshBuffers.Normals(surface.normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(surface.textureCoordinates)
        descriptor.primitives = .triangles(surface.triangles)
        descriptor.materials = .perFace(Array(repeating: UInt32(HeartAnatomyRegion.ventricular.rawValue), count: surface.triangles.count / 3))
        return try MeshResource.generate(from: [descriptor])
    }
}
