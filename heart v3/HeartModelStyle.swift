import RealityKit
#if canImport(UIKit)
import UIKit
private typealias TissueColor = UIColor
#else
import AppKit
private typealias TissueColor = NSColor
#endif

/// One surface family for live anatomy. Anatomical colour maps are data, not decoration.
/// Muted anatomical regions follow the user-selected colour direction.
enum HeartModelStyle {
    static let roughness: Float = 0.48

    static func tissue() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: regionTint(.ventricular))
        material.roughness = .init(floatLiteral: roughness)
        material.metallic = .init(floatLiteral: 0)
        return material
    }

    static func region(_ region: HeartAnatomyRegion) -> PhysicallyBasedMaterial {
        var material = tissue()
        material.baseColor = .init(tint: regionTint(region))
        return material
    }
    static func morphRegion(_ region: HeartAnatomyRegion, progress: Double) -> PhysicallyBasedMaterial {
        morphRegion(region, progress: progress, lightening: 0)
    }
    static func morphRegion(_ region: HeartAnatomyRegion, progress: Double, lightening: Double) -> PhysicallyBasedMaterial {
        var material = tissue()
        let base = region.morphRGB(progress: progress)
        let rgb = base + (SIMD3<Double>(repeating: 1) - base) * min(1, max(0, lightening))
        material.baseColor = .init(tint: TissueColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1))
        return material
    }
    private static func regionTint(_ region: HeartAnatomyRegion) -> TissueColor {
        let rgb = region.rgb
        return TissueColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1)
    }
    /// Explicit named-region adaptation. Surface detail remains in normal and
    /// roughness maps; original source colour maps remain in the unchanged asset.
    static func identifiedRegion(_ source: PhysicallyBasedMaterial, partID: String) -> PhysicallyBasedMaterial {
        let region = HeartAnatomyRegion.identifiedPart(partID)
        guard region != nil || HeartAnatomyRegion.isUnsegmentedTubeWall(partID) else { return source }
        var material = source
        // Retain a lightness distinction between the named wall layers while
        // keeping their regional hue family consistent with the animation.
        let layerLightening = partID.hasPrefix("CardiacJelly_") ? HeartTubeLayer.cardiacJelly.lightening
            : partID.hasPrefix("Endocardium_") ? HeartTubeLayer.endocardium.lightening : 0.0
        let base = (region ?? .ventricular).rgb
        let rgb = base + (SIMD3<Double>(repeating: 1) - base) * layerLightening
        material.baseColor = .init(tint: TissueColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: source.baseColor.tint.cgColor.alpha))
        return material
    }

    /// Never discard a source texture, transparency, cut-face setting or unknown shader.
    /// Uniform tissue colour is opt-in for inspected, texture-free UMCG models.
    static func harmonized(_ source: any RealityKit.Material, uniformTissue: Bool = false, toneRegions: Bool = false, toneTextures: Bool = false) -> any RealityKit.Material {
        guard var material = source as? PhysicallyBasedMaterial else { return source }
        if uniformTissue && material.baseColor.texture == nil {
            // Keep the original alpha/blending even for a colour adaptation.
            let alpha = material.baseColor.tint.cgColor.alpha
            material.baseColor.tint = tissue().baseColor.tint.withAlphaComponent(alpha)
        } else if toneRegions && material.baseColor.texture == nil {
            material.baseColor.tint = regionColor(material.baseColor.tint)
        } else if toneTextures && material.baseColor.texture != nil {
            material.baseColor.tint = textureTint(material.baseColor.tint)
        }
        if material.roughness.texture == nil { material.roughness.scale = roughness }
        if material.metallic.texture == nil { material.metallic.scale = 0 }
        return material
    }
    /// Bound texture modulation instead of replacing or flattening colour maps.
    /// Set a ceiling rather than multiplying repeatedly, so styling is idempotent.
    private static func textureTint(_ source: TissueColor) -> TissueColor {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard source.getRed(&r, green: &g, blue: &b, alpha: &a) else { return source }
        #else
        guard let rgb = source.usingColorSpace(.sRGB) else { return source }
        let r = rgb.redComponent, g = rgb.greenComponent, b = rgb.blueComponent, a = rgb.alphaComponent
        #endif
        let peak = max(r, max(g, b))
        guard peak > 0.65 else { return source }
        let factor = 0.65 / peak
        return TissueColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }

    /// Keep the hue of categorical anatomy, but bring neon source colours into
    /// the same restrained palette. Neutral greys and dark structures stay unchanged.
    private static func regionColor(_ source: TissueColor) -> TissueColor {
        #if canImport(UIKit)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard source.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return source }
        #else
        guard let rgb = source.usingColorSpace(.sRGB) else { return source }
        let hue = rgb.hueComponent, saturation = rgb.saturationComponent
        let brightness = rgb.brightnessComponent, alpha = rgb.alphaComponent
        #endif
        guard saturation > 0.15 else { return source }
        return TissueColor(hue: hue, saturation: min(saturation, 0.55), brightness: min(brightness, 0.72), alpha: alpha)
    }

}

#if os(visionOS)
/// Lights stay outside the rotating anatomy so shadows continue to reveal its form.
@MainActor enum HeartModelLighting {
    private static let environment = Task {
        try await EnvironmentResource(named: "HeartTissueStudio", in: .main)
    }

    static func install(on holder: Entity, receiving model: Entity) async throws {
        let resource = try await environment.value
        var lighting = ImageBasedLightComponent(source: .single(resource), intensityExponent: -0.6)
        lighting.inheritsRotation = true
        holder.components.set(lighting)
        model.components.set(ImageBasedLightReceiverComponent(imageBasedLight: holder))
        // Idempotent installation avoids stacking lights when a scene is reused.
        if holder.children.contains(where: { $0.name == "TissueKeyLight" }) { return }
        let key = DirectionalLight()
        key.name = "TissueKeyLight"
        key.light.intensity = 1100
        key.shadow = .init(shadowProjection: .automatic(maximumDistance: 3), depthBias: 1)
        holder.addChild(key)
        key.look(at: .zero, from: [-0.4, 0.6, 0.8], relativeTo: holder)
        // A directional light needs orientation only; keep layout bounds at the origin.
        key.position = .zero
        let rim = DirectionalLight()
        rim.name = "TissueRimLight"
        rim.light.intensity = 300
        holder.addChild(rim)
        rim.look(at: .zero, from: [0.5, 0.25, -0.7], relativeTo: holder)
        rim.position = .zero
    }
}
#endif
