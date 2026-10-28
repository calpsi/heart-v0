import Foundation

struct LearningCard: Identifiable {
    let id = UUID()
    let title: String
    let visualFocus: String
    let concepts: [String]
    let interaction: String
}

struct LearningTopic: Identifiable {
    let id = UUID()
    let timing: String
    let name: String
    let summary: String
    let cards: [LearningCard]
}

/// Content and optional assessment rules, independent of RealityKit rendering.
enum HeartLearningPilot {
    static let cushionLesson = "Endocardial cushion fusion"
    static let coarctationLesson = "Coarctation of the Aorta"
    static let reviewNotice = "School prototype · simplified developmental models."
    static let cushionExplanation = "Fusion of the superior and inferior cushions divides the common AV canal into separate left and right atrioventricular openings."
    static let cushionCards: [LearningCard] = [
        .init(title: "Observe", visualFocus: "Inspect the opposing cushions before fusion.", concepts: ["Identify the common canal and the space between the cushions before considering the later arrangement."], interaction: "Rotate the assembled model. Keep both cushions in view."),
        .init(title: "Predict", visualFocus: "What will change when these cushions meet?", concepts: [], interaction: "Make an optional prediction before showing the later state."),
        .init(title: "Reveal", visualFocus: "Compare the earlier and later arrangements.", concepts: [cushionExplanation], interaction: "Toggle Compare while keeping the same viewpoint. These are discrete teaching snapshots, not a continuous developmental animation."),
        .init(title: "Explain", visualFocus: cushionExplanation, concepts: ["The fused cushion mass also participates in septal junctions. The muscular ventricular septum develops from myocardium.", "The model simplifies tissue shape and timing; it does not simulate growth."], interaction: "Trace the openings on either side of the fused cushions. Revisit the previous step to compare."),
        .init(title: "Retrieve", visualFocus: "Recall the relationship you just compared.", concepts: [], interaction: "Answer without reopening the explanation, or revisit it whenever you need.")
    ]
    static let coarctationCards: [LearningCard] = [
        .init(title: "Normal Reference", visualFocus: "Inspect the open aortic arch and its branches.", concepts: ["Trace the channel through the arch and into the descending segment.", "This open comparison is a schematic reference, not a patient or a measured normal range."], interaction: "Rotate the arch and follow the main channel. Continue to inspect a second configuration without target labels."),
        .init(title: "Find the Narrowing", visualFocus: "Aortic isthmus just beyond the left subclavian branch.", concepts: ["This regional example shows a localized coarctation.", "The cutaway exposes an eccentric narrowing of the channel."], interaction: "Inspect the channel, then compare it with the open reference."),
        .init(title: "Compare the Channel", visualFocus: "Compare the same aortic segment at the same viewpoint.", concepts: ["The comparison preserves the outer vessel size while widening the lumen.", "Dimensions are illustrative and do not grade clinical severity."], interaction: "Switch between Coarctation and Open comparison with Cutaway on. Follow the same branches across both states."),
        .init(title: "Explain the Difference", visualFocus: "The narrowed channel can obstruct blood flow through the aorta.", concepts: ["Clinical consequence: significant obstruction can produce higher pressure upstream and reduced perfusion downstream. This model does not simulate pressure, flow or clinical severity.", "Developmental explanation: multiple mechanisms have been proposed, including ductal tissue and altered fetal flow. No single mechanism explains every case.", "Source: Coarctation of the Aorta: Diagnosis and Management (2023), doi:10.3390/diagnostics13132189."], interaction: "Describe the visible narrowing separately from its proposed causes. Compare the open channel again if needed."),
        .init(title: "Recognise Again", visualFocus: "Locate the narrowing again after changing your viewpoint.", concepts: ["This is repeat recognition of the same teaching model. Use the patient-derived example to compare a different representation."], interaction: "Rotate to another view, then identify the region without labels. This does not measure clinical transfer.")
    ]
    struct Check {
        let id: String
        let question: String
        let options: [String]
        let answer: Int
        let rationale: String
    }
    static func check(lesson: String, step: Int) -> Check? {
        guard lesson == cushionLesson else { return nil }
        switch step {
        case 1: return .init(id: "cushion.predict", question: "What arrangement do you expect after the opposing cushions meet?", options: ["One unchanged common opening", "Separate left and right openings", "No atrioventricular openings"], answer: 1, rationale: cushionExplanation)
        case 4: return .init(id: "cushion.retrieve", question: "Which change explains the two openings in the later state?", options: ["The arch branches separate", "The ventricular wall disappears", "The opposing AV cushions fuse"], answer: 2, rationale: cushionExplanation)
        default: return nil
        }
    }
    static func investigation(stage: Int) -> String {
        switch stage {
        case 0: return "Inspect the cardiogenic region from two views. Which relationships are easier to see after rotation?"
        case 1: return "Follow each paired channel. What relationship would you compare with the next stage?"
        case 2, 3: return "Compare the tube map and looping reconstruction. What can each representation show, and what does it omit?"
        case 4, 5: return "Find an opening between regions. Compare the available states and describe what changes."
        case 6: return "Trace two neighbouring outflow structures. Separate and reassemble them to check their relationship."
        default: return "Compare the available birth-transition states. Which visible relationships change, and which physiological changes are not simulated?"
        }
    }
}

struct HeartKnowledgeRecord: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    let checkID: String
    let selectedOption: Int?
    let correct: Bool
    let explanationViewed: Bool
    // A skipped check is stored without an option and is never scored correct.
    init(check: HeartLearningPilot.Check, selectedOption: Int?, explanationViewed: Bool) {
        checkID = check.id
        self.selectedOption = selectedOption
        correct = selectedOption == check.answer
        self.explanationViewed = explanationViewed
    }
}
