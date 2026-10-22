import SwiftUI
import RealityKit
import RealityKitContent
import Foundation
import simd
import UIKit

struct HeartAsset: Decodable, Identifiable {
    struct Part: Decodable, Identifiable {
        let id: String
        let label: String
        let category: String
        let state: String?
        let separationOffset: [Float]?
    }
    let id: String
    let lesson: String
    let stageIndex: Int
    let category: String?
    let parts: [Part]
    struct DevelopmentState: Decodable, Identifiable {
        let id: String
        let label: String
    }
    let states: [DevelopmentState]?
    let defaultState: String?
    let defaultCutaway: Bool?
    let defaultYaw: Float?
    let defaultPitch: Float?
    let previewImage: String?
    let presentationNote: String?
    let shortName: String?
    struct AnatomyReview: Decodable {
        let scope: String
        let supports: String
        let limitations: String
    }
    let anatomyReview: AnatomyReview?

    var isAnomaly: Bool { category == "anomaly" }

    var artworkName: String { previewImage ?? String(format: "Stage%02d", stageIndex + 1) }

    func includes(_ part: Part, state: String?) -> Bool {
        part.state == nil || part.state == (state ?? defaultState)
    }

    static let all: [HeartAsset] = {
        guard let url = Bundle.main.url(forResource: "HeartModels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let assets = try? JSONDecoder().decode([HeartAsset].self, from: data) else {
            assertionFailure("HeartModels.json is missing or invalid")
            return []
        }
        return assets
    }()

    static let referenceModels: [HeartAsset] = {
        guard let url = Bundle.main.url(forResource: "HeartReferenceModels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let assets = try? JSONDecoder().decode([HeartAsset].self, from: data) else { return [] }
        return assets
    }()

    static var allIncludingReferences: [HeartAsset] { referenceModels + all }

    static func teachingAsset(for lesson: String) -> HeartAsset? {
        // Use observed regional geometry for looping; the old tissue illustration
        // remains separately available for comparison in free exploration.
        if lesson == "Cardiac looping (D-looping)",
           let reconstruction = referenceModels.first(where: { $0.id == "HDBR_CS11_N662" }) {
            return reconstruction
        }
        if lesson == "Outflow tract septation",
           let reconstruction = referenceModels.first(where: { $0.id == "HDBR_CS18_N1645" }) {
            return reconstruction
        }
        return all.first { $0.lesson == lesson }
    }


    var hasCutaway: Bool { parts.contains { $0.id.hasSuffix("_Anterior") } }
    var usesSchematicView: Bool { stageIndex < 3 && !isAnomaly }

    var hasContext: Bool { parts.contains { $0.category == "context" } }
}

struct HeartLessonStep: Equatable {
    let focus: String
    let state: String?

    static func steps(for asset: HeartAsset) -> [HeartLessonStep] {
        if asset.id == "HDBR_CS11_N662" {
            return ["CS11_N662_left_ventricle", "CS11_N662_atria", "CS11_N662_outflow_tract"].map {
                HeartLessonStep(focus: $0, state: nil)
            }
        }
        if asset.id == "HDBR_CS18_N1645" {
            return ["CS18_cs18_N1645_outflow_tract", "CS18_cs18_N1645_aorta", "CS18_cs18_N1645_pulmonary"].map {
                HeartLessonStep(focus: $0, state: nil)
            }
        }
        let parts: [String]
        switch asset.lesson {
        case "Cardiogenic region":
            parts = ["CardiogenicCrescent", "Endoderm_Context", "AngioblasticCord_L"]
        case "Paired heart tubes":
            parts = ["Myocardium_L_Anterior", "CardiacJelly_L_Posterior", "Endocardium_L_Posterior"]
        case "Primitive heart tube segments":
            parts = ["Myocardium_SinusVenosus_Anterior", "Myocardium_BulbusCordis_Anterior", "Myocardium_PrimitiveVentricle_Anterior"]
        case "Cardiac looping (D-looping)":
            parts = ["Myocardium_BulbusCordis_Anterior", "Myocardium_PrimitiveAtrium_Anterior", "Endocardium_AVCanal_Posterior"]
        case "Atrial septation":
            parts = ["SeptumPrimum_Early", "DorsalMesenchymalProtrusion_Early", "SeptumSecundum_Later", "SeptumPrimum_Later"]
        case "Endocardial cushion fusion":
            parts = ["CushionSuperior_Unfused", "CushionSuperior_Fused", "CushionInferior_Fused"]
        case "Ventricular septation":
            parts = ["MuscularSeptum_Open", "MembranousSeptum_Closed", "SubaorticOutlet_Posterior"]
        case "Outflow tract septation":
            parts = ["SeptalRidge_Ridges", "SeptalRidge_Divided", "AorticCuspPrimordium_1"]
        case "Valvular refinement":
            parts = ["Mitral_Anterior_Cushions", "MitralChord_1_1", "Fibrosa_AorticCusp1_Refined"]
        case "Circulatory transition":
            parts = ["Ductus_Fetal", "ForamenFlap_Transition", "Ductus_Transition"]
        case "Ventricular Septal Defect (VSD)":
            parts = ["OutletSeptalContribution", "MembranousSeptum_Closed", "TricuspidSeptalLeaflet"]
        case "Atrial Septal Defect (ASD)":
            parts = ["FossaFloor_Defect", "FossaFloor_Intact", "AtrialSeptalRim"]
        case "Tetralogy of Fallot":
            parts = ["OutletSeptum_Fallot", "RVOutflow_Fallot_Posterior", "Aorta_Fallot", "VentricularWall_R_Fallot_Posterior"]
        case "Transposition of the Great Arteries (TGA)":
            parts = ["Aorta_Tga", "PulmonaryTrunk_Tga", "AtrialSeptum_Tga", "Aorta_Normal"]
        case "Coarctation of the Aorta":
            parts = ["AorticIsthmus_Coarctation_Posterior", "AorticIsthmus_Normal_Posterior", "Ligamentum", "LeftSubclavian_Posterior"]
        case "Patent Ductus Arteriosus (PDA)":
            parts = ["Ductus_Patent_Posterior", "PulmonaryTrunk_Patent", "Ligamentum_Closed"]
        default: return []
        }
        let states: [String]
        switch asset.lesson {
        case "Atrial septation": states = ["early", "early", "later", "later"]
        case "Endocardial cushion fusion": states = ["unfused", "fused", "fused"]
        case "Ventricular septation": states = ["open", "closed", "closed"]
        case "Outflow tract septation": states = ["ridges", "divided", "divided"]
        case "Valvular refinement": states = ["cushions", "refined", "refined"]
        case "Circulatory transition": states = ["fetal", "transition", "transition"]
        case "Ventricular Septal Defect (VSD)", "Atrial Septal Defect (ASD)": states = ["defect", "intact", "defect"]
        case "Tetralogy of Fallot": states = ["fallot", "fallot", "fallot", "fallot"]
        case "Transposition of the Great Arteries (TGA)": states = ["tga", "tga", "tga", "normal"]
        case "Coarctation of the Aorta": states = ["coarctation", "normal", "coarctation", "coarctation"]
        case "Patent Ductus Arteriosus (PDA)": states = ["patent", "patent", "closed"]
        default: states = []
        }
        return parts.enumerated().map { index, focus in
            HeartLessonStep(focus: focus, state: states.indices.contains(index) ? states[index] : asset.defaultState)
        }
    }
}

enum HeartModelAction: Equatable {
    case focus, layers, compare
}

struct HeartModelActionRequest: Equatable {
    let id = UUID()
    let action: HeartModelAction
}

/// Shared by the viewer and regression checks so restoring a step is atomic.
enum HeartModelZoom {
    static let range: ClosedRange<Double> = 0.4...4
    static let overviewMaximum: Double = 1.25

