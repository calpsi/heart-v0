#if os(visionOS)
import Foundation
import Metal
import RealityKit

/// One material path for both learning modes. Inspection changes do not alter
/// tissue identity; only the existing early-looping palette reveal changes it.
@MainActor final class HeartMorphAppearance {
    private struct Key: Equatable {
        let outflow: Bool
        let paletteProgress: Double
    }
    private var key: Key?
    private weak var styledModel: ModelEntity?
    private(set) var revision = 0
    private static let surfaceFinish: (grain: TextureResource, roughness: TextureResource)? = {
        guard let grainURL = Bundle.main.url(forResource: "MorphTissueGrain", withExtension: "png"),
              let roughnessURL = Bundle.main.url(forResource: "MorphTissueRoughness", withExtension: "png"),
              let grain = try? TextureResource.load(contentsOf: grainURL, options: .init(semantic: .color)),
              let roughness = try? TextureResource.load(contentsOf: roughnessURL, options: .init(semantic: .raw)) else { return nil }
        return (grain, roughness)
    }()

    private func finished(_ source: PhysicallyBasedMaterial) -> PhysicallyBasedMaterial {
        var material = source
        if let finish = Self.surfaceFinish {
            var sampler = MaterialParameters.Texture.Sampler()
            sampler.modify { $0.sAddressMode = .repeat; $0.tAddressMode = .repeat }
            material.baseColor.texture = .init(finish.grain, sampler: sampler)
            material.roughness.texture = .init(finish.roughness, sampler: sampler)
        }
        material.faceCulling = .none
        return material
    }

    func apply(to model: ModelEntity, progress: Double, outflow: Bool) {
        guard model.model != nil else { return }
        let next = Key(outflow: outflow,
                       paletteProgress: outflow ? 0 : min(0.18, max(0, progress.isFinite ? progress : 0)))
        // Recreating RealityView can install a fresh ModelComponent with an
        // empty material list while retaining this appearance cache.
        guard key != next || styledModel !== model || model.model?.materials.isEmpty == true else { return }
        let materials: [any RealityKit.Material]
        if outflow {
            materials = [HeartAnatomyRegion.arterial, .atrioventricular].map { region in
                finished(HeartModelStyle.region(region))
            }
        } else {
            materials = HeartTubeLayer.allCases.flatMap { layer in
                HeartAnatomyRegion.allCases.map { region -> any RealityKit.Material in
                    finished(HeartModelStyle.morphRegion(region, progress: next.paletteProgress,
                                                        lightening: layer.lightening))
                }
            }
        }
        model.model?.materials = materials
        key = next
        styledModel = model
        revision += 1
    }
}
#endif
