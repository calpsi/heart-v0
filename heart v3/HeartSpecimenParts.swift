import Foundation
import simd

/// Group at the source-object level, not at material/65k-vertex export splits.
/// Generic source groups are deliberately not labelled as anatomical layers.
struct HeartSpecimenPart: Identifiable {
    let id: String
    let label: String
    static func parts(for model: String) -> [Self] {
        let names: [(String, String)]
        switch model {
        case "PDA_Patent": names = [("Aorta", "Aorta and arch branches"), ("PulmonaryArteries", "Pulmonary trunk and branches"), ("Ductus", "Ductus arteriosus")]
        case "PDA_Closed": names = [("Aorta", "Aorta and arch branches"), ("PulmonaryArteries", "Pulmonary trunk and branches"), ("Ligament", "Ligamentum arteriosum")]
        case "Normal_Teenage_Heart": names = [("Retopo_TN_Blood_Pool_0", "Blood-pool representation"), ("TN_Myocardium_001_1", "Myocardial shell")]
        case "Coarctation": names = [("right_final_no_peg_0", "Source section 1"), ("left_final_no_peg_1", "Source section 2")]
        case "Tetralogy_of_Fallot": names = [("AB_bp_obj_cleaner_materialmerger_gles", "Heart — unsegmented source")]
        case "Normal_Neonatal_Heart": names = [("Extract1", "Source component 1"), ("Extract3_1", "Source component 2"), ("MM634_BP51951_FMA4706_Coronary_sinus821", "Coronary sinus (source label)"), ("VALVES", "Valves (source label)")]
        case "Atrial_Septal_Defect_ASD": names = [("Extract1", "Source component 1"), ("Default1_2", "Source component 2"), ("Extract1_copy1", "Source component 3"), ("Default6", "Source component 4")]
        case "Ventricular_Septal_Defect": names = ["Default", "Default_copy1", "Default_copy2", "Default1", "Default15", "Default13_01"].enumerated().map { ($0.element, "Source component \($0.offset + 1)") }
        case "Transposition_of_the_great_arteries": names = ["POGING_14", "POGING_4", "POGING_19"].enumerated().map { ($0.element, "Source component \($0.offset + 1)") }
        case "Atrioventricular_septal_defect_4_chamber_view": names = [("avsd_4_kamer334", "Source section 1"), ("avsd_4_kamer132", "Source section 2"), ("MM634_BP51951_FMA4706_Coronary_sinus847", "Coronary sinus (source label)")]
        default: names = []
        }
        return names.map { Self(id: $0.0, label: $0.1) }
    }
    static func separationDirection(index: Int, count: Int) -> SIMD3<Float> {
        guard count > 1 else { return .zero }
        let angle = Float(index) * 2 * .pi / Float(count)
        return [cos(angle), sin(angle), 0]
    }
    static func separationDirection(model: String, part: String, index: Int, count: Int) -> SIMD3<Float> {
        if model == "Normal_Teenage_Heart" {
            // Source-authored shell and blood pool have known roles. Keep the
            // internal reference centred and lift its enclosing shell locally.
            if part == "Retopo_TN_Blood_Pool_0" { return .zero }
            if part == "TN_Myocardium_001_1" { return [-0.45, 0, -0.65] }
        }
        return separationDirection(index: index, count: count)
    }
    static func boundedOffset(_ value: SIMD3<Float>, diameter: Float) -> SIMD3<Float> {
        guard value.x.isFinite, value.y.isFinite, value.z.isFinite, diameter.isFinite, diameter > 0 else { return .zero }
        let length = simd_length(value), limit = diameter * 0.3
        return length > limit ? value * (limit / length) : value
    }
}
