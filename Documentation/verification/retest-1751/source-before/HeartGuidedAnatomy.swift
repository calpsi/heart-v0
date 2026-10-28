import Foundation

/// Later anatomy is a second representation within a lesson, never a morph
/// target or a substitute for the embryonic process. All IDs refer to bundled models.
struct HeartGuidedAnatomy {
    let normalID: String
    let alteredID: String?
    let process: String
    let observe: String
    let explain: String

    var isDuctalComparison: Bool { alteredID == "PDA_Patent" }
    var normalLabel: String { isDuctalComparison ? "Closed remnant" : "Typical anatomy" }
    var alteredLabel: String { isDuctalComparison ? "Patent ductus" : "Related anomaly" }
    var comparisonNote: String {
        isDuctalComparison ? "Matched authored regional models · anatomical endpoints, not instant closure or a flow simulation."
            : "Later anatomy, not an embryonic stage. Different specimens; fitted size is not a measurement."
    }

    static func lesson(_ name: String) -> Self? {
        switch name {
        case "Cardiogenic region", "Paired heart tubes", "Primitive heart tube segments", "Cardiac looping (D-looping)":
            return .init(normalID: "Normal_Neonatal_Heart", alteredID: nil,
                process: "From an early tube to a recognisable heart",
                observe: "Rotate the neonatal heart to establish its overall form. Return to the developmental model and follow the tube or regions being introduced.",
                explain: "Which changes in shape can the developmental view explain? This external view cannot show the internal partitions or every intervening stage.")
        case "Atrial septation", "Atrial Septal Defect (ASD)":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: "Atrial_Septal_Defect_ASD",
                process: "Atrial partitioning → later atrial anatomy",
                observe: "Use the typical heart to orient the chambers, then rotate the ASD example and inspect the opening in relation to the atria.",
                explain: "Describe the visible communication, then return to the developmental view to explain what the separating tissues normally achieve. These examples are not matched before-and-after specimens.")
        case "Endocardial cushion fusion":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: "Atrioventricular_septal_defect_4_chamber_view",
                process: "AV junction development → later central anatomy",
                observe: "Inspect the centre of the four-chamber AVSD view. Compare the junction with the two openings in the cushion lesson.",
                explain: "Explain the relationship between the junction and the neighbouring chambers. The cushion animation alone does not reproduce all changes in AVSD.")
        case "Ventricular septation", "Ventricular Septal Defect (VSD)":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: "Ventricular_Septal_Defect",
                process: "Ventricular partitioning → later septal anatomy",
                observe: "Orient the ventricles, then rotate the VSD example. Look for the communication and describe its relationship to the surrounding anatomy.",
                explain: "Return to the developmental view and explain the role of the partition. Do not infer a specific developmental mechanism from this specimen alone.")
        case "Outflow tract septation", "Tetralogy of Fallot":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: "Tetralogy_of_Fallot",
                process: "Outlet division and alignment → later connections",
                observe: "Trace the great vessels towards the ventricular regions. Compare the typical heart with the Fallot example using both rotation and the developmental view.",
                explain: "Describe an observed spatial relationship before explaining it. Division, alignment and later muscle changes are not a single event in the morph.")
        case "Transposition of the Great Arteries (TGA)":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: "Transposition_of_the_great_arteries",
                process: "Outlet connections → later arterial pathways",
                observe: "Trace each great artery back towards its ventricle in the TGA example. Use the typical heart as a second orientation reference.",
                explain: "Explain why the connections matter, rather than identifying arteries from their colour alone. Return to the developmental view to inspect the labelled pathways.")
        case "Coarctation of the Aorta":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: "Coarctation",
                process: "Arch development → later channel shape",
                observe: "Follow the aortic arch in this different representation. Describe where its width changes before returning to the matched schematic comparison.",
                explain: "Separate what you see from its proposed developmental causes. These fitted specimens cannot measure severity or establish the cause of an individual narrowing.")
        case "Valvular refinement":
            return .init(normalID: "Normal_Teenage_Heart", alteredID: nil,
                process: "Valve development within the whole heart",
                observe: "Use the whole-heart reference to orient the chambers and outlets. Return to the developmental view for the separate valve and chordal structures.",
                explain: "Explain where the valve structures belong. This whole-heart source is not a detailed valve-layer model.")
        case "Circulatory transition", "Patent Ductus Arteriosus (PDA)":
            return .init(normalID: "PDA_Closed", alteredID: "PDA_Patent",
                process: "A normal fetal connection → closure after birth or a persistent duct",
                observe: "Follow the duct from the pulmonary artery to the descending aorta. Open a cross-section, then compare the patent duct with the closed remnant at the same orientation.",
                explain: "Before birth this connection is normal. If it persists after birth, it is PDA. Explain what is still connected; the closed view shows a later anatomical endpoint, not immediate closure or simulated blood flow.")
        default: return nil
        }
    }

    static func isAvailable(lesson: String, step: Int, answerHidden: Bool) -> Bool {
        guard !answerHidden, self.lesson(lesson) != nil else { return false }
        if lesson == HeartLearningPilot.cushionLesson { return step >= 2 }
        // Keep the normal-reference → unaided-recognition sequence intact.
        if lesson == HeartLearningPilot.coarctationLesson { return step >= 2 }
        return true
    }

    static func opensAutomatically(lesson: String, step: Int, lastStep: Int, answerHidden: Bool) -> Bool {
        guard isAvailable(lesson: lesson, step: step, answerHidden: answerHidden) else { return false }
        if ["Atrial Septal Defect (ASD)", "Ventricular Septal Defect (VSD)", "Patent Ductus Arteriosus (PDA)"].contains(lesson) { return true }
        if lesson == HeartLearningPilot.cushionLesson || lesson == HeartLearningPilot.coarctationLesson { return step == 3 }
        return step == lastStep
    }
}
