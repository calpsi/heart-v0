import Foundation
import simd

/// Clips only existing triangles. No caps, wall thickness or histological layers
/// are invented. New edge vertices interpolate the source normal and UV.
enum HeartSectionGeometry {
    nonisolated struct Vertex: Sendable {
        var position: SIMD3<Float>
        var normal: SIMD3<Float>
        var uv: SIMD2<Float>
    }
    nonisolated static func clip(_ triangle: [Vertex], plane: SIMD4<Float>) -> [Vertex] {
        guard triangle.count == 3 else { return [] }
        func distance(_ v: Vertex) -> Float { simd_dot(plane, SIMD4(v.position, 1)) }
        func intersection(_ a: Vertex, _ b: Vertex, _ da: Float, _ db: Float) -> Vertex {
            let t = max(0, min(1, da / (da - db)))
            let n = a.normal + (b.normal - a.normal) * t
            return Vertex(position: a.position + (b.position - a.position) * t,
                          normal: simd_length_squared(n) > 1e-12 ? simd_normalize(n) : a.normal,
                          uv: a.uv + (b.uv - a.uv) * t)
        }
        var polygon: [Vertex] = []
        for i in 0..<3 {
            let a = triangle[i], b = triangle[(i + 1) % 3]
            let da = distance(a), db = distance(b)
            if da <= 0 { polygon.append(a) }
            if (da < 0 && db > 0) || (da > 0 && db < 0) { polygon.append(intersection(a, b, da, db)) }
        }
        guard polygon.count >= 3 else { return [] }
        var result: [Vertex] = []
        for i in 1..<(polygon.count - 1) {
            let a = polygon[0], b = polygon[i], c = polygon[i + 1]
            if simd_length_squared(simd_cross(b.position - a.position, c.position - a.position)) > 1e-20 {
                result += [a, b, c]
            }
        }
        return result
    }
}