    static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 1 }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}

struct HeartModelControls: Codable, Hashable {
    var selectedPart = ""
    var isolate = false
    var cutaway = false
    var developmentState: String?
    var showContext = true
    var transparent = false
    var showBackdrop = true
    var showLabels = true
    var showOrientation = true
    var separation: Double = 0
    var yaw: Float = 0
    var pitch: Float = 0
    var zoom: Double = 1
    private var dragOrientation: SIMD4<Float>?
    var orientation: simd_quatf {
        if let value = dragOrientation { return simd_normalize(simd_quatf(vector: value)) }
        return simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: pitch, axis: [1, 0, 0])
    }
    mutating func rotate(from start: simd_quatf, horizontal: Float, vertical: Float) {
        let delta = simd_quatf(angle: vertical * 0.005, axis: [1, 0, 0])
            * simd_quatf(angle: horizontal * 0.005, axis: [0, 1, 0])
        dragOrientation = simd_normalize(delta * start).vector
    }
    mutating func setOrientation(yaw: Float, pitch: Float) {
        dragOrientation = nil
        self.yaw = yaw; self.pitch = pitch
    }
    // Optional storage keeps previously saved close-up windows decodable.
    private var movablePartsEnabled: Bool?
    private var detachedPartPositions: [String: SIMD3<Float>]?
    var moveParts: Bool {
        get { movablePartsEnabled ?? false }
        set { movablePartsEnabled = newValue }
    }
    var partOffsets: [String: SIMD3<Float>] {
        get { detachedPartPositions ?? [:] }
        set { detachedPartPositions = newValue }
    }

    mutating func transition(to step: HeartLessonStep?, asset: HeartAsset) {
        let viewpoint = (yaw, pitch, zoom, dragOrientation)
        restore(asset: asset, step: step)
        (yaw, pitch, zoom, dragOrientation) = viewpoint
    }

    mutating func setSeparation(_ value: Double) {
        isolate = false
        moveParts = false
        partOffsets.removeAll()
        separation = min(1, max(0, value))
    }

    mutating func toggleSeparation() {
        isolate = false
        moveParts = false
        if separation > 0 || !partOffsets.isEmpty { reassemble() }
        else { separation = 1 }
    }

    mutating func reassemble() {
        isolate = false
        moveParts = false
        separation = 0
        partOffsets.removeAll()
    }

    mutating func restore(asset: HeartAsset, step: HeartLessonStep?) {
        let displayPreferences = (transparent, showBackdrop, showLabels, showOrientation)
        self = HeartModelControls()
        (transparent, showBackdrop, showLabels, showOrientation) = displayPreferences
        showContext = asset.category != "reference"
        developmentState = step?.state ?? asset.defaultState
        selectedPart = step?.focus ?? ""
        cutaway = asset.defaultCutaway ?? false
        if selectedPart.hasSuffix("_Anterior") { cutaway = false }
        if selectedPart.hasSuffix("_Posterior") { cutaway = true }
        resetView(asset: asset)
    }

    mutating func perform(_ action: HeartModelAction, asset: HeartAsset, step: HeartLessonStep?) {
        switch action {
        case .focus:
            guard let step, asset.parts.contains(where: { $0.id == step.focus }) else { return }
            restore(asset: asset, step: step)
            isolate = true
        case .layers:
            restore(asset: asset, step: step)
            separation = 1
            if asset.hasCutaway {
                cutaway = true
                if selectedPart.hasSuffix("_Anterior") {
                    let posterior = selectedPart.replacingOccurrences(of: "_Anterior", with: "_Posterior")
                    selectedPart = asset.parts.contains(where: { $0.id == posterior }) ? posterior : ""
                }
            }
        case .compare:
            guard let states = asset.states, states.count > 1 else { return }
            let index = states.firstIndex { $0.id == (developmentState ?? asset.defaultState) } ?? 0
            developmentState = states[(index + 1) % states.count].id
            selectedPart = ""
            isolate = false
            reassemble()
        }
    }

    mutating func resetView(asset: HeartAsset) {
        dragOrientation = nil
        yaw = asset.defaultYaw ?? 0
        pitch = asset.defaultPitch ?? 0
        zoom = 1
    }
}

private struct HeartSeparationRequest: Equatable {
    let target: Double
    let state: String?
    let reduceMotion: Bool
}

