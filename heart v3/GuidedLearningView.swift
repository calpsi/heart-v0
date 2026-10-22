import SwiftUI
import AVFoundation

fileprivate struct LearningCard: Identifiable {
    let id = UUID()
    let title: String
    let visualFocus: String
    let concepts: [String]
    let interaction: String
}

fileprivate struct LearningTopic: Identifiable {
    let id = UUID()
    let timing: String
    let name: String
    let summary: String
    let cards: [LearningCard]
}

@MainActor
@Observable
final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var hasFinished: Bool = false
    var currentSpokenRange: NSRange?
    var spokenCharacterCount: Int = 0

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String) {
        stop()
        hasFinished = false
        currentSpokenRange = nil
        spokenCharacterCount = 0

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        activeUtterance = utterance
        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false
    }

    func togglePlayPause(for text: String) {
        if isPlaying && !isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        } else if isPlaying && isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        } else {
            speak(text: text)
        }
    }

    func stop() {
        activeUtterance = nil
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false
        currentSpokenRange = nil
        spokenCharacterCount = 0
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.activeUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.isPlaying = true
            self.isPaused = false
            self.hasFinished = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.activeUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.isPaused = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.activeUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let totalCount = utterance.speechString.count
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.activeUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.isPlaying = false
            self.isPaused = false
            self.hasFinished = true
            self.currentSpokenRange = nil
            self.spokenCharacterCount = totalCount
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.activeUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.isPlaying = false
            self.isPaused = false
            self.currentSpokenRange = nil
            self.spokenCharacterCount = 0
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let rangeLocation = characterRange.location
        let rangeLength = characterRange.length
        let safeNSRange = NSRange(location: rangeLocation, length: rangeLength)
        let totalSoFar = rangeLocation + rangeLength

        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard self.activeUtterance.map(ObjectIdentifier.init) == utteranceID else { return }
            self.currentSpokenRange = safeNSRange
            self.spokenCharacterCount = totalSoFar
        }
    }
}

struct HeartLessonProgress: Codable, Equatable {
    struct Entry: Codable, Equatable {
        var step: Int
        var completed: Bool
    }
    private(set) var lessons: [String: Entry] = [:]

    func resumeStep(for lesson: String, stepCount: Int) -> Int {
        min(max(0, lessons[lesson]?.step ?? 0), max(0, stepCount - 1))
    }

    mutating func record(step: Int, for lesson: String, stepCount: Int) {
        lessons[lesson] = .init(step: min(max(0, step), max(0, stepCount - 1)), completed: false)
    }

    mutating func finish(_ lesson: String) {
        lessons[lesson] = .init(step: 0, completed: true)
    }
}

struct GuidedLearningView: View {
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil
    @State private var showingAnomalies = false
    @AppStorage("guidedLearning.progress") private var progressData = Data()
    @State private var selectedTopic: LearningTopic? = nil

