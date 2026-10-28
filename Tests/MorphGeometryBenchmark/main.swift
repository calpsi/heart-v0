import Foundation
import CryptoKit
import simd
var results: [[String: Any]] = []
for kind in ["joining", "looping", "outflow"] {
 for opening in [0.0, 0.5, 1.0] {
  var hasher = SHA256()
  let start = ContinuousClock.now
  var vertices = 0
  var geometryMS = 0.0
  for i in 0...20 {
   let p = Double(i) / 20
   let frameStart = ContinuousClock.now
   let surface: HeartLoopingGeometry.Surface
   if kind == "outflow" {
    let s = HeartOutflowGeometry.surface(progress: p, opening: opening, separation: 0.5)
    surface = .init(positions: s.positions, normals: s.normals, triangles: s.triangles, materials: s.materials, textureCoordinates: s.textureCoordinates)
   } else {
    surface = HeartTubeLayerGeometry.surface(progress: kind == "joining" ? p - 1.001 : p, opening: opening, separation: 0.5)
   }
   let frameTime = frameStart.duration(to: .now).components
   geometryMS += Double(frameTime.seconds)*1000+Double(frameTime.attoseconds)/1e15
   vertices += surface.positions.count
   // Hash components explicitly; SIMD3 padding bytes are unspecified.
   for vector in surface.positions + surface.normals { for var value in [vector.x,vector.y,vector.z] { withUnsafeBytes(of:&value) { hasher.update(bufferPointer:$0) } } }
   surface.triangles.withUnsafeBytes { hasher.update(bufferPointer:$0) }
   surface.materials.withUnsafeBytes { hasher.update(bufferPointer:$0) }
   surface.textureCoordinates.withUnsafeBytes { hasher.update(bufferPointer:$0) }
  }
  let duration = start.duration(to: .now).components
  results.append(["kind":kind,"opening":opening,"frames":21,"vertices":vertices,"geometryMS":geometryMS,"msIncludingHash":Double(duration.seconds)*1000+Double(duration.attoseconds)/1e15,"sha256":hasher.finalize().map { String(format:"%02x",$0) }.joined()])
 }
}
let output = try JSONSerialization.data(withJSONObject:results,options:[.prettyPrinted,.sortedKeys])
print(String(decoding:output,as:UTF8.self))