/// Anatomy and its controls occupy separate areas of the spatial canvas.
struct HeartModelView: View {
    let asset: HeartAsset
    var lessonStep: HeartLessonStep? = nil
    var detailControlsAtBottom = false
    var obscuredBySheet = false
    var actionRequest: HeartModelActionRequest? = nil
    @PhysicalMetric(from: .meters) private var pointsPerMeter: CGFloat = 1
    @State private var scene = HeartModelScene()
    @State private var controls = HeartModelControls()
    @State private var hasAppliedInitialStep = false
    @State private var showingInfo = false
    @State private var showingLocation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openWindow) private var openWindow
    @State private var openedCloseUpDuringPinch = false
    @State private var separationPresentation = HeartSeparationPresentation()
    @State private var lastSeparationState: String?
    @State private var hasPresentedSeparation = false
    @State private var dragStart: simd_quatf?
    @State private var partDrag: (id: String, start: SIMD3<Float>)?
    @State private var pinchStart: Double?
    @State private var retry = UUID()
    @State private var showingAtlas = false
    @State private var showingParts = false
    @State private var showingAdjustments = false
    @State private var partSearch = ""
    @State private var selectionSuppressedUntil = Date.distantPast

    private var selectedLabel: String? {
        asset.parts.first(where: { $0.id == controls.selectedPart })?.label
    }

    private var separationRequest: HeartSeparationRequest {
        .init(target: controls.separation, state: controls.developmentState, reduceMotion: reduceMotion)
    }

    var body: some View {
        VStack(spacing: 10) {
            if asset.category != "reference", !asset.isAnomaly, !HeartAsset.referenceModels.isEmpty {
                HStack {
                    Text("Regional teaching illustration").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Stage reconstructions", systemImage: "cube.transparent") { showingAtlas = true }
                }
            } else if asset.category == "reference" {
                Text("HDBR Atlas · colour-coded chamber regions and vessel lumens · enlarged")
                    .font(.caption).foregroundStyle(.secondary)
            }
            modelComparison
            HStack(spacing: 16) {
                modelToolbar
                modelCanvas
                if !detailControlsAtBottom {
                    if asset.id == "Heart_10_CirculatoryTransition" {
                        ScrollView {
                            VStack(spacing: 12) {
                                transitionGuide
                                VStack(spacing: 8) { modelDetailsButtons }
                                    .buttonStyle(.bordered).font(.subheadline)
                            }
                        }.frame(width: 280)
                    } else { modelDetailsToolbar }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingAtlas) { HeartReferenceBrowser() }
        .preferredWindowClippingMargins(.front, pointsPerMeter * 0.6)
        .preferredWindowClippingMargins(.back, pointsPerMeter * 0.2)
        .task(id: scene.ready) {
            #if DEBUG
            guard scene.ready, ProcessInfo.processInfo.arguments.contains("--preview-close-up") else { return }
            let args = ProcessInfo.processInfo.arguments
            let index = args.firstIndex(of: "--preview-zoom")
            let zoom = index.flatMap { $0 + 1 < args.count ? Double(args[$0 + 1]) : nil } ?? 1
            openCloseUp(zoom: zoom)
            #endif
        }
        .task(id: separationRequest) {
            let request = separationRequest
            let animate = hasPresentedSeparation && lastSeparationState == request.state
                && scene.ready && !request.reduceMotion
            lastSeparationState = request.state
            hasPresentedSeparation = true
            await separationPresentation.update(to: request.target, animated: animate)
        }
        .onChange(of: lessonStep, initial: true) { _, next in
            if !hasAppliedInitialStep {
                restoreStepOrModel()
                hasAppliedInitialStep = true
            } else { controls.transition(to: next, asset: asset) }
            dragStart = nil; partDrag = nil; pinchStart = nil
        }
        .onChange(of: actionRequest) { _, request in
            guard let request else { return }
            controls.perform(request.action, asset: asset, step: lessonStep)
            dragStart = nil; pinchStart = nil
        }
        .onAppear {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "--preview-zoom"), index + 1 < args.count,
               let zoom = Double(args[index + 1]) { controls.zoom = min(HeartModelZoom.overviewMaximum, HeartModelZoom.clamped(zoom)) }
            if args.contains("--preview-adjustments") { showingAdjustments = true }
            if args.contains("--preview-location") { showingLocation = true }
            if args.contains("--preview-info") { showingInfo = true }
            if args.contains("--preview-move-parts") { controls.moveParts = true }
            if args.contains("--preview-detached"), let part = asset.parts.first(where: { $0.category != "context" && asset.includes($0, state: controls.developmentState) }) {
                controls.moveParts = true
                controls.selectedPart = part.id
                controls.partOffsets[part.id] = [0.045, 0.01, 0.025]
            }
            if args.contains("--preview-separated") { controls.separation = 1 }
            if args.contains("--preview-focus") { controls.isolate = true }
            if args.contains("--preview-layers") { controls.perform(.layers, asset: asset, step: lessonStep) }
            #endif
        }
        .onChange(of: controls.moveParts) { _, moving in
            partDrag = nil; dragStart = nil
            if moving { controls.isolate = false }
        }
        .onChange(of: controls.selectedPart) { _, value in
            guard partDrag == nil else { return }
            if value.isEmpty { controls.isolate = false }
            if value.hasSuffix("_Anterior") { controls.cutaway = false }
            if value.hasSuffix("_Posterior") { controls.cutaway = true }
            if asset.parts.first(where: { $0.id == value })?.category == "context" { controls.showContext = true }
        }
        .onChange(of: controls.cutaway) { _, value in
            if value && controls.selectedPart.hasSuffix("_Anterior") {
                controls.selectedPart = controls.selectedPart.replacingOccurrences(of: "_Anterior", with: "_Posterior")
            }
        }
        .onChange(of: controls.showContext) { _, value in
            if !value && asset.parts.first(where: { $0.id == controls.selectedPart })?.category == "context" {
                controls.selectedPart = ""; controls.isolate = false
            }
        }
    }

    // This key is deliberately limited to the birth-transition illustration.
    private var transitionGuide: some View {
        let fetal = (controls.developmentState ?? asset.defaultState) == "fetal"
        return VStack(alignment: .leading, spacing: 8) {
            Text(fetal ? "Before birth: two connections let blood bypass the lungs"
                       : "After birth: lung flow increases; the two connections begin closing")
                .font(.headline)
            VStack(spacing: 8) {
                transitionKey("1 · Foramen ovale", detail: fetal ? "Right atrium → left atrium" : "Flap presses against the atrial septum",
                              id: fetal ? "ForamenFlap_Fetal" : "ForamenFlap_Transition", color: .yellow)
                transitionKey("2 · Ductus arteriosus", detail: fetal ? "Pulmonary artery → aorta" : "Narrows gradually; still open in this view",
                              id: fetal ? "Ductus_Fetal" : "Ductus_Transition", color: .purple)
                transitionKey("Lungs", detail: "Pale shapes beside the heart", id: "Lung_R", color: .gray)
                transitionKey("Aorta", detail: "Arch carrying blood to the body", id: "Aorta", color: .orange)
            }
            Text("Tap a key to highlight its structure. Pink = heart walls · blue = pulmonary arteries. Colours identify structures, not oxygen levels. Closure is gradual; this is a simplified snapshot.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 18))
    }

    private func transitionKey(_ title: String, detail: String, id: String, color: Color) -> some View {
        Button {
            controls.selectedPart = id
            controls.isolate = false
            controls.showContext = true
            controls.cutaway = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label { Text(title).font(.subheadline.bold()) } icon: {
                    Circle().fill(color).frame(width: 10, height: 10)
                }
                Text(detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(8).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("transition." + id)
    }

    @ViewBuilder
    private var modelComparison: some View {
        if let states = asset.states, !states.isEmpty {
            SpatialChoicePicker(title: "Compare anatomy", selection: Binding(
                get: { controls.developmentState ?? asset.defaultState ?? states[0].id },
                set: { controls.developmentState = $0; controls.selectedPart = ""; controls.isolate = false; controls.reassemble() }
            ), choices: states.map { .init(id: $0.id, title: $0.label) })
            .frame(maxWidth: 480)
            .disabled(!scene.ready)
        }
    }

    private var modelDetailsToolbar: some View {
        Group {
            if detailControlsAtBottom {
                HStack(spacing: 12) { modelDetailsButtons }
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) { modelDetailsButtons }
                    .frame(width: 148)
                    .padding(.top, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .font(.subheadline)
        .buttonStyle(.bordered)
        .controlSize(detailControlsAtBottom ? .regular : .large)
    }

    private var detailPopupEdge: Edge { detailControlsAtBottom ? .top : .leading }

    private var modelDetailsButtons: some View {
        Group {
            Button {
                openCloseUp(zoom: max(1, controls.zoom))
            } label: {
                Label("Close-up", systemImage: "arrow.up.left.and.arrow.down.right").foregroundStyle(.black)
            }
            .accessibilityHint("Open an enlarged model in a separate movable 3D window.")
            .disabled(!scene.ready)
            if let guide = HeartLocationGuide.guide(for: asset) {
                Button {
                    showingInfo = false
                    showingLocation.toggle()
                } label: {
                    Label("Location", systemImage: "map").foregroundStyle(.black)
                }
                .accessibilityHint(guide.title)
                .popover(isPresented: $showingLocation, arrowEdge: detailPopupEdge) {
                    HeartLocationView(asset: asset, guide: guide) { showingLocation = false }
                }
            }
            Button {
                showingLocation = false
                showingInfo.toggle()
            } label: {
                Label("Model info", systemImage: "info.circle").foregroundStyle(.black)
            }
            .popover(isPresented: $showingInfo, arrowEdge: detailPopupEdge) { informationPanel }
        }
    }

    private var modelCanvas: some View {
        VStack(spacing: 12) {
            if controls.showLabels {
                Text(selectedLabel ?? (controls.moveParts ? "Drag a part to move it" : "Tap a part to inspect it"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(height: 36)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
                    .allowsHitTesting(false)
                    .accessibilityLabel(selectedLabel.map { "Selected part: \($0)" } ?? "No part selected")
            }
            if detailControlsAtBottom { modelDetailsToolbar }
            modelViewport
        }
        .padding(20)
        .background {
            if controls.showBackdrop {
                RoundedRectangle(cornerRadius: 28).fill(.black.opacity(0.65))
                    .offset(z: -pointsPerMeter * 0.20)
            }
        }
        .id(retry)
        .overlay {
            if let message = scene.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                    Text(message)
                    Button("Try Again") { scene = HeartModelScene(); retry = UUID() }
                }
                .padding(28).glassBackgroundEffect()
            } else if !scene.ready {
                ProgressView("Loading model").padding(24).glassBackgroundEffect()
            }
        }
    }

    // The label and bottom actions reserve their own layout space, rather than
    // floating over anatomy as the model rotates or the window changes size.
    private var modelViewport: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                do {
                    let model = try await Entity(named: "HeartAssets/\(asset.id)", in: realityKitContentBundle)
                    guard !Task.isCancelled else { return }
                    try await scene.install(model, asset: asset)
                    content.add(scene.holder)
                    scene.holder.isEnabled = !obscuredBySheet && !showingInfo && !showingLocation && !showingAtlas && !showingParts
                    scene.apply(asset: asset, selected: controls.selectedPart, isolate: controls.isolate,
                                cutaway: controls.cutaway, context: controls.showContext,
                                separation: Float(separationPresentation.value), state: controls.developmentState, transparent: controls.transparent, partOffsets: controls.partOffsets)
                    scene.spin.orientation = controls.orientation
                    scene.fit(in: content.convert(geometry.frame(in: .local), from: .local, to: .scene), zoom: Float(controls.zoom), selected: controls.selectedPart,
                          overviewFill: detailControlsAtBottom ? 0.72 : 0.64)
                    scene.ready = true
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--validate-heart-assets") {
                        let host = Entity()
                        host.components.set(OpacityComponent(opacity: 0))
                        content.add(host)
                        Task { @MainActor in
                            await HeartAssetValidation.run(in: host)
                            host.removeFromParent()
                        }
                    }
                    #endif
                } catch {
                    guard !Task.isCancelled else { return }
                    scene.errorMessage = "This model couldn’t be opened."
                    print("Heart asset \(asset.id) failed: \(error)")
                }
            } update: { content in
                // Spatial geometry can project through detail popovers. Suspend its
                // rendering while reading; keep all inspection transforms intact.
                scene.holder.isEnabled = !obscuredBySheet && !showingInfo && !showingLocation && !showingAtlas && !showingParts
                scene.apply(asset: asset, selected: controls.selectedPart, isolate: controls.isolate,
                            cutaway: controls.cutaway, context: controls.showContext, separation: Float(separationPresentation.value), state: controls.developmentState, transparent: controls.transparent, partOffsets: controls.partOffsets)
                scene.spin.orientation = controls.orientation
                scene.fit(in: content.convert(geometry.frame(in: .local), from: .local, to: .scene), zoom: Float(controls.zoom), selected: controls.selectedPart,
                          overviewFill: detailControlsAtBottom ? 0.72 : 0.64)
            }
            .realityViewLayoutBehavior(.flexible)
            // Keep the inspection focus above the lower manipulation area.
            // Move the RealityView itself so its hit targets follow the anatomy.
            .offset(y: -geometry.size.height * 0.18)
            // A drag owns its gesture through completion, so releasing it cannot select a tissue.
            .gesture(DragGesture(minimumDistance: 8).targetedToAnyEntity()
                .exclusively(before: SpatialTapGesture().targetedToAnyEntity())
                .onChanged { value in
                    if case .first(let drag) = value {
                        guard pinchStart == nil else { dragStart = nil; return }
                        if controls.moveParts, lessonStep == nil {
                            if partDrag == nil, let id = scene.partID(for: drag.entity, asset: asset) {
                                partDrag = (id, controls.partOffsets[id] ?? .zero)
                                controls.selectedPart = id
                            }
                            if let partDrag {
                                let delta = drag.convert(drag.translation3D, from: .local, to: scene.movementSpace)
                                controls.partOffsets[partDrag.id] = scene.boundedOffset(partDrag.start + delta)
                            }
                            return
                        }
                        if dragStart == nil { dragStart = controls.orientation }
                        guard let start = dragStart else { return }
                        controls.rotate(from: start, horizontal: Float(drag.translation.width), vertical: Float(drag.translation.height))
                    }
                }
                .onEnded { value in
                    switch value {
                    case .first:
                        dragStart = nil; partDrag = nil
                    case .second(let tap):
                        guard pinchStart == nil, Date() >= selectionSuppressedUntil else { return }
                        controls.selectedPart = scene.partID(for: tap.entity, asset: asset) ?? ""
                    }
                })
            .simultaneousGesture(MagnifyGesture().targetedToAnyEntity()
                .onChanged { value in
                    guard partDrag == nil else { return }
                    selectionSuppressedUntil = Date().addingTimeInterval(0.25)
                    if pinchStart == nil { pinchStart = controls.zoom }
                    let zoom = HeartModelZoom.clamped((pinchStart ?? 1) * value.magnification)
                    controls.zoom = min(HeartModelZoom.overviewMaximum, zoom)
                    if zoom > HeartModelZoom.overviewMaximum, !openedCloseUpDuringPinch {
                        openedCloseUpDuringPinch = true
                        openCloseUp(zoom: zoom)
                    }
                }
                .onEnded { _ in
                    pinchStart = nil
                    openedCloseUpDuringPinch = false
                    selectionSuppressedUntil = Date().addingTimeInterval(0.25)
                })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("\(asset.lesson) three-dimensional model")
    }

    private var modelToolbar: some View {
        VStack(spacing: 8) {
            ScrollView {
                VStack(spacing: 6) {
                    if selectedLabel != nil {
                        HStack(spacing: 4) {
                            Button {
                                controls.moveParts = false
                                controls.isolate = true
                                controls.zoom = 1
                            } label: {
                                Text("Focus").foregroundStyle(.black)
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                            .fixedSize(horizontal: true, vertical: false)
                            .accessibilityHint("Enlarge the selected part and hide other parts. Use Show all to return.")
                            Button { controls.selectedPart = ""; controls.isolate = false } label: {
                                Image(systemName: "xmark").frame(width: 44, height: 44)
                            }.buttonStyle(.plain).accessibilityLabel("Clear selected part")
                        }
                    } else {
                        Image(systemName: "hand.draw")
                        Text(controls.moveParts ? "Drag a part to move it\nTap to inspect" : "Drag to rotate\nPinch to resize\nTap to inspect")
                            .font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    }
                    Divider().padding(.vertical, 4)
                    SpatialToolButton(title: "Parts", symbol: "square.3.layers.3d", selected: showingParts) {
                        showingAdjustments = false
                        showingParts.toggle()
                    }
                    .popover(isPresented: $showingParts, arrowEdge: .trailing) { partsPanel }
                    if lessonStep == nil {
                        SpatialToolButton(title: controls.moveParts ? "Rotate" : "Move parts", symbol: controls.moveParts ? "arrow.triangle.2.circlepath" : "hand.draw", selected: controls.moveParts) {
                            controls.moveParts.toggle()
                            controls.isolate = false
                        }
                        .accessibilityHint("Switch between rotating the whole model and dragging individual parts apart.")
                        if controls.partOffsets[controls.selectedPart] != nil {
                            SpatialToolButton(title: "Return part", symbol: "arrow.uturn.backward") {
                                controls.partOffsets.removeValue(forKey: controls.selectedPart)
                            }
                        }
                    }
                    if asset.hasCutaway {
                        SpatialToolButton(title: "Cutaway", symbol: "circle.lefthalf.filled", selected: controls.cutaway) {
                            controls.cutaway.toggle()
                        }
                    }
                    SpatialToolButton(title: controls.separation > 0 || !controls.partOffsets.isEmpty ? "Reassemble" : "Separate", symbol: "arrow.up.left.and.arrow.down.right", selected: controls.separation > 0 || !controls.partOffsets.isEmpty) {
                        controls.toggleSeparation()
                    }
                    SpatialToolButton(title: controls.isolate ? "Show all" : "Isolate", symbol: "scope", selected: controls.isolate) {
                        controls.moveParts = false
                        controls.isolate.toggle()
                    }.disabled(controls.selectedPart.isEmpty)
                    SpatialToolButton(title: "View", symbol: "slider.horizontal.3", selected: showingAdjustments) {
                        showingParts = false
                        showingAdjustments.toggle()
                    }
                    .popover(isPresented: $showingAdjustments, arrowEdge: .trailing) { adjustmentsPanel }
                    if lessonStep != nil {
                        SpatialToolButton(title: "Restore step", symbol: "arrow.uturn.backward") { restoreStepOrModel() }
                    }
                }
                .frame(maxWidth: .infinity).padding(8)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Keep recovery visible even when a selected tissue or small window
            // makes the remaining tools require scrolling.
            Divider().padding(.horizontal, 12)
            HStack(spacing: 0) {
                SpatialToolButton(title: "Reset view", symbol: "arrow.counterclockwise") { resetView() }
                    .accessibilityHint("Restore the original model size and viewing angle.")
                if controls.showOrientation && asset.category != "reference" {
                    HeartOrientationCue(rotation: controls.orientation, schematic: asset.usesSchematicView)
                        .allowsHitTesting(false)
                }
            }.padding(.bottom, 8)
        }
        .frame(width: 148).frame(maxHeight: .infinity)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        .disabled(!scene.ready)
    }

    private var informationPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("About this model").font(.title2.bold())
                    Spacer()
                    Button("Done") { showingInfo = false }
                }
                Text(asset.lesson).font(.headline)
                if let note = asset.presentationNote { Text(note).font(.body) }
                Text(asset.category == "reference" ? "Enlarged HDBR regional reconstruction. Regions are not complete tissue walls; omitted structures remain omitted. Colours identify regions. Adapted under CC BY-NC-SA 4.0; see References for attribution." : "Enlarged educational illustration. Anatomy is simplified; the model does not simulate blood flow or pressure.")
                    .foregroundStyle(.secondary)
                if let review = asset.anatomyReview {
                    Divider()
                    Text(review.scope).font(.headline)
                    Text(review.supports)
                    Text("What this model leaves out").font(.subheadline.bold())
                    Text(review.limitations).foregroundStyle(.secondary)
                }
                Divider()
                Label("Drag the model to rotate", systemImage: "hand.draw")
                Label("Use two hands to resize, or use View → Model size", systemImage: "arrow.up.left.and.arrow.down.right")
                Label("Tap a part, or choose it in Parts", systemImage: "square.3.layers.3d")
                Label("Focus enlarges one part; Show all restores its surroundings", systemImage: "scope")
                Text(asset.category == "reference" ? "Source coordinate frame retained. Anatomical direction labels are withheld until the specimen axes are verified." : asset.usesSchematicView
                     ? "The orientation cue shows cranial (Cr) and the schematic viewing side (V)."
                     : "The rotating orientation cue shows anatomical left (L), cranial (Cr), and anterior (A).")
                    .font(.subheadline).foregroundStyle(.secondary)
            }.padding(24)
        }
        .frame(width: 400, height: 520)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var partsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Anatomy").font(.title2.bold())
                Spacer()
                Button("Done") { showingParts = false }
            }
            TextField("Find a tissue or region", text: $partSearch)
                .textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVStack(spacing: 4) {
                    partRow("", label: "Whole model")
                    ForEach(asset.parts.filter { asset.includes($0, state: controls.developmentState) && (partSearch.isEmpty || $0.label.localizedCaseInsensitiveContains(partSearch)) }) { part in
                        partRow(part.id, label: part.label)
                    }
                    if !partSearch.isEmpty, !asset.parts.contains(where: {
                        asset.includes($0, state: controls.developmentState) && $0.label.localizedCaseInsensitiveContains(partSearch)
                    }) {
                        Text("No parts match “\(partSearch)”.").font(.subheadline).foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                        Button("Clear search") { partSearch = "" }
                    }
                }
            }.frame(maxHeight: 340)
        }.padding(24).frame(width: 360)
    }

    private func partRow(_ id: String, label: String) -> some View {
        Button {
            controls.selectedPart = id
            if id.isEmpty { controls.isolate = false }
            showingParts = false
        } label: {
            HStack(spacing: 12) {
                Text(label).font(.subheadline).multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if controls.selectedPart == id { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
            }
            .padding(12).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(controls.selectedPart == id ? Color.accentColor.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityIdentifier("part." + (id.isEmpty ? "whole" : id))
    }

    private var adjustmentsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("View controls").font(.title2.bold())
                    Spacer()
                    Button("Done") { showingAdjustments = false }
                }
                Toggle("Part label", isOn: $controls.showLabels)
                if asset.category != "reference" { Toggle("Orientation cue", isOn: $controls.showOrientation) }
                Toggle("Model backdrop", isOn: $controls.showBackdrop)
                Toggle("Transparent surroundings", isOn: $controls.transparent)
                if asset.hasContext { Toggle("Surrounding tissue", isOn: $controls.showContext) }
                HStack {
                    Button(asset.category == "reference" ? "Source view" : (asset.usesSchematicView ? "View side" : "Anterior")) { setView(yaw: 0, pitch: 0) }
                    Button(asset.category == "reference" ? "Opposite" : (asset.usesSchematicView ? "Opposite" : "Posterior")) { setView(yaw: .pi, pitch: 0) }
                    Button(asset.category == "reference" ? "Top view" : "Cranial") { setView(yaw: 0, pitch: .pi / 2) }
                }.buttonStyle(.bordered)
                VStack(alignment: .leading) {
                    Text("Separation").font(.headline)
                    Slider(value: Binding(get: { controls.separation }, set: { controls.setSeparation($0) }), in: 0...1).accessibilityLabel("Part separation")
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("Model size").font(.headline)
                        Spacer()
                        Text("\(controls.zoom, format: .number.precision(.fractionLength(1)))×")
                    }
                    Slider(value: $controls.zoom, in: HeartModelZoom.range.lowerBound...HeartModelZoom.overviewMaximum)
                        .accessibilityLabel("Model size")
                        .accessibilityValue("\(Int((controls.zoom * 100).rounded())) percent")
                    Button("Open close-up · up to 4×", systemImage: "arrow.up.left.and.arrow.down.right") {
                        showingAdjustments = false
                        openCloseUp(zoom: max(1, controls.zoom))
                    }
                }
                Button("Reset view", systemImage: "arrow.counterclockwise") {
                    resetView()
                }
                if lessonStep != nil {
                    Button("Restore step view", systemImage: "arrow.uturn.backward") {
                        restoreStepOrModel(); showingAdjustments = false
                    }
                }
            }.padding(24)
        }.frame(width: 380, height: 560)
            .scrollBounceBehavior(.basedOnSize)
    }


    private func openCloseUp(zoom: Double) {
        var snapshot = controls
        snapshot.zoom = HeartModelZoom.clamped(zoom)
        openWindow(id: "heart-close-up", value: HeartCloseUpRequest(assetID: asset.id, controls: snapshot))
    }

    private func resetView() {
        controls.resetView(asset: asset)
        dragStart = nil; pinchStart = nil
        selectionSuppressedUntil = Date().addingTimeInterval(0.25)
    }

    private func setView(yaw: Float, pitch: Float) {
        controls.setOrientation(yaw: yaw, pitch: pitch)
        dragStart = nil; pinchStart = nil
    }

    private func restoreStepOrModel() {
        controls.restore(asset: asset, step: lessonStep)
        dragStart = nil; pinchStart = nil
    }
}