    private var progress: HeartLessonProgress {
        get { (try? JSONDecoder().decode(HeartLessonProgress.self, from: progressData)) ?? .init() }
        nonmutating set { progressData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    private static let development: [LearningTopic] = [
        LearningTopic(
            timing: "Days 18–19",
            name: "Cardiogenic region",
            summary: "Mesodermal cells migrate to form the cardiogenic field.",
            cards: [
                LearningCard(title: "Cardiogenic C-Shape", visualFocus: "Cardiac crescent in the cranial mesoderm.", concepts: ["Progenitor cells organize into the primary heart field.", "Positioned anterior to the developing neural plate."], interaction: "Tap the crescent, then use Isolate to inspect its shape."),
                LearningCard(title: "Field Signals", visualFocus: "Endoderm and lateral mesoderm contact points.", concepts: ["Signals induce myocardial and endocardial lineages.", "Establishes the earliest anterior-posterior polarity."], interaction: "Use Separate to inspect the endoderm beside the cardiogenic tissue."),
                LearningCard(title: "Pre-Vascular Cords", visualFocus: "Endothelial cell clusters within the crescent.", concepts: ["Angioblastic cords coalesce into solid strands.", "Lumen formation begins shortly before tubulation."], interaction: "Isolate the selected angioblastic cord and drag to rotate it. This stage shows solid cords.")
            ]
        ),
        LearningTopic(
            timing: "Early tube formation · schematic",
            name: "Paired heart tubes",
            summary: "Lateral embryonic folding moves endocardial tubes into the midline.",
            cards: [
                LearningCard(title: "Lateral Folding", visualFocus: "Medial movement of the left and right endocardial tubes.", concepts: ["Lateral body folding brings the paired endocardial channels toward the ventral midline.", "Surrounding splanchnic mesoderm contributes to the myocardial mantle; epicardium develops separately later."], interaction: "Rotate the paired tubes and use Separate to inspect their tissue layers."),
                LearningCard(title: "Approaching Fusion", visualFocus: "Ventral midline seam where tubes meet.", concepts: ["Paired endocardial channels converge as the ventral heart tube forms.", "Cardiac jelly fills the space between endocardium and myocardium."], interaction: "Isolate the cardiac jelly between the inner and outer tube walls."),
                LearningCard(title: "Inflow and Outflow Poles", visualFocus: "Cranial and caudal poles; connecting vessels are not shown in this model.", concepts: ["Venous return attaches to the caudal tube.", "Aortic arches develop at the cranial end."], interaction: "Isolate the endocardial wall and rotate it to look through the tube lumen.")
            ]
        ),
        LearningTopic(
            timing: "Unfolded regional map",
            name: "Primitive heart tube segments",
            summary: "An unfolded teaching map follows the developing heart from venous inflow to arterial outflow.",
            cards: [
                LearningCard(title: "Linear Organization", visualFocus: "An unfolded map of inflow-to-outflow regions, not a single embryonic snapshot.", concepts: ["Truncus arteriosus sits at the outflow pole.", "The venous inflow region develops into the systemic venous sinus; the labelled regions do not all mature simultaneously."], interaction: "Use Parts to select each segment from sinus venosus to truncus arteriosus."),
                LearningCard(title: "Bulbus Cordis & Ventricle", visualFocus: "Mid-tube chamber precursors.", concepts: ["Bulbus cordis forms outflow components and part of right ventricle.", "Primitive ventricle will primarily form the anatomical left ventricle."], interaction: "Drag to rotate the tube and inspect the selected bulbus cordis."),
                LearningCard(title: "Early Valveless Pumping", visualFocus: "Myocardial sleeve along the tube.", concepts: ["Contractions begin during early heart-tube development.", "The endocardial lining and outer myocardium are separated by cardiac jelly; mature valve leaflets are absent."], interaction: "Use Cutaway to inspect the ventricular wall layers. Contraction is not animated.")
            ]
        ),
        LearningTopic(
            timing: "CS11 · specimen N662",
            name: "Cardiac looping (D-looping)",
            summary: "Elongation and bending produce an early C-loop, followed by more complex looping and chamber expansion.",
            cards: [
                LearningCard(title: "Rightward D-Looping", visualFocus: "Left ventricular region in the CS11 N662 reconstruction.", concepts: ["The developing tube bends rightward and ventrally as its length increases.", "In the early C-loop, the embryonic left ventricle occupies the most ventral portion of the loop."], interaction: "Rotate the CS11 reconstruction and isolate the left ventricular region. The colours identify segmented regions, not tissue layers."),
                LearningCard(title: "Atrial Translocation", visualFocus: "Common atrial region relative to the ventricular loop.", concepts: ["Atrium shifts posterior and superior to the ventricular region.", "Atrial and ventricular regions expand at different times; their eventual positions emerge progressively."], interaction: "Select the common atrial region and rotate to compare its position with the ventricular regions. This is a static specimen, not animated translocation."),
                LearningCard(title: "Outflow Relationship", visualFocus: "Reconstructed outflow region and its relationship to the ventricular loop.", concepts: ["The outflow region links the ventricular loop with the arterial pole.", "This atlas does not separately segment the AV canal or complete endocardial wall; coloured surfaces must not be interpreted as tissue thickness."], interaction: "Isolate the outflow region, then reassemble to inspect its position beside the ventricular regions.")
            ]
        ),
        LearningTopic(
            timing: "Early septation → later fetal arrangement",
            name: "Atrial septation",
            summary: "The primary septum, mesenchymal tissues and later atrial-wall infolding establish the fetal interatrial pathway.",
            cards: [
                LearningCard(title: "Septum Primum", visualFocus: "Crescent-shaped ridge growing from roof toward cushions.", concepts: ["Its mesenchymal cap joins the AV cushions and dorsal mesenchymal protrusion to close the primary opening; the cap and dorsal contribution are enlarged for inspection.", "Fenestrations appear near top, forming ostium secundum."], interaction: "Compare the early and later states; isolate the septum primum to inspect its openings."),
                LearningCard(title: "Mesenchymal Contributions", visualFocus: "Cap on the primary septal edge and dorsal protrusion beside the AV cushions.", concepts: ["The mesenchymal cap, dorsal protrusion and AV cushions participate in closing the primary atrial opening.", "The later state shows a simplified muscularized inferior contribution; these are illustrative snapshots, not measured stages."], interaction: "Isolate the dorsal contribution, then choose Mesenchymal cap in Parts. Reassemble to inspect their relationship to the cushions."),
                LearningCard(title: "Septum Secundum", visualFocus: "Two limbs of the later atrial-wall fold, right of septum primum.", concepts: ["Later atrial-wall infolding contributes to the superior rim. Its roof groove is outside the atrial cavities, not an atrial septal defect.", "Septum primum remnant acts as a one-way flap valve."], interaction: "Select the later fetal reference and isolate the fold to inspect its two wall limbs; reassemble to see the flap overlap."),
                LearningCard(title: "Right-to-Left Shunt", visualFocus: "Interatrial shunt path in fetal circulation.", concepts: ["High right atrial pressure keeps the foramen ovale open in utero.", "Directs oxygen-rich blood toward the left heart and brain."], interaction: "Rotate the later state to inspect the opening between the overlapping septa.")
            ]
        ),
        LearningTopic(
            timing: "AV canal division · schematic",
            name: "Endocardial cushion fusion",
            summary: "Superior and inferior cushions divide the common AV canal.",
            cards: [
                LearningCard(title: "Opposing Cushions", visualFocus: "Superior and inferior AV cushions swelling toward midline.", concepts: ["Composed of extracellular matrix colonized by mesenchymal cells.", "Essential for separating mitral and tricuspid orifices."], interaction: "Switch between before and after fusion to compare the opposing cushions."),
                LearningCard(title: "Two Distinct Canals", visualFocus: "Cross-section of the newly divided AV orifice.", concepts: ["Creates separate left and right atrioventricular orifices.", "Serves as the central anchor for atrial and ventricular septa."], interaction: "Rotate the fused state to look down the two AV openings."),
                LearningCard(title: "Septum Intermedium", visualFocus: "Fused cushion mass at the center of the heart.", concepts: ["Joins the mesenchymal cap and dorsal mesenchymal protrusion in closing the primary atrial opening.", "Participates in septal junctions and membranous septal formation; the muscular ventricular septum develops from myocardium."], interaction: "Select and separate the fused cushions to inspect their midline contact.")
            ]
        ),
        LearningTopic(
            timing: "Septation stages · schematic",
            name: "Ventricular septation",
            summary: "Muscular crest and membranous septum separate the left and right ventricles.",
            cards: [
                LearningCard(title: "Muscular Ridge Growth", visualFocus: "Crest arising from the apex toward the AV canal.", concepts: ["Ventricular chambers expand laterally by trabecular apposition.", "Interventricular foramen remains temporarily open superiorly."], interaction: "Isolate the muscular septum and inspect the remaining superior communication."),
                LearningCard(title: "Closing the Foramen", visualFocus: "Region between muscular crest, cushions, and conus ridges.", concepts: ["Membranous septum closes the interventricular foramen.", "Requires contributions from endocardial cushions and conal ridges."], interaction: "Switch to septal closure and isolate the membranous patch."),
                LearningCard(title: "Subaortic & Subpulmonary Paths", visualFocus: "Separate outflow tracts from left and right ventricles.", concepts: ["Left ventricle connects toward the future ascending aorta.", "Right ventricle channels into the pulmonary infundibulum."], interaction: "Rotate the closure state and select each outlet.")
            ]
        ),
        LearningTopic(
            timing: "CS18 · specimen N1645",
            name: "Outflow tract septation",
            summary: "Inspect the outflow and arterial relationships in a stage-specific human reconstruction.",
            cards: [
                LearningCard(title: "Reconstructed Outflow", visualFocus: "Outflow region in the CS18 N1645 specimen.", concepts: ["Outflow development involves cushion fusion and remodeling of surrounding tissues, not a rigid partition turning through a fixed angle.", "This reconstruction shows anatomical regions at one stage; it does not separately segment cushion cells or tissue-wall layers."], interaction: "Isolate the outflow region, then reassemble to inspect its position relative to the ventricles."),
                LearningCard(title: "Aortic Relationship", visualFocus: "Aortic region relative to the ventricular and outflow regions.", concepts: ["The developing aortic pathway must be understood in relation to the ventricular outflow and adjacent pulmonary pathway.", "The source colours identify regions; their boundaries do not represent natural dissection planes."], interaction: "Select the aortic region and rotate the assembled model. Use Regions to separate the labelled structures."),
                LearningCard(title: "Pulmonary Relationship", visualFocus: "Pulmonary trunk beside the aortic and ductal regions.", concepts: ["The pulmonary and aortic regions have distinct spatial relationships in this specimen.", "Individual valve cusps and septal tissue layers are not segmented here; their absence from this view does not mean they are absent in the embryo."], interaction: "Isolate the pulmonary trunk, then reassemble and select the ductus arteriosus to inspect its relationship to the arterial regions.")
            ]
        ),
        LearningTopic(
            timing: "Embryonic formation → later maturation",
            name: "Valvular refinement",
            summary: "Early cushions remodel into leaflets; later-anatomy views show subsequent valve maturation.",
            cards: [
                LearningCard(title: "AV Leaflet Delamination", visualFocus: "Ventricular myocardium undermining cushion-derived flaps.", concepts: ["Chamber wall excavates beneath cushion tissue to free leaflets.", "Forms tricuspid (anterior/posterior/septal) and mitral valves."], interaction: "Compare thickened cushions with refined leaflets, then isolate an AV leaflet."),
                LearningCard(title: "Later Chordae & Papillary Muscles", visualFocus: "Later-anatomy reference: branching cords linking leaflet margins to papillary muscles.", concepts: ["Papillary muscles develop through remodeling of ventricular myocardium; each mitral muscle supports both leaflets through branching chordae.", "Chordal tension helps prevent leaflet prolapse during systole. Branch counts and thickness in this reference are illustrative."], interaction: "In the later-anatomy reference, select a chord and its papillary muscle to inspect their attachment."),
                LearningCard(title: "Later Valve Tissue Layers", visualFocus: "Later-anatomy reference: three tissue layers within a pocket-shaped aortic cusp.", concepts: ["Valve matrix and cell populations continue to mature through fetal and postnatal life.", "These enlarged layers illustrate later organization, not a completed three-layer valve at weeks 5–8."], interaction: "Separate the reference cusp layers, then reassemble and inspect the curved attachment to the sinus wall. The cusp is shown partly open.")
            ]
        ),
        LearningTopic(
            timing: "At Birth",
            name: "Circulatory transition",
            summary: "First breath triggers dramatic pressure changes, closing fetal shunts.",
            cards: [
                LearningCard(title: "First Breath & PVR Drop", visualFocus: "Lung expansion and sudden drop in pulmonary vascular resistance.", concepts: ["Pulmonary vessels dilate, multiplying flow to left atrium.", "Left atrial pressure rises above right atrial pressure."], interaction: "Compare the before-birth and transitioning states; show or hide lung context."),
                LearningCard(title: "Foramen Ovale Closure", visualFocus: "Septum primum pressing firmly against septum secundum.", concepts: ["Functional closure occurs within minutes to hours.", "Later anatomical fusion is variable; incomplete fusion can leave a patent foramen ovale, distinct from an ASD."], interaction: "Select and isolate the atrial flap to compare opening and apposition."),
                LearningCard(title: "Ductus Arteriosus Constriction", visualFocus: "Muscular wall contraction in the ductus arteriosus.", concepts: ["Elevated oxygen tension and loss of placental prostaglandins trigger constriction.", "Remodels into the fibrous ligamentum arteriosum."], interaction: "Compare the patent and constricting ductus. The later snapshot retains a narrow lumen.")
            ]
        )
    ]

    private static let anomalies: [LearningTopic] = [
        LearningTopic(timing: "Card 10.1", name: "Ventricular Septal Defect (VSD)",
            summary: "Inspect a perimembranous opening between the ventricles and compare an intact septum.", cards: [
                LearningCard(title: "Find the Opening", visualFocus: "Upper ventricular septum beneath the aortic root.", concepts: ["This illustrates an intended perimembranous VSD location; its complete fibrous borders are not reconstructed.", "An opening crosses the partition between the ventricular cavities."], interaction: "Rotate the cutaway and isolate the septal rim to inspect the opening."),
                LearningCard(title: "Compare the Septum", visualFocus: "Intact tissue at the same septal location.", concepts: ["The intact comparison fills the opening with septal tissue.", "These are structural alternatives, not a repair sequence."], interaction: "Switch between Perimembranous VSD and Intact septum; separate the tissue to inspect its margins."),
                LearningCard(title: "Nearby Valve Landmarks", visualFocus: "Tricuspid septal leaflet and aortic root.", concepts: ["Perimembranous defects lie near aortic and tricuspid valve structures.", "The model illustrates position; shunt flow and pressure are not simulated."], interaction: "Select the tricuspid septal leaflet, then reassemble the model to see its relation to the defect.")
            ]),
        LearningTopic(timing: "Card 10.2", name: "Tetralogy of Fallot",
            summary: "Inspect four characteristic structural features and compare a normal arrangement.", cards: [
                LearningCard(title: "Outlet Septal Displacement", visualFocus: "Outlet septal muscle displaced anteriorly and cranially above the VSD.", concepts: ["Fallot includes a ventricular septal defect beneath the overriding aorta.", "The displaced outlet septum contributes to subpulmonary narrowing; abnormal septoparietal trabeculations also matter and are not reconstructed here."], interaction: "Isolate the outlet septum, then reassemble and compare its position with Normal comparison. The displacement is illustrative, not a measured severity."),
                LearningCard(title: "Narrowed Pulmonary Outflow", visualFocus: "The narrowed channel leaving the right ventricle.", concepts: ["Right ventricular outflow obstruction is a key feature of Fallot.", "The cutaway exposes the smaller lumen; flow and severity are not simulated."], interaction: "Compare Fallot with Normal comparison, keeping Cutaway on to inspect the channel."),
                LearningCard(title: "Overriding Aorta", visualFocus: "Aortic mouth positioned across the septal crest.", concepts: ["The aortic root straddles the ventricular septum in this illustration.", "The comparison connects the aorta to the left ventricle."], interaction: "Separate the aorta to inspect its open mouth, then reassemble and compare its position."),
                LearningCard(title: "Thickened Right Wall", visualFocus: "Right ventricular muscle in the removable wall panels.", concepts: ["Right ventricular hypertrophy is the fourth characteristic feature and develops with pressure loading; it is not an initiating septation defect.", "The comparison keeps the outer envelope similar while changing wall thickness."], interaction: "Inspect the cut edge of the right wall and switch to Normal comparison.")
            ]),
        LearningTopic(timing: "Card 10.3", name: "Transposition of the Great Arteries (TGA)",
            summary: "Follow the ventricular origins of the great arteries in d-TGA and compare normal connections.", cards: [
                LearningCard(title: "Aorta from the Right", visualFocus: "Aortic root arising from the right ventricular cavity.", concepts: ["In d-TGA, the aorta connects to the right ventricle.", "Its proximal course lies anterior and to the right of the pulmonary trunk here. Ventricular identity depends on morphology, not position alone; that morphology is simplified in this model."], interaction: "Isolate the aorta to follow its root, then reassemble to identify its ventricle."),
                LearningCard(title: "Pulmonary Trunk from the Left", visualFocus: "Pulmonary root entering the left ventricular cavity.", concepts: ["The pulmonary trunk connects to the left ventricle.", "These connections support parallel circulations; complete return pathways are not shown."], interaction: "Select and separate the pulmonary trunk, then rotate to inspect its ventricular origin."),
                LearningCard(title: "An Atrial Mixing Route", visualFocus: "An illustrative opening between the atrial cavities.", concepts: ["Communication between the two circulations permits mixing.", "This example includes an atrial opening, not every possible associated pathway."], interaction: "Isolate the atrial septum to see the real opening, then reassemble the atrial walls."),
                LearningCard(title: "Compare the Connections", visualFocus: "Normal aorta-to-left and pulmonary-to-right ventricular connections.", concepts: ["The normal comparison changes both artery origins and closes the illustrative atrial opening.", "The two states compare anatomy, not surgery or a flow simulation."], interaction: "Switch between d-TGA and Normal connections and follow each named artery to its ventricle.")
            ]),
        LearningTopic(timing: "Card 10.4", name: "Atrial Septal Defect (ASD)",
            summary: "Inspect a secundum defect in the oval fossa and compare an intact atrial septum.", cards: [
                LearningCard(title: "Find the Deficiency", visualFocus: "Opening in the floor of the oval fossa.", concepts: ["This model shows a secundum ASD in the central atrial septum.", "The opening represents deficient tissue, rather than a patent foramen ovale flap."], interaction: "Isolate the oval fossa floor and rotate it to look through the opening."),
                LearningCard(title: "Compare the Floor", visualFocus: "An intact oval fossa floor.", concepts: ["The intact comparison has a continuous tissue floor.", "The same surrounding geometry keeps attention on the structural difference."], interaction: "Switch between Secundum ASD and Intact septum, then separate the floor from its rim."),
                LearningCard(title: "Orient the Atria", visualFocus: "Oval fossa rim between right and left atrial cavities.", concepts: ["The defect permits communication between the atria.", "Flow, chamber enlargement and other ASD subtypes are outside this regional model."], interaction: "Reassemble, inspect the rim and rotate between the two atrial sides.")
            ]),
        LearningTopic(timing: "Card 10.5", name: "Coarctation of the Aorta",
            summary: "Inspect a localized aortic narrowing near the ductal attachment and compare an open lumen.", cards: [
                LearningCard(title: "Find the Narrowing", visualFocus: "Aortic isthmus just beyond the left subclavian branch.", concepts: ["This regional example shows a localized coarctation.", "The cutaway exposes an eccentric narrowing of the channel."], interaction: "Isolate the isthmus and rotate it to inspect the narrowed lumen."),
                LearningCard(title: "Compare the Channel", visualFocus: "The same aortic segment with an open comparison lumen.", concepts: ["The comparison preserves the outer vessel size while widening the lumen.", "Dimensions are illustrative and do not grade clinical severity."], interaction: "Switch between Coarctation and Open comparison with Cutaway on."),
                LearningCard(title: "Ductal Landmark", visualFocus: "Ligamentum arteriosum near the narrowed segment.", concepts: ["Coarctation commonly lies near the ductal attachment.", "This example shows a closed remnant; pressure gradients and collateral vessels are not modeled."], interaction: "Select the ligament, then reassemble and inspect its position beside the isthmus."),
                LearningCard(title: "Orient the Arch", visualFocus: "The left subclavian branch upstream of the isthmus.", concepts: ["Three separate arch branches provide orientation.", "The vessel model is regional; it omits the chambers and complete distal circulation."], interaction: "Follow the left subclavian branch back to the arch and rotate toward the descending aorta.")
            ]),
        LearningTopic(timing: "Card 10.6", name: "Patent Ductus Arteriosus (PDA)",
            summary: "Inspect an open ductal connection and compare the anatomically closed remnant.", cards: [
                LearningCard(title: "A Persistent Connection", visualFocus: "A hollow duct between the pulmonary artery and aorta.", concepts: ["PDA retains the ductal connection after birth.", "The cutaway shows a continuous opening between the vessel lumens."], interaction: "Isolate the ductal wall, then reassemble to inspect both junctions."),
                LearningCard(title: "Pulmonary Junction", visualFocus: "The ductal mouth near the left pulmonary branch.", concepts: ["The connection opens into the pulmonary arterial lumen.", "Flow direction and pressure are not simulated by this static model."], interaction: "Select the pulmonary trunk and separate it from the duct to inspect the junction."),
                LearningCard(title: "Closed Remnant", visualFocus: "The ligamentum arteriosum between continuous vessel walls.", concepts: ["The closed comparison has no ductal lumen and restores both parent-vessel walls.", "It depicts an anatomical endpoint, not instant closure at birth or a treatment sequence."], interaction: "Switch between Patent ductus and Closed remnant; inspect the ligament and aortic wall.")
            ])
    ]

    var body: some View {
        Group {
            if let topic = selectedTopic {
                GuidedTopicDetailView(topic: topic, onDismiss: { selectedTopic = nil }, onComplete: {
                    var updated = progress
                    updated.finish(topic.name)
                    progress = updated
                }, currentCardIndex: Binding(
                    get: { progress.resumeStep(for: topic.name, stepCount: topic.cards.count) },
                    set: { step in
                        var updated = progress
                        updated.record(step: step, for: topic.name, stepCount: topic.cards.count)
                        progress = updated
                    }
                ))
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 20) {
                        SpatialBackButton(title: "Home") { if let onBack { onBack() } else { dismiss() } }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Guided Learning").font(.largeTitle.bold())
                            Text("Follow the heart from its first cells to birth.").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        let completed = (Self.development + Self.anomalies).filter { progress.lessons[$0.name]?.completed == true }.count
                        let total = Self.development.count + Self.anomalies.count
                        Text("\(completed) of \(total) lessons completed").font(.subheadline.weight(.semibold))
                            .accessibilityIdentifier("learning.overallProgress")
                        ProgressView(value: Double(completed), total: Double(total))
                            .tint(Color.accentColor)
                            .accessibilityLabel("Overall learning progress")
                    }
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    SpatialChoicePicker(title: "Lesson category", selection: Binding(
                        get: { showingAnomalies ? "anomalies" : "development" },
                        set: { showingAnomalies = $0 == "anomalies" }
                    ), choices: [
                        .init(id: "development", title: "Development"),
                        .init(id: "anomalies", title: "Anomalies")
                    ]).frame(width: 360)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 290), spacing: 16)], spacing: 16) {
                            ForEach(showingAnomalies ? Self.anomalies : Self.development) { topic in
                                Button { selectedTopic = topic } label: {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(topic.timing).font(.caption.weight(.semibold)).foregroundStyle(Color.accentColor)
                                            Spacer()
                                            Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                                        }
                                        HStack(spacing: 12) {
                                            Image(HeartAsset.teachingAsset(for: topic.name)
                                                .map { $0.artworkName } ?? "GuidedHeart")
                                                .resizable().scaledToFit().frame(width: 76, height: 76)
                                                .accessibilityHidden(true)
                                            Text(topic.name).font(.title3.bold()).lineLimit(3)
                                        }
                                        Text(topic.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                                        Spacer(minLength: 0)
                                        ProgressView(
                                            value: progress.lessons[topic.name]?.completed == true
                                                ? Double(topic.cards.count)
                                                : Double(progress.resumeStep(for: topic.name, stepCount: topic.cards.count)),
                                            total: Double(max(1, topic.cards.count))
                                        )
                                        .tint(Color.accentColor)
                                        .accessibilityLabel("\(topic.name) saved progress")
                                        HStack {
                                            if progress.lessons[topic.name]?.completed == true {
                                                Label("Completed · Review", systemImage: "checkmark.circle")
                                            } else if progress.resumeStep(for: topic.name, stepCount: topic.cards.count) > 0 {
                                                Text("Continue · Step \(progress.resumeStep(for: topic.name, stepCount: topic.cards.count) + 1)/\(topic.cards.count)")
                                            } else {
                                                Text("\(topic.cards.count) steps")
                                            }
                                            Spacer()
                                            Label(HeartAsset.all.contains(where: { $0.lesson == topic.name }) ? "3D ready" : "Lesson only",
                                                  systemImage: "cube.transparent")
                                        }.font(.caption).foregroundStyle(.secondary)
                                    }
                                    .padding(22).frame(maxWidth: .infinity, minHeight: 260, maxHeight: 260, alignment: .topLeading)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
                                    .contentShape(RoundedRectangle(cornerRadius: 24))
                                }.buttonStyle(.plain).hoverEffect(.highlight)
                                    .accessibilityLabel(topic.name)
                                    .accessibilityHint(topic.summary)
                            }
                        }.padding(.vertical, 4)
                    }
                    Text("Timings use post-fertilization age.").font(.caption).foregroundStyle(.secondary)
                }
                .padding(32)
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 36))
            }
        }
        .frame(minWidth: 1060, idealWidth: 1140, maxWidth: .infinity,
               minHeight: 700, idealHeight: 780, maxHeight: .infinity)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-lesson-list") { return }
            if ProcessInfo.processInfo.arguments.contains("--preview-guided"), selectedTopic == nil {
                let args = ProcessInfo.processInfo.arguments
                if let index = args.firstIndex(of: "--preview-anomaly"), index + 1 < args.count,
                   let lesson = Int(args[index + 1]), Self.anomalies.indices.contains(lesson) {
                    showingAnomalies = true
                    selectedTopic = Self.anomalies[lesson]
                } else if let index = args.firstIndex(of: "--preview-lesson"), index + 1 < args.count,
                   let lesson = Int(args[index + 1]), Self.development.indices.contains(lesson) {
                    selectedTopic = Self.development[lesson]
                } else { selectedTopic = Self.development[0] }
            }
            #endif
        }
    }

}

