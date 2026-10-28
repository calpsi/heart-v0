import Foundation
import Observation

@MainActor @Observable final class HeartLayerMovePresentation {
    private(set) var offsets: [Int: SIMD3<Float>] = [:]
    func update(to target: [Int: SIMD3<Float>], animated: Bool) async {
        guard !Task.isCancelled else { return }
        let target = Dictionary(uniqueKeysWithValues: HeartTubeLayer.allCases.compactMap { layer -> (Int, SIMD3<Float>)? in
            let value = HeartTubeLayer.boundedMove(target[layer.rawValue] ?? .zero)
            return value == .zero ? nil : (layer.rawValue, value)
        })
        let start = offsets
        guard animated, start != target else { offsets = target; return }
        // Use the same elapsed-time driver as wall opening and reassembly.
        // Counting frames stretched a short move whenever rendering was busy.
        let transition = HeartSeparationPresentation()
        await transition.update(to: 1, animated: true) { eased in
            self.offsets = Dictionary(uniqueKeysWithValues: HeartTubeLayer.allCases.map {
                let a = start[$0.rawValue] ?? .zero, b = target[$0.rawValue] ?? .zero
                return ($0.rawValue, a + (b - a) * Float(eased))
            })
        }
        if !Task.isCancelled { offsets = target }
    }
}