@MainActor @Observable
final class HeartModelScene {
    // Only readiness and errors drive SwiftUI. The mutable renderer caches are
    // read and written inside RealityView.update; observing them feeds the
    // update back into itself, especially when switching isolation pivots.
    let holder = Entity()
    let spin = Entity()
    let annotations = Entity()
    @ObservationIgnored private var currentLabel: Entity?
    private let annotationDot = ModelEntity(mesh: .generateSphere(radius: 0.0025),
                                           materials: [UnlitMaterial(color: .systemYellow)])
    private let annotationLine = ModelEntity(mesh: .generateCylinder(height: 1, radius: 0.0006),
                                            materials: [UnlitMaterial(color: .systemYellow)])
    @ObservationIgnored private var model: Entity?
    @ObservationIgnored private var assembledModelPosition = SIMD3<Float>.zero
    @ObservationIgnored private var isolatedPartID: String?
    @ObservationIgnored private var manualOffsets: [String: SIMD3<Float>] = [:]
    var movementSpace: Entity { model ?? spin }

    func boundedOffset(_ value: SIMD3<Float>) -> SIMD3<Float> {
        guard value.x.isFinite, value.y.isFinite, value.z.isFinite else { return .zero }
        let length = simd_length(value)
        return length > 0.18 ? value * (0.18 / length) : value
    }

