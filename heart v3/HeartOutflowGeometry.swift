import Foundation
import RealityKit
import simd

/// Regional illustration adapted from build_batch04.py's outflow loft.
/// A fixed curved conduit makes inward cushion growth visible. The quarter-turn
/// is a viewing convention, not a measured embryological rotation or a TGA model.
enum HeartOutflowGeometry {
    /// Do not render a sub-resolution sliver: Float angle rounding would make
    /// adjacent anterior-panel vertices coincide just before full opening.
    static func inspectionOpening(_ value: Double) -> Float {
        let value = Float(value.isFinite ? min(1, max(0, value)) : 0)
        return value >= 0.9999 ? 1 : value
    }
    struct Surface {
        var positions: [SIMD3<Float>]
        var normals: [SIMD3<Float>]
        var triangles: [UInt32]
        var materials: [UInt32]
        /// Wall, then the two authored cushion shapes. These are inspection
        /// components, not a complete anatomical segmentation of the outflow.
        var componentRanges: [Range<Int>]
        var textureCoordinates: [SIMD2<Float>]
    }
    static func surface(progress: Double, cutaway: Bool) -> Surface {
        surface(progress: progress, opening: cutaway ? 1 : 0)
    }

    /// Move the inspection cut around the anterior wall without changing the
    /// posterior wall, either cushion, or developmental progression.
    static func surface(progress: Double, opening: Double, separation: Double = 0) -> Surface {
        let opening = inspectionOpening(opening)
        let eased = Float(HeartMorphTiming.eased(progress))
        var positions: [SIMD3<Float>] = [], triangles: [UInt32] = [], materials: [UInt32] = []
        var textureCoordinates: [SIMD2<Float>] = []
        let rings = 48
        let frames = (0...rings).map { ring -> (t: Float, bend: Float, cosine: Float, sine: Float) in
            let t = Float(ring) / Float(rings), a = Float.pi * 0.5 * t
            return (t, 0.12 * sin(.pi*t), cos(a), sin(a))
        }
        func frame(_ ring: Int, _ x: Float, _ y: Float) -> SIMD3<Float> {
            let f = frames[ring]
            // Blender Z-up to app Y-up. Same source coordinates, reused ring frame.
            return SIMD3(f.bend + x*f.cosine - y*f.sine, -1.15 + 2.6*f.t, -(x*f.sine + y*f.cosine)) * 0.1
        }
        func triangle(_ a: Int, _ b: Int, _ c: Int, material: UInt32) {
            triangles.append(UInt32(a)); triangles.append(UInt32(b)); triangles.append(UInt32(c)); materials.append(material)
        }
        func loft(_ section: [SIMD2<Float>], material: UInt32, annular: Bool = false) {
            let base = positions.count, count = section.count
            for ring in 0...rings {
                for (j, point) in section.enumerated() {
                    positions.append(frame(ring, point.x, point.y))
                    textureCoordinates.append([Float(j) / Float(count) * 2, Float(ring) / Float(rings) * 6])
                }
            }
            for ring in 0..<rings { for j in 0..<count {
                let a = base + ring*count+j, b = base+ring*count+(j+1)%count
                triangle(a,b,b+count,material: material); triangle(a,b+count,a+count,material: material)
            } }
            // Duplicate cap vertices so cut surfaces have crisp lighting normals.
            for end in [0,rings] {
                if annular {
                    let cap = positions.count
                    for j in 0..<count {
                        positions.append(positions[base+end*count+j])
                        textureCoordinates.append(section[j] * 2)
                    }
                    for j in 0..<32 {
                        let a = cap+j, b = cap+j+1, c = cap+count-2-j, d = cap+count-1-j
                        if end == 0 {
                            triangle(a,c,b,material: material); triangle(a,d,c,material: material)
                        } else {
                            triangle(a,b,c,material: material); triangle(a,c,d,material: material)
                        }
                    }
                    continue
                }
                let cap = positions.count
                var centre = SIMD3<Float>.zero
                for j in 0..<count { centre += positions[base+end*count+j] }
                positions.append(centre / Float(count))
                textureCoordinates.append(section.reduce(.zero, +) / Float(count) * 2)
                for j in 0..<count {
                    positions.append(positions[base+end*count+j]); textureCoordinates.append(section[j] * 2)
                }
                for j in 0..<count {
                    let a = cap+1+j, b = cap+1+(j+1)%count
                    if end == 0 { triangle(cap,b,a,material: material) }
                    else { triangle(cap,a,b,material: material) }
                }
            }
        }
        // Posterior wall remains in place; optional anterior panel gives a whole conduit.
        for panel in 0..<(opening == 1 ? 1 : 2) {
            let start = Float(panel) * .pi
            let sweep = Float.pi * (panel == 0 ? 1 : 1 - opening)
            var section: [SIMD2<Float>] = []
            for i in 0...32 {
                let a = start + sweep*Float(i)/32
                section.append([0.56*cos(a), 0.56*sin(a)])
            }
            for i in (0...32).reversed() {
                let a = start + sweep*Float(i)/32
                section.append([0.48*cos(a), 0.48*sin(a)])
            }
            loft(section, material: 0, annular: true)
        }
        var componentRanges = [0..<positions.count]
        for sign: Float in [-1,1] {
            let first = positions.count
            var section: [SIMD2<Float>] = []
            for i in 0..<24 {
                let a = 2*Float.pi*Float(i)/24, c = cos(a), s = sin(a)
                let divisor = max(abs(c),abs(s))
                let before = SIMD2<Float>(0.40+0.10*c, 0.095*s)
                let after = SIMD2<Float>(0.25+0.25*c/divisor, 0.085*s/divisor)
                var point = before + (after-before)*eased
                point.x *= sign
                section.append(point)
            }
            if sign < 0 { section.reverse() }
            loft(section, material: 1)
            componentRanges.append(first..<positions.count)
        }
        var normals = Array(repeating: SIMD3<Float>.zero, count: positions.count)
        for i in stride(from: 0, to: triangles.count, by: 3) {
            let a = Int(triangles[i]), b = Int(triangles[i+1]), c = Int(triangles[i+2])
            let n = simd_cross(positions[b]-positions[a], positions[c]-positions[a])
            normals[a] += n; normals[b] += n; normals[c] += n
        }
        normals = normals.map { simd_length_squared($0) > 1e-20 ? simd_normalize($0) : [0,0,1] }
        let assembled = Surface(positions: positions, normals: normals, triangles: triangles, materials: materials, componentRanges: componentRanges, textureCoordinates: textureCoordinates)
        return placing(assembled, separation: separation)
    }

    static func placing(_ assembled: Surface, separation: Double) -> Surface {
        let separation = Float(separation.isFinite ? min(1, max(0, separation)) : 0)
        guard separation > 0 else { return assembled }
        var surface = assembled
        // Rigid offsets preserve the authored geometry and normals. The wall
        // stays at the shared origin; cushions retain their side of that wall.
        for component in 1...2 {
            let offset = SIMD3<Float>(component == 1 ? -0.12 : 0.12, 0, 0) * separation
            for vertex in surface.componentRanges[component] { surface.positions[vertex] += offset }
        }
        return surface
    }
    static func mesh(progress: Double, cutaway: Bool) throws -> MeshResource {
        let surface = surface(progress: progress, cutaway: cutaway)
        var descriptor = MeshDescriptor(name: "Outflow cushion transition")
        descriptor.positions = MeshBuffers.Positions(surface.positions)
        descriptor.normals = MeshBuffers.Normals(surface.normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(surface.textureCoordinates)
        descriptor.primitives = .triangles(surface.triangles)
        descriptor.materials = .perFace(surface.materials)
        return try MeshResource.generate(from: [descriptor])
    }
}
