import Foundation
import RealityKit
import simd

/// One continuous tube surface. The same ring/vertex indices persist throughout
/// bending; this is an illustrative shape interpolation, not a growth simulation.
enum HeartLoopingGeometry {
    static let knots: [(Float, SIMD3<Float>)] = [
        (0, [0.38, 1.16, -0.82]), (0.15, [0.73, 0.74, -0.68]),
        (0.30, [0.77, 0.06, -0.34]), (0.38, [0.67, -0.42, 0]),
        (0.50, [0.26, -0.91, 0.25]), (0.62, [-0.48, -0.70, 0.39]),
        (0.73, [-0.76, -0.13, 0.32]), (0.84, [-0.60, 0.50, 0.12]), (1, [-0.24, 1.38, -0.04])
    ]
    private static func referenceCentre(_ t: Float, _ progress: Float) -> SIMD3<Float> {
        let i = (0..<knots.count - 1).first { t <= knots[$0 + 1].0 } ?? knots.count - 2
        let (t0, p0) = knots[i], (t1, p1) = knots[i + 1]
        let (ta, pa) = knots[max(0, i - 1)], (tb, pb) = knots[min(knots.count - 1, i + 2)]
        let u = (t - t0) / (t1 - t0)
        let m0 = (p1 - pa) / (t1 - ta), m1 = (pb - p0) / (tb - t0)
        let curve = (2*u*u*u - 3*u*u + 1)*p0 + (u*u*u - 2*u*u + u)*(t1-t0)*m0
            + (-2*u*u*u + 3*u*u)*p1 + (u*u*u - u*u)*(t1-t0)*m1
        let straight = SIMD3<Float>(0.035*sin(.pi*t), -1.6+3.2*t, 0)
        return straight*(1-progress) + curve*progress
    }

    private static let standardPaths = referencePaths(rings: 96)

    private static func referencePaths(rings: Int) -> (straight: [SIMD3<Float>], loop: [SIMD3<Float>]) {
        let straight = (0...rings).map { referenceCentre(Float($0) / Float(rings), 0) }
        var loop = (0...rings).map { referenceCentre(Float($0) / Float(rings), 1) }
        // Soften curvature changes at the teaching spline's knots. The original
        // tight ventricular bend folded a few inner-bend wall faces inward.
        for _ in 0..<6 {
            var smoothed = loop
            for i in 1..<rings { smoothed[i] = (loop[i - 1] + 2 * loop[i] + loop[i + 1]) / 4 }
            loop = smoothed
        }
        return (straight, loop)
    }

    /// Interpolate edge rotation and length, not endpoint positions. Linear
    /// position interpolation crushed intermediate edges as the tube folded.
    static func centres(progress: Float, rings: Int = 96) -> [SIMD3<Float>] {
        let p = Float(HeartMorphTiming.eased(Double(progress)))
        let (straight, loop) = rings == 96 ? standardPaths : referencePaths(rings: rings)
        if p == 0 { return straight }
        if p == 1 { return loop }
        var points = [SIMD3<Float>.zero]
        for i in 0..<rings {
            let a = straight[i + 1] - straight[i], b = loop[i + 1] - loop[i]
            let rotation = simd_quatf(from: simd_normalize(a), to: simd_normalize(b))
            let intermediate = simd_slerp(simd_quatf(angle: 0, axis: [0, 1, 0]), rotation, p)
            let length = simd_length(a) * (1 - p) + simd_length(b) * p
            points.append(points[i] + intermediate.act(simd_normalize(a)) * length)
        }
        // Keep the model centred along the same trajectory as its endpoints.
        let targetCentre = zip(straight, loop).reduce(SIMD3<Float>.zero) { $0 + $1.0 * (1 - p) + $1.1 * p } / Float(rings + 1)
        let actualCentre = points.reduce(SIMD3<Float>.zero, +) / Float(rings + 1)
        return points.map { $0 + targetCentre - actualCentre }
    }