    @ObservationIgnored private var nodes: [String: Entity] = [:]
    @ObservationIgnored private var rest: [String: SIMD3<Float>] = [:]
    private struct TissueAppearance {
        let entity: Entity
        let partID: String
        let opaque: [any RealityKit.Material]
        let selected: [any RealityKit.Material]
    }
    @ObservationIgnored private var appearances: [TissueAppearance] = []
    @ObservationIgnored private var lastAppearance: String?
    var ready = false
    var errorMessage: String?

    private static let tissueEnvironment = Task {
        try await EnvironmentResource(named: "HeartTissueStudio", in: .main)
    }

    func install(_ model: Entity, asset: HeartAsset) async throws {
        let environment = try await Self.tissueEnvironment.value
        var lighting = ImageBasedLightComponent(source: .single(environment), intensityExponent: 0)
        lighting.inheritsRotation = true
        holder.components.set(lighting)
        model.components.set(ImageBasedLightReceiverComponent(imageBasedLight: holder))
        // A real key light lets neighbouring tissues cast shadows on one another;
        // environment reflections alone leave stacked anatomy looking painted flat.
        let keyLight = DirectionalLight()
        keyLight.name = "TissueKeyLight"
        keyLight.light.intensity = 1100
        keyLight.shadow = .init(shadowProjection: .automatic(maximumDistance: 3), depthBias: 1)
        holder.addChild(keyLight)
        keyLight.look(at: .zero, from: [-0.4, 0.6, 0.8], relativeTo: holder)
        // Directional lights need orientation only. An offset light must not
        // expand SwiftUI's scene layout bounds away from the anatomy.
        keyLight.position = .zero
        self.model = model
        holder.addChild(spin)
        spin.addChild(model)
        let bounds = model.visualBounds(relativeTo: spin)
        model.position -= bounds.center
        assembledModelPosition = model.position
        for part in asset.parts {
            guard let node = model.findEntity(named: part.id) else {
                throw NSError(domain: "HeartModel", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Missing tissue: \(part.id)"])
            }
            nodes[part.id] = node
            rest[part.id] = node.position(relativeTo: model)
            // Colliders are per tissue, never on the entire model's bounding box.
            node.generateCollisionShapes(recursive: true)
            node.components.set(InputTargetComponent())
            node.components.set(HoverEffectComponent())
            cacheAppearance(of: node, partID: part.id, tint: asset.id == "Heart_10_CirculatoryTransition" ? transitionTint(part.id) : nil)
        }
    }

    func fit(in available: BoundingBox, zoom: Float, selected: String = "", volumetric: Bool = false, overviewFill: Float = 0.60) {
        guard let model else { return }
        // Measure enabled anatomy after rotation and separation, rather than the original asset.
        spin.position = .zero
        holder.scale = .one
        // Frame the assembled anatomy, so moving one tissue never shrinks or recentres the whole model.
        var movedPositions: [String: SIMD3<Float>] = [:]
        for (id, offset) in manualOffsets where isolatedPartID == nil {
            guard let node = nodes[id] else { continue }
            movedPositions[id] = node.position(relativeTo: model)
            node.setPosition(node.position(relativeTo: model) - offset, relativeTo: model)
        }
        var bounds = model.visualBounds(relativeTo: holder, excludeInactive: true)
        if let id = isolatedPartID, let node = nodes[id] {
            // A rotation-invariant envelope keeps an asymmetric isolated tissue
            // from drifting or changing size as its camera-facing bounds change.
            let localBounds = node.visualBounds(relativeTo: spin, excludeInactive: true)
            let radius = max(0.0005, simd_length(localBounds.extents) / 2)
            bounds = BoundingBox(min: .init(repeating: -radius), max: .init(repeating: radius))
        }
        for (id, position) in movedPositions { nodes[id]?.setPosition(position, relativeTo: model) }
        guard bounds.extents.x > 0, bounds.extents.y > 0,
              bounds.center.x.isFinite, bounds.center.y.isFinite, bounds.center.z.isFinite else { return }
        let width = max(0.001, bounds.extents.x)
        let height = max(0.001, bounds.extents.y)
        let depth = max(0.001, bounds.extents.z)
        let fitScale = min(available.extents.x / width, available.extents.y / height,
                           min(available.extents.x, available.extents.y) / depth)
        // The default view fits the anatomy. Close-up zoom deliberately permits
        // larger geometry rather than silently restoring the old fit-to-window cap.
        // The viewer requests an expanded front clipping margin. Allow readable
        // depth here rather than shrinking the entire organ into a six-centimetre slab.
        let overviewScale = volumetric ? fitScale * 0.60
            : min(fitScale * overviewFill, 0.30 / (depth * Float(HeartModelZoom.overviewMaximum)))
        holder.scale = .init(repeating: max(0.001, overviewScale * Float(HeartModelZoom.clamped(Double(zoom)))))
        var center = bounds.center
        let closeUp = Float(HeartModelZoom.clamped(Double(zoom)))
        if isolatedPartID == nil, manualOffsets.isEmpty, closeUp > 1.25, let node = nodes[selected], node.isEnabled {
            let focus = node.visualBounds(relativeTo: holder, excludeInactive: true)
            if focus.extents.x > 0, focus.extents.y > 0, focus.center.x.isFinite, focus.center.y.isFinite {
                let weight = min(1, (closeUp - 1.25) / (Float(HeartModelZoom.range.upperBound) - 1.25))
                center.x += (focus.center.x - center.x) * weight
                center.y += (focus.center.y - center.y) * weight
                if volumetric { center.z += (focus.center.z - center.z) * weight }
            }
        }
        spin.position = -center
        // Keep overview anatomy on the window plane to avoid perspective drift over
        // adjacent controls. Its backdrop is 20 cm behind this plane.
        // A flexible RealityView keeps a stable origin at the view centre.
        // fit() centres the visible anatomy itself; automatic content centering
        // would add a second offset based on the initial lesson state.
        holder.position = volumetric ? [0, 0, available.center.z] : .zero
    }

    func selectedAnchor(for selected: String) -> SIMD3<Float>? {
        guard let node = nodes[selected], node.isEnabled else { return nil }
        let bounds = node.visualBounds(relativeTo: holder, excludeInactive: true)
        guard bounds.extents.x > 0, bounds.extents.y > 0,
              bounds.center.x.isFinite, bounds.center.y.isFinite, bounds.max.z.isFinite else { return nil }
        // The front of this tissue's bounds locates its label without moving with other tissues.
        let surface = SIMD3<Float>(bounds.center.x, bounds.center.y, bounds.max.z)
        return surface * holder.scale + holder.position
    }

    func updateAnnotation(label: Entity?, selected: String, visible: Bool, available: BoundingBox) {
        guard let label, visible, let anchor = selectedAnchor(for: selected) else {
            for child in annotations.children { child.isEnabled = false }
            return
        }
        if currentLabel !== label {
            currentLabel?.removeFromParent()
            currentLabel = label
        }
        if label.parent !== annotations { annotations.addChild(label) }
        if annotationDot.parent == nil { annotations.addChild(annotationDot); annotations.addChild(annotationLine) }
        for child in annotations.children { child.isEnabled = true }
        let extent = label.visualBounds(relativeTo: label).extents
        let limitX = max(0, available.extents.x / 2 - extent.x / 2 - 0.01)
        let limitY = max(0, available.extents.y / 2 - extent.y / 2 - 0.01)
        let position = SIMD3<Float>(min(limitX, max(-limitX, anchor.x + 0.05)),
                                    min(limitY, max(-limitY, anchor.y + 0.055)), anchor.z + 0.018)
        label.position = position
        annotationDot.position = anchor + [0, 0, 0.003]
        let end = position - [0, extent.y / 2, 0]
        let direction = end - annotationDot.position
        let length = simd_length(direction)
        annotationLine.position = (end + annotationDot.position) / 2
        annotationLine.scale = [1, max(0.0001, length), 1]
        if length > 0.0001 {
            annotationLine.orientation = simd_quatf(from: [0, 1, 0], to: direction / length)
        }
    }

    private func transitionTint(_ id: String) -> UIColor? {
        if id.hasPrefix("ForamenFlap") { return UIColor(red: 1, green: 0.83, blue: 0.24, alpha: 1) }
        if id.hasPrefix("Ductus_") { return UIColor(red: 0.72, green: 0.40, blue: 0.95, alpha: 1) }
        if id.hasPrefix("Lung_") { return UIColor(red: 0.80, green: 0.81, blue: 0.84, alpha: 1) }
        if id == "Aorta" { return UIColor(red: 1, green: 0.57, blue: 0.26, alpha: 1) }
        if id.contains("PulmonaryArtery") { return UIColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 1) }
        return nil
    }