private func anomaly(_ timing: String, _ name: String, _ summary: String, _ focus: String, _ concepts: [String], _ interaction: String) -> LearningTopic {
    LearningTopic(timing: timing, name: name, summary: summary, cards: [LearningCard(title: "Explore \(name)", visualFocus: focus, concepts: concepts, interaction: interaction)])
}

struct GuidedTopicDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    fileprivate let topic: LearningTopic
    var onDismiss: (() -> Void)? = nil
    var onComplete: (() -> Void)? = nil

    @State private var speechManager = SpeechManager()
    @Binding var currentCardIndex: Int
    @State private var narrationEnabled = false
    @State private var showingCaptions = false
    @State private var showingLesson = true
    @State private var modelAction: HeartModelActionRequest?

    private var modelAsset: HeartAsset? { HeartAsset.teachingAsset(for: topic.name) }

    private var currentCard: LearningCard {
        topic.cards[currentCardIndex]
    }

    private var modelStep: HeartLessonStep? {
        guard let asset = HeartAsset.teachingAsset(for: topic.name) else { return nil }
        let steps = HeartLessonStep.steps(for: asset)
        return steps.indices.contains(currentCardIndex) ? steps[currentCardIndex] : nil
    }

    private var voiceoverScript: String {
        "\(currentCard.title). \(currentCard.visualFocus) \(currentCard.concepts.joined(separator: " "))"
    }

    private var attributedScript: AttributedString {
        let script = voiceoverScript
        var attr = AttributedString(script)
        attr.foregroundColor = .secondary

        if speechManager.hasFinished {
            attr.foregroundColor = .primary
            return attr
        }

        if let currentRange = speechManager.currentSpokenRange,
           let scriptRange = Range(currentRange, in: script) {
            let beforeNSRange = NSRange(location: 0, length: currentRange.location)
            if let beforeRange = Range(beforeNSRange, in: script),
               let attrBefore = Range(beforeRange, in: attr) {
                attr[attrBefore].foregroundColor = .primary
            }

            if let attrCurrent = Range(scriptRange, in: attr) {
                attr[attrCurrent].foregroundColor = .accentColor
                attr[attrCurrent].inlinePresentationIntent = .stronglyEmphasized
            }
        } else if speechManager.spokenCharacterCount > 0 {
            let length = min(speechManager.spokenCharacterCount, script.count)
            let beforeNSRange = NSRange(location: 0, length: length)
            if let beforeRange = Range(beforeNSRange, in: script),
               let attrBefore = Range(beforeRange, in: attr) {
                attr[attrBefore].foregroundColor = .primary
            }
        }

        return attr
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                SpatialBackButton(title: "Lessons") { dismissView() }
                VStack(alignment: .leading, spacing: 4) {
                    Text("GUIDED LEARNING").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                    Text(topic.name).font(.title2.bold()).lineLimit(2)
                    if !showingLesson {
                        Text(currentCard.title).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 14)
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
                Spacer()
                if !showingLesson {
                    narrationButton.labelStyle(.iconOnly)
                    compactStepNavigation
                }
                Button {
                    showingLesson.toggle()
                } label: {
                    Label(showingLesson ? "Hide lesson" : "Show lesson", systemImage: "sidebar.right")
                        .foregroundStyle(.black)
                        .frame(minHeight: 44)
                }.buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Phase \(currentCardIndex + 1) of \(topic.cards.count)").font(.headline.monospacedDigit())
                        .accessibilityIdentifier("learning.phaseProgress")
                    Spacer()
                    Text("\(Int(Double(currentCardIndex + 1) / Double(max(1, topic.cards.count)) * 100))% through this lesson")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    ForEach(topic.cards.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentCardIndex ? Color.accentColor : Color.white.opacity(0.18))
                            .frame(height: 8)
                    }
                }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Lesson position")
                    .accessibilityValue("Phase \(currentCardIndex + 1) of \(topic.cards.count)")
                phaseNavigation
            }
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

            HStack(alignment: .center, spacing: 24) {
                Group {
                    if let asset = HeartAsset.teachingAsset(for: topic.name) {
                        HeartModelView(asset: asset, lessonStep: modelStep, detailControlsAtBottom: true,
                                       actionRequest: modelAction).id(asset.id)
                    } else {
                        HeartModelUnavailableView(title: topic.name)
                            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showingLesson {
                    lessonPanel
                        .frame(width: 340)
                        .frame(maxHeight: .infinity)
                }
            }

        }
        .padding(28)
        .onAppear {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "--preview-step"), index + 1 < args.count,
               let step = Int(args[index + 1]), topic.cards.indices.contains(step) { currentCardIndex = step }
            if args.contains("--preview-hide-lesson") { showingLesson = false }
            #endif
        }
        .task(id: currentCardIndex) {
            if narrationEnabled { speechManager.speak(text: voiceoverScript) }
            else { speechManager.stop() }
        }
        .onDisappear { speechManager.stop() }
    }

    private var phaseNavigation: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(topic.cards.indices, id: \.self) { index in
                        Button { changeCard(by: index - currentCardIndex) } label: {
                            HStack(spacing: 8) {
                                Text("\(index + 1)").font(.subheadline.monospacedDigit().bold())
                                    .frame(width: 28, height: 28)
                                    .background(.white.opacity(0.14), in: Circle())
                                Text(topic.cards[index].title).font(.subheadline)
                            }
                            .padding(.horizontal, 12).frame(minHeight: 52)
                            .background(index == currentCardIndex ? Color.accentColor.opacity(0.3) : .clear,
                                        in: Capsule())
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Phase \(index + 1) of \(topic.cards.count): \(topic.cards[index].title)")
                        .accessibilityAddTraits(index == currentCardIndex ? .isSelected : [])
                        .id(index)
                    }
                }.padding(8)
            }
            .scrollIndicators(.hidden)
            .glassBackgroundEffect(in: Capsule())
            .onChange(of: currentCardIndex, initial: true) { _, index in
                reader.scrollTo(index, anchor: .center)
            }
        }.fixedSize(horizontal: false, vertical: true)
    }

    private var lessonPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(topic.timing).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Text("\(currentCardIndex + 1) / \(topic.cards.count)").font(.subheadline.monospacedDigit())
                narrationButton.labelStyle(.iconOnly)
                captionsButton
            }
            HStack(spacing: 6) {
                ForEach(topic.cards.indices, id: \.self) { index in
                    Capsule().fill(index <= currentCardIndex ? Color.accentColor : Color.white.opacity(0.18)).frame(height: 4)
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(currentCard.title).font(.system(size: 28, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                    Text(currentCard.visualFocus).font(.body).foregroundStyle(.secondary)
                    ForEach(Array(currentCard.concepts.enumerated()), id: \.offset) { index, concept in
                        HStack(alignment: .top, spacing: 12) {
                            Text(String(format: "%02d", index + 1)).font(.caption.monospacedDigit()).foregroundStyle(Color.accentColor).padding(.top, 4)
                            Text(concept).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if showingCaptions {
                        Divider()
                        Text("NARRATION").font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(.secondary)
                        Text(attributedScript).font(.subheadline)
                    }
            VStack(alignment: .leading, spacing: 8) {
                Label("Try this", systemImage: "hand.point.up.left").font(.subheadline.weight(.semibold))
                Text(currentCard.interaction).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                if let asset = modelAsset, modelStep != nil {
                    HStack(spacing: 4) {
                        SpatialToolButton(title: "Focus", symbol: "scope") { requestModelAction(.focus) }
                            .frame(maxWidth: .infinity)
                            .accessibilityHint("Restore this step and enlarge its selected tissue.")
                        SpatialToolButton(title: asset.category == "reference" ? "Regions" : "Layers", symbol: "square.3.layers.3d") { requestModelAction(.layers) }
                            .frame(maxWidth: .infinity)
                            .accessibilityHint(asset.category == "reference" ? "Restore this step and separate its anatomical regions." : "Restore this step and separate its tissue layers.")
                        if let states = asset.states, states.count > 1 {
                            SpatialToolButton(title: "Compare", symbol: "arrow.left.arrow.right") { requestModelAction(.compare) }
                                .frame(maxWidth: .infinity)
                                .accessibilityHint("Switch anatomical state while keeping the current viewing angle.")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .id(currentCardIndex)


            Divider()
            stepNavigation
        }
        .padding(22)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32))
    }

    private var compactStepNavigation: some View {
        HStack(spacing: 12) {
            Button { changeCard(by: -1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }.disabled(currentCardIndex == 0).accessibilityLabel("Previous step")
            Text("\(currentCardIndex + 1) / \(topic.cards.count)").font(.subheadline.monospacedDigit())
            Button {
                if currentCardIndex == topic.cards.count - 1 { finishLesson() }
                else { changeCard(by: 1) }
            } label: {
                Image(systemName: currentCardIndex == topic.cards.count - 1 ? "checkmark" : "chevron.right")
                    .frame(width: 44, height: 44)
            }.accessibilityLabel(currentCardIndex == topic.cards.count - 1 ? "Finish lesson" : "Next step")
        }.buttonStyle(.bordered)
    }

    private var captionsButton: some View {
        Button { showingCaptions.toggle() } label: {
            Image(systemName: "captions.bubble")
                .foregroundStyle(showingCaptions ? Color.accentColor : .white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(showingCaptions ? 0.18 : 0.08), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showingCaptions ? "Hide narration" : "Show narration")
    }

    private var narrationButton: some View {
        Button {
            narrationEnabled = !(speechManager.isPlaying && !speechManager.isPaused)
            speechManager.togglePlayPause(for: voiceoverScript)
        } label: {
            Label(speechManager.isPlaying && !speechManager.isPaused ? "Pause" : "Listen",
                  systemImage: speechManager.isPlaying && !speechManager.isPaused ? "pause.fill" : "play.fill")
                .foregroundStyle(.black)
                .frame(minHeight: 44)
        }.buttonStyle(.bordered)
            .accessibilityLabel(speechManager.isPlaying && !speechManager.isPaused ? "Pause narration"
                : speechManager.isPaused ? "Resume narration" : "Play narration")
    }

    private var stepNavigation: some View {
        HStack(spacing: 12) {
            Button { changeCard(by: -1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .disabled(currentCardIndex == 0)
            .accessibilityLabel("Previous step")
            Button {
                if currentCardIndex == topic.cards.count - 1 { finishLesson() }
                else { changeCard(by: 1) }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(currentCardIndex == topic.cards.count - 1 ? "Finish lesson" : "Next phase")
                        if currentCardIndex + 1 < topic.cards.count {
                            Text(topic.cards[currentCardIndex + 1].title).font(.caption).lineLimit(2)
                        }
                    }
                    Spacer()
                    Image(systemName: currentCardIndex == topic.cards.count - 1 ? "checkmark" : "arrow.right")
                }.frame(minHeight: 44)
            }.buttonStyle(.borderedProminent).tint(Color.accentColor).foregroundStyle(.black)
            .accessibilityLabel(currentCardIndex == topic.cards.count - 1 ? "Finish lesson" : "Next phase")
        }
    }

    private func requestModelAction(_ action: HeartModelAction) {
        modelAction = HeartModelActionRequest(action: action)
    }

    private func changeCard(by offset: Int) {
        speechManager.stop()
        showingCaptions = false
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            currentCardIndex = max(0, min(topic.cards.count - 1, currentCardIndex + offset))
        }
    }

    private func finishLesson() {
        onComplete?()
        dismissView()
    }

    private func dismissView() {
        speechManager.stop()
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

#Preview(windowStyle: .plain) {
    GuidedLearningView()
}
