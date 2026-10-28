import Foundation

/// Muted teaching colours identify regions, never oxygen levels or cell lineages.
/// Tube boundaries follow the existing segmented illustration (build_batch02.py).
enum HeartAnatomyRegion: Int, CaseIterable {
    case inflow, atrial, atrioventricular, ventricular, bulbus, arterial
    var title: String {
        switch self {
        case .inflow: "Venous inflow"
        case .atrial: "Atrial region"
        case .atrioventricular: "AV junction / cushions"
        case .ventricular: "Ventricular region"
        case .bulbus: "Bulbus region"
        case .arterial: "Arterial outflow"
        }
    }
    var rgb: SIMD3<Double> {
        switch self {
        case .inflow: [0.36, 0.48, 0.66]
        case .atrial: [0.57, 0.46, 0.64]
        case .atrioventricular: [0.70, 0.57, 0.36]
        case .ventricular: [0.70, 0.39, 0.43]
        case .bulbus: [0.39, 0.60, 0.57]
        case .arterial: [0.72, 0.48, 0.35]
        }
    }
    static func tube(at value: Float) -> Self {
        let t = value.isFinite ? min(1, max(0, value)) : 0
        if t < 0.15 { return .inflow }
        if t < 0.30 { return .atrial }
        if t < 0.38 { return .atrioventricular }
        if t < 0.62 { return .ventricular }
        if t < 0.84 { return .bulbus }
        return .arterial
    }

    /// Reveal the teaching colour key as looping starts, without a colour pop
    /// when the unsegmented joined tube changes to the looping topology.
    func morphRGB(progress: Double) -> SIMD3<Double> {
        let t = min(1, max(0, (progress.isFinite ? progress : 0) / 0.18))
        let eased = t * t * (3 - 2 * t)
        let wall = Self.ventricular.rgb
        return wall + (rgb - wall) * eased
    }
    static func identifiedPart(_ id: String) -> Self? {
        let key = id.lowercased()
        let words = Set(key.split(separator: "_").map(String.init))
        // Explicit anatomy names only: never infer a region from geometry or colour.
        // Atlas exports append mesh/version suffixes and sometimes abbreviate ventricle.
        // Match anatomical tokens rather than requiring the name to end at that token.
        if key.contains("sinusvenosus") || key.contains("sinus_venosus") || key.contains("vena_cava")
            || key.contains("venousinflow") || words.contains("veins")
            || key.hasPrefix("superiorcavalmouth_") || key.hasPrefix("inferiorcavalmouth_") { return .inflow }
        if key.contains("primitiveatrium") || key.hasPrefix("atrialwall_") || key.hasPrefix("atriumwall_")
            || !words.isDisjoint(with: ["atrium", "atrium2", "atria"]) { return .atrial }
        if key.contains("avcanal") || key.contains("cushion") || key.contains("septalridge") || key.contains("parietalridge") { return .atrioventricular }
        if key.contains("primitiveventricle") || key.hasPrefix("ventricularwall_") || key.hasPrefix("ventriclewall_")
            || !words.isDisjoint(with: ["ventricle", "vent"]) { return .ventricular }
        if key.contains("bulbuscordis") { return .bulbus }
        if key.contains("truncusarteriosus") || key.hasPrefix("outflowwall_") || key.hasPrefix("arterialbranch_")
            || !words.isDisjoint(with: ["outflow", "oft"]) { return .arterial }
        return nil
    }

    /// A wall-layer role without a regional assignment. Paired tubes have not
    /// been subdivided in this illustration, so coral here means tube wall only.
    static func isUnsegmentedTubeWall(_ id: String) -> Bool {
        let words = id.lowercased().split(separator: "_").map(String.init)
        guard words.count == 3 else { return false }
        return ["myocardium", "cardiacjelly", "endocardium"].contains(words[0])
            && ["l", "r"].contains(words[1])
            && ["anterior", "posterior"].contains(words[2])
    }
}