    private func cacheAppearance(of entity: Entity, partID: String, tint: UIColor? = nil) {
        if let component = entity.components[ModelComponent.self] {
            let opaque: [any RealityKit.Material] = component.materials.map { material in
                if var tissue = material as? PhysicallyBasedMaterial {
                    tissue.blending = .opaque
                    if let tint { tissue.baseColor = .init(tint: tint) }
                    return tissue
                }
                if let tint {
                    var tissue = PhysicallyBasedMaterial()
                    tissue.baseColor = .init(tint: tint)
                    tissue.roughness = .init(floatLiteral: 0.65)
                    return tissue
                }
                return material
            }
            let selected: [any RealityKit.Material] = opaque.map { material in
                if var tissue = material as? PhysicallyBasedMaterial {
                    tissue.emissiveColor = .init(color: UIColor(red: 1, green: 0.28, blue: 0.42, alpha: 1))
                    tissue.emissiveIntensity = 0.06
                    return tissue
                }
                return material
            }
            appearances.append(TissueAppearance(entity: entity, partID: partID, opaque: opaque, selected: selected))
        }
        for child in entity.children { cacheAppearance(of: child, partID: partID, tint: tint) }
    }

    func partID(for entity: Entity, asset: HeartAsset) -> String? {
        var candidate: Entity? = entity
        while let node = candidate {
            if nodes[node.name] != nil { return node.name }
            candidate = node.parent
        }
        return nil
    }