    static func centre(_ t: Float, _ progress: Float) -> SIMD3<Float> {
        let points = centres(progress: progress)
        let index = min(95, max(0, Int(floor(t * 96))))
        let fraction = t * 96 - Float(index)
        return points[index] + (points[index + 1] - points[index]) * fraction
    }
    static func radius(_ t: Float) -> Float {
        0.20 + 0.16*exp(-pow((t-0.50)/0.14, 2)) + 0.10*exp(-pow((t-0.22)/0.09, 2))
    }

    struct Surface {
        var positions: [SIMD3<Float>]
        var normals: [SIMD3<Float>]
        var triangles: [UInt32]
        var materials: [UInt32] = []
        var textureCoordinates: [SIMD2<Float>] = []
    }

    struct Frame {
        let centre: SIMD3<Float>
        let side: SIMD3<Float>
        let dorsal: SIMD3<Float>
    }

    /// Parallel-transport the cross-section along the centreline. Recomputing
    /// cross(tangent, worldZ) at every ring flipped the surface as its tangent
    /// passed through worldZ during bending, despite a continuous centreline.
    static func frames(progress: Float, rings: Int = 96) -> [Frame] {
        var result: [Frame] = []
        let points = centres(progress: progress, rings: rings)
        var previousTangent = SIMD3<Float>(0, 1, 0)
        var side = SIMD3<Float>(1, 0, 0)
        for i in 0...rings {
            let tangent = simd_normalize(points[min(rings, i + 1)] - points[max(0, i - 1)])
            side = simd_quatf(from: previousTangent, to: tangent).act(side)
            // Remove round-off drift so the wall stays circular, not sheared.
            side = simd_normalize(side - tangent * simd_dot(side, tangent))
            result.append(Frame(centre: points[i], side: side,
                                dorsal: simd_normalize(simd_cross(side, tangent))))
            previousTangent = tangent
        }
        return result
    }

    static func surface(progress: Double, cutaway: Bool) -> Surface {
        surface(progress: progress, opening: cutaway ? 1 : 0)
    }