    func apply(asset: HeartAsset, selected: String, isolate: Bool, cutaway: Bool,
               context: Bool, separation: Float, state: String? = nil, transparent: Bool = false, partOffsets: [String: SIMD3<Float>] = [:]) {
        guard let model else { return }
        // Restore before measuring a new pivot; never accumulate recentering.
        model.position = assembledModelPosition
        isolatedPartID = nil
        manualOffsets = partOffsets.mapValues(boundedOffset)
        for part in asset.parts {
            guard let node = nodes[part.id], let original = rest[part.id] else { continue }
            node.isEnabled = asset.includes(part, state: state) && (!isolate || selected.isEmpty || part.id == selected)
                && (isolate && part.id == selected || context || part.category != "context")
                && (isolate && part.id == selected || !cutaway || !part.id.hasSuffix("_Anterior"))
            let dimSurroundings = transparent || (asset.id == "Heart_10_CirculatoryTransition" && !selected.isEmpty)
            node.components.set(OpacityComponent(opacity: dimSurroundings && selected != part.id && !isolate ? (transparent ? 0.35 : 0.6) : 1))
            node.setPosition(original + offset(for: part) * separation + (manualOffsets[part.id] ?? .zero), relativeTo: model)
        }
        if isolate, !selected.isEmpty, let node = nodes[selected], node.isEnabled {
            let bounds = node.visualBounds(relativeTo: spin, excludeInactive: true)
            let center = bounds.center
            if center.x.isFinite, center.y.isFinite, center.z.isFinite,
               simd_length(bounds.extents) > 0 {
                // Move the selected tissue's own center to the spin origin.
                // Its authored mesh origin may still be the whole heart's origin.
                model.position -= center
                isolatedPartID = selected
            }
        }
        if lastAppearance != selected {
            for appearance in appearances {
                guard var component = appearance.entity.components[ModelComponent.self] else { continue }
                component.materials = appearance.partID == selected ? appearance.selected : appearance.opaque
                appearance.entity.components.set(component)
            }
            lastAppearance = selected
        }
    }

    private func offset(for part: HeartAsset.Part) -> SIMD3<Float> {
        if let offset = part.separationOffset, offset.count == 3 {
            return [offset[0], offset[1], offset[2]]
        }
        if part.category == "context" { return [0, 0, part.id.hasPrefix("Neural") ? -0.025 : -0.05] }
        let side: Float = part.id.contains("_L") ? -1 : (part.id.contains("_R") ? 1 : 0)
        let depth: Float = part.id.hasPrefix("Myocardium") ? 0.05 : (part.id.hasPrefix("CardiacJelly") ? 0.025 : 0)
        let panel: Float = part.id.hasSuffix("_Anterior") ? 1 : -1
        if part.id.hasPrefix("Angioblastic") { return [side * 0.03, 0, 0.04] }
        return [side * 0.035, 0, depth * panel]
    }
}

struct HeartModelUnavailableView: View {
    let title: String
    var body: some View {
        VStack(spacing: 16) {
            Image("GuidedHeart").resizable().scaledToFit().frame(width: 150, height: 150)
                .accessibilityHidden(true)
            Text("Model coming soon").font(.title2.bold())
            Text("The 3D model for \(title) is being prepared.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 260)
    }
}

/// Stage-specific source reconstructions remain distinct from tissue-layer illustrations.
struct HeartReferenceBrowser: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = HeartAsset.referenceModels.first?.id ?? ""
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Human embryonic heart atlas").font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            Picker("Carnegie stage", selection: $selectedID) {
                ForEach(HeartAsset.referenceModels) { asset in
                    Text(asset.lesson).tag(asset.id)
                }
            }.pickerStyle(.menu)
                .accessibilityIdentifier("atlas.stage")
            if let asset = HeartAsset.referenceModels.first(where: { $0.id == selectedID }) {
                HeartModelView(asset: asset).id(asset.id)
            }
            Text("These are reconstructed anatomical regions, not complete tissue layers. Source surface detail and omitted structures are retained; colours identify regions.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Link("HDBR Atlas", destination: URL(string: "https://hdbratlas.org/interactive/heart.html")!)
                Text("· adapted for enlarged, separable display ·")
                Link("CC BY-NC-SA 4.0", destination: URL(string: "https://creativecommons.org/licenses/by-nc-sa/4.0/")!)
            }.font(.caption)
        }.padding(24).frame(width: 1080, height: 800)
    }
}