    /// Reveal the existing lumen progressively. Opening is an inspection cut,
    /// independent of the developmental bend and of the wall's radius/thickness.
    static func surface(progress: Double, opening: Double, outerRadius: Float = 1, innerRadius: Float = 0.72,
                        preparedFrames: [Frame]? = nil) -> Surface {
        let opening = Float(opening.isFinite ? min(1, max(0, opening)) : 0)
        let cutaway = opening > 0
        let p = Float(min(1, max(0, progress.isFinite ? progress : 0)))
        let rings = 96, sides = 48, stride = sides + 1, layer = (rings + 1) * (sides + 1)
        let frames = preparedFrames ?? frames(progress: p, rings: rings)
        precondition(frames.count == rings + 1)
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], faces: [UInt32] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var regions: [UInt32] = [], materialFaces: [UInt32] = []
        let vertexCount = layer * 2 + sides * 8 + (cutaway ? rings * 8 : 0)
        positions.reserveCapacity(vertexCount); normals.reserveCapacity(vertexCount)
        textureCoordinates.reserveCapacity(vertexCount); regions.reserveCapacity(vertexCount)
        faces.reserveCapacity(rings * sides * 12 + sides * 12 + (cutaway ? rings * 12 : 0))
        materialFaces.reserveCapacity(rings * sides * 4 + sides * 4 + (cutaway ? rings * 4 : 0))
        // Every ring and both wall surfaces use these same angular samples.
        // Compute trig once while retaining the exact original vertex formula.
        let circle = (0...sides).map { j -> (angle: Float, cosine: Float, sine: Float) in
            let angle = Float.pi / 2 + Float(j)/Float(sides) * (2 - 0.5 * opening) * .pi + opening * 0.25 * .pi
            return (angle, cos(angle), sin(angle))
        }
        for inside in [false, true] {
            for i in 0...rings {
                let t = Float(i) / Float(rings)
                let frame = frames[i]
                let radius = radius(t)
                for j in 0...sides {
                    // Place the inspection opening towards the default viewer,
                    // not around the side of the tube. The back-wall midpoint
                    // stays fixed while the cut opens; the closed shape is the
                    // same circular shell with a quarter-turn vertex seam.
                    let sample = circle[j]
                    let angle = sample.angle
                    let n = sample.cosine*frame.side + sample.sine*frame.dorsal
                    let r = radius * (inside ? innerRadius : outerRadius)
                    positions.append((frame.centre + n*r) * 0.1)
                    textureCoordinates.append([angle / .pi, t * 6])
                    regions.append(UInt32(HeartAnatomyRegion.tube(at: t).rawValue))
                    normals.append(n * (inside ? -1 : 1))
                }
            }
        }
        func quad(_ a: Int, _ b: Int, _ c: Int, _ d: Int) {
            faces.append(UInt32(a)); faces.append(UInt32(b)); faces.append(UInt32(c))
            faces.append(UInt32(a)); faces.append(UInt32(c)); faces.append(UInt32(d))
            materialFaces += [regions[a], regions[a]]
        }
        for k in 0...1 {
            for i in 0..<rings { for j in 0..<sides {
                let a = k*layer + i*stride+j
                if k == 0 { quad(a,a+stride,a+stride+1,a+1) }
                else { quad(a,a+1,a+stride+1,a+stride) }
            } }
        }
        // Separate rim vertices give the cut faces their own surface normals,
        // instead of lighting a thickness face as though it were curved muscle.
        func rim(_ a: Int, _ b: Int, _ c: Int, _ d: Int) {
            let first = positions.count
            for index in [a, b, c, d] {
                positions.append(positions[index]); normals.append(.zero); regions.append(regions[index])
                textureCoordinates.append(textureCoordinates[index])
            }
            quad(first, first + 1, first + 2, first + 3)
        }
        for j in 0..<sides {
            rim(j,j+1,j+1+layer,j+layer)
            let a = rings*stride+j
            rim(a,a+layer,a+layer+1,a+1)
        }
        if cutaway {
            for i in 0..<rings { for j in [0,sides] {
                let a = i*stride+j
                if j == 0 { rim(a,a+layer,a+layer+stride,a+stride) }
                else { rim(a,a+stride,a+layer+stride,a+layer) }
            } }
        }
        // Derive lighting from the actual deformed surface, including changes
        // in radius. Pure radial normals made the tapered wall look flat.
        normals = Array(repeating: .zero, count: positions.count)
        for index in Swift.stride(from: 0, to: faces.count, by: 3) {
            let a = Int(faces[index]), b = Int(faces[index+1]), c = Int(faces[index+2])
            let normal = simd_cross(positions[b] - positions[a], positions[c] - positions[a])
            normals[a] += normal; normals[b] += normal; normals[c] += normal
        }
        if !cutaway {
            for k in 0...1 { for ring in 0...rings {
                let a = k*layer + ring*stride, b = a+sides
                let joined = normals[a] + normals[b]
                normals[a] = joined; normals[b] = joined
            } }
        }
        normals = normals.map { simd_length_squared($0) > 1e-20 ? simd_normalize($0) : SIMD3<Float>(0, 0, 1) }
        return Surface(positions: positions, normals: normals, triangles: faces, materials: materialFaces, textureCoordinates: textureCoordinates)
    }

    static func mesh(progress: Double, cutaway: Bool) throws -> MeshResource {
        let surface = surface(progress: progress, cutaway: cutaway)
        var descriptor = MeshDescriptor(name: "Continuous heart tube")
        descriptor.positions = MeshBuffers.Positions(surface.positions)
        descriptor.normals = MeshBuffers.Normals(surface.normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(surface.textureCoordinates)
        descriptor.primitives = .triangles(surface.triangles)
        descriptor.materials = .perFace(surface.materials)
        return try MeshResource.generate(from: [descriptor])
    }
}

