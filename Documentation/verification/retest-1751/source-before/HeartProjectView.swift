import SwiftUI
import RealityKit
import simd

struct HeartProjectModel: Identifiable {
    let id: String
    let title: String
    let note: String
    let url: String
    let license: String
    var creator: String { if id.hasPrefix("PDA_") { return "HeartV0 · authored teaching model" }; return id == "Normal_Neonatal_Heart" || id == "Atrial_Septal_Defect_ASD" || id == "Ventricular_Septal_Defect" || id == "Transposition_of_the_great_arteries" || id == "Atrioventricular_septal_defect_4_chamber_view" ? "E-learning UMCG" : "3D Heart Project" }
    // These inspected sources have no colour textures or reliable regional
    // assignments. Use tissue colour without inventing anatomical segmentation.
    var usesUniformTissueColor: Bool { ["Normal_Neonatal_Heart", "Atrial_Septal_Defect_ASD", "Ventricular_Septal_Defect", "Atrioventricular_septal_defect_4_chamber_view", "Transposition_of_the_great_arteries"].contains(id) }
    static func modelID(for lesson: String) -> String? {
        switch lesson {
        case "Atrial Septal Defect (ASD)": "Atrial_Septal_Defect_ASD"
        case "Ventricular Septal Defect (VSD)": "Ventricular_Septal_Defect"
        case "Tetralogy of Fallot": "Tetralogy_of_Fallot"
        case "Transposition of the Great Arteries (TGA)": "Transposition_of_the_great_arteries"
        case "Coarctation of the Aorta": "Coarctation"
        case "Patent Ductus Arteriosus (PDA)": "PDA_Patent"
        default: nil
        }
    }
    static let all: [Self] = [
        .init(id: "PDA_Patent", title: "Patent ductus", note: "Authored regional reconstruction of a persistent ductal connection. The hollow duct joins the left pulmonary arterial region to the descending aorta beyond the arch branches. Compare with the matched closed-remnant model.", url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/patent-ductus-arteriosus-pda", license: "Original HeartV0 teaching geometry"),
        .init(id: "PDA_Closed", title: "Closed remnant", note: "Matched authored regional reconstruction with a solid ligamentum arteriosum and closed parent-vessel walls. This is an anatomical endpoint, not instant closure at birth or a treatment simulation.", url: "https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/patent-ductus-arteriosus-pda", license: "Original HeartV0 teaching geometry"),
        .init(id: "Atrioventricular_septal_defect_4_chamber_view", title: "AVSD", note: "UMCG’s four-chamber educational view of an atrioventricular septal defect. Compare the central junction with the cushion lesson; this is a different representation, not a simulated developmental outcome.", url: "https://sketchfab.com/3d-models/atrioventricular-septal-defect-4-chamber-view-d899d6e674054c3bb265f9cd687fd967", license: "CC BY-NC-SA 4.0"),
        .init(id: "Transposition_of_the_great_arteries", title: "TGA", note: "UMCG’s educational model of transposition of the great arteries. Trace each outlet back to its ventricle and compare with the normal-heart reference.", url: "https://sketchfab.com/3d-models/transposition-of-the-great-arteries-ee41d9d7c8854a98aa67feeeaf430584", license: "CC BY-NC-SA 4.0"),
        .init(id: "Normal_Neonatal_Heart", title: "Neonatal heart", note: "UMCG’s external view of a neonatal heart. Compare the external form with the developmental illustrations.", url: "https://sketchfab.com/3d-models/normal-neonatal-heart-9c0dcc64acd74f0aaa9847736a9a87af", license: "CC BY-NC-SA 4.0"),
        .init(id: "Atrial_Septal_Defect_ASD", title: "ASD", note: "UMCG’s educational model of an opening in the partition between the atria. Rotate it to relate the opening to the surrounding chambers.", url: "https://sketchfab.com/3d-models/atrial-septal-defect-asd-3398e00958054779a07554eaffc8b329", license: "CC BY-NC-SA 4.0"),
        .init(id: "Ventricular_Septal_Defect", title: "VSD", note: "UMCG’s educational model of a ventricular septal defect. Compare this representation with the simplified ventricular septation lesson.", url: "https://sketchfab.com/3d-models/ventricular-septal-defect-e4e0143741f64025af101658210c8c5d", license: "CC BY-NC-SA 4.0"),
        .init(id: "Normal_Teenage_Heart", title: "Typical heart", note: "A teenage heart with no defects. The translucent outer muscle surrounds the coloured chambers and vessels.", url: "https://sketchfab.com/3d-models/normal-teenage-heart-fc6eda3c7c994a31a6e30c9e117353f4", license: "CC BY-NC 4.0"),
        .init(id: "Coarctation", title: "Coarctation", note: "A patient-derived example of a narrowed aortic arch. Compare the vessel’s width along its course.", url: "https://sketchfab.com/3d-models/coarctation-0c71994adc644ed8bd4ff5544d92f26b", license: "CC BY 4.0"),
        .init(id: "Tetralogy_of_Fallot", title: "Tetralogy of Fallot", note: "A patient-derived example of altered ventricular and outlet anatomy. Use the developmental lesson to connect these findings to outlet alignment.", url: "https://sketchfab.com/3d-models/tetralogy-of-fallot-9a2cb93e8e754cd6b3329613d9e40944", license: "CC BY 4.0")
    ]
}

/// Applies the shared finish while preserving source textures and transparent myocardium.
@MainActor @Observable final class HeartProjectScene {
    @ObservationIgnored let root = Entity()
    @ObservationIgnored let spin = Entity()
    @ObservationIgnored var diameter: Float = 1
    var ready = false
    var failed = false
    var parts: [HeartSpecimenPart] = []
    var selectedPart = ""
    var separated = false
    var sectionAxis = -1
    var sectionError: String?
    var moved = false
    private var layoutRevision = 0
    @ObservationIgnored let sections = HeartSectionCache()
    @ObservationIgnored private var specimen: Entity?
    @ObservationIgnored private var nodes: [String: Entity] = [:]
    @ObservationIgnored private var rest: [String: SIMD3<Float>] = [:]
    @ObservationIgnored private var offsets: [String: SIMD3<Float>] = [:]
    @ObservationIgnored private var returnedParts: Set<String> = []
    @ObservationIgnored private var directions: [String: SIMD3<Float>] = [:]
    @ObservationIgnored private var motion: Task<Void, Never>?
    @ObservationIgnored private var entrance: Task<Void, Never>?
    @ObservationIgnored private let origin = ModelEntity(mesh: .generateSphere(radius: 1), materials: [UnlitMaterial(color: .darkGray)])
    @ObservationIgnored private let tether = ModelEntity(mesh: .generateCylinder(height: 1, radius: 1), materials: [UnlitMaterial(color: .darkGray)])

    var preparingSection = false
    @ObservationIgnored private var sectionTask: Task<Void, Never>?
    func setSection(_ axis: Int) {
        sectionTask?.cancel()
        if axis < 0 {
            try? sections.apply(axis: -1); sectionAxis = -1; preparingSection = false; sectionError = nil
            return
        }
        preparingSection = true
        sectionTask = Task { @MainActor in
            do {
                try await prepareSection(axis)
                preparingSection = false
            } catch {
                guard !Task.isCancelled else { return }
                preparingSection = false
                sectionError = "This section could not be prepared. The previous view is retained."
            }
        }
    }
    func prepareSection(_ axis: Int) async throws {
        try await sections.prepare(axis: axis)
        try Task.checkCancellation()
        try sections.apply(axis: axis); sectionAxis = axis; sectionError = nil
    }
    func separate(reduceMotion: Bool) {
        returnedParts = []
        if separated || moved { separated = false; offsets = [:]; moved = false }
        else { separated = true }
        layout(animated: !reduceMotion)
    }
    func returnPart(reduceMotion: Bool) {
        guard nodes[selectedPart] != nil else { return }
        offsets.removeValue(forKey: selectedPart); moved = !offsets.isEmpty
        if separated {
            returnedParts.insert(selectedPart)
            if returnedParts.count == nodes.count { separated = false; returnedParts = [] }
        }
        layout(animated: !reduceMotion)
    }
    func movePart(_ delta: SIMD3<Float>, reduceMotion: Bool) {
        guard nodes[selectedPart] != nil else { return }
        offsets[selectedPart] = HeartSpecimenPart.boundedOffset((offsets[selectedPart] ?? .zero) + spin.orientation.inverse.act(delta * diameter), diameter: diameter)
        moved = !offsets.isEmpty
        layout(animated: !reduceMotion)
    }
    func restore(reduceMotion: Bool) {
        separated = false; offsets = [:]; returnedParts = []; moved = false
        setSection(-1); layout(animated: !reduceMotion)
    }
    func stop() {
        motion?.cancel(); entrance?.cancel(); sectionTask?.cancel()
        sectionTask = nil; preparingSection = false
    }
    func reveal(reduceMotion: Bool) {
        entrance?.cancel()
        if reduceMotion { spin.components.set(OpacityComponent(opacity: 1)); return }
        let start = spin.components[OpacityComponent.self]?.opacity ?? 0
        entrance = Task { @MainActor in
            await HeartMorphTiming.animate(duration: 0.24) { progress in
                spin.components.set(OpacityComponent(opacity: start + (1 - start) * Float(progress)))
            }
        }
    }
    private func layout(animated: Bool) {
        guard specimen != nil else { return }
        motion?.cancel()
        let starts = nodes.mapValues { $0.position(relativeTo: spin) }
        let targets = rest.mapValues { $0 }
        var ends: [String: SIMD3<Float>] = [:]
        for (id, position) in targets {
            let spread = separated && !returnedParts.contains(id) ? (directions[id] ?? .zero) * diameter * 0.15 : .zero
            ends[id] = position + spread + (offsets[id] ?? .zero)
        }
        func apply(_ t: Float) {
            for (id, end) in ends { if let start = starts[id] { nodes[id]?.setPosition(start + (end - start) * t, relativeTo: spin) } }
            updateTether()
            layoutRevision += 1
        }
        guard animated else { apply(1); return }
        motion = Task { @MainActor in
            await HeartMorphTiming.animate(duration: 0.24) { apply(Float($0)) }
        }
    }
    func updateTether() {
        origin.isEnabled = false; tether.isEnabled = false
        guard specimen != nil, let node = nodes[selectedPart], let original = rest[selectedPart] else { return }
        let displacement = node.position(relativeTo: spin) - original
        let end = node.visualBounds(relativeTo: spin).center
        let start = end - displacement, length = simd_length(displacement)
        guard length > diameter * 0.0001 else { return }
        origin.isEnabled = true; tether.isEnabled = true
        origin.position = start; origin.scale = .init(repeating: diameter * 0.008)
        tether.position = (start + end) / 2
        tether.scale = [diameter * 0.002, length, diameter * 0.002]
        tether.orientation = simd_quatf(from: [0, 1, 0], to: displacement / length)
    }

    func load(_ name: String, uniformTissue: Bool) async {
        do {
            guard let url = Bundle.main.url(forResource: name, withExtension: "usdz")
                ?? Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "HeartProject") else {
                throw CocoaError(.fileNoSuchFile)
            }
            let entity = try await Entity(contentsOf: url)
            guard !Task.isCancelled else { return }
            func style(_ node: Entity) {
                if var component = node.components[ModelComponent.self] {
                    component.materials = component.materials.map { HeartModelStyle.harmonized($0, uniformTissue: uniformTissue, toneRegions: true, toneTextures: true) }
                    node.components.set(component)
                }
                for child in node.children { style(child) }
            }
            style(entity)
            specimen = entity
            spin.components.set(OpacityComponent(opacity: 0))
            spin.addChild(entity)
            root.addChild(spin)
            let bounds = entity.visualBounds(relativeTo: spin)
            diameter = max(0.001, simd_length(bounds.extents))
            entity.position -= bounds.center
            sections.capture(entity)
            parts = HeartSpecimenPart.parts(for: name)
            for (index, part) in parts.enumerated() {
                guard let node = entity.findEntity(named: part.id) else { throw CocoaError(.coderReadCorrupt) }
                nodes[part.id] = node; rest[part.id] = node.position(relativeTo: spin)
                // Nested shell/blood-pool centres can point in the same radial
                // direction. Use a distinct inspection slot for every source
                // group so Separate cannot merely translate the whole heart.
                directions[part.id] = HeartSpecimenPart.separationDirection(model: name, part: part.id, index: index, count: parts.count)
            }
            selectedPart = parts.first?.id ?? ""
            spin.addChild(origin); spin.addChild(tether)
            origin.isEnabled = false; tether.isEnabled = false
            try await HeartModelLighting.install(on: root, receiving: entity)
            ready = true
        } catch { failed = true }
    }

    func fit(_ bounds: BoundingBox, zoom: Double, yaw: Double, pitch: Double) {
        let extent = min(bounds.extents.x, bounds.extents.y) * 0.92
        root.scale = SIMD3(repeating: max(0.001, extent / diameter) * Float(HeartModelZoom.clamped(zoom)))
        // Preserve the rotation-invariant x/y envelope. Measure source surfaces
        // at their current part transforms to keep them in front of the backing.
        spin.orientation = simd_quatf(angle: Float(yaw), axis: [0, 1, 0]) * simd_quatf(angle: Float(pitch), axis: [1, 0, 0])
        _ = layoutRevision
        // Sectioning must not change depth or comparison alignment.
        var farthest = Float.infinity
        var nearest = -Float.infinity
        for entry in sections.entries {
            let box = entry.original.mesh.bounds
            for x in [box.min.x, box.max.x] {
                for y in [box.min.y, box.max.y] {
                    for z in [box.min.z, box.max.z] {
                        let z = entry.entity.convert(position: [x, y, z], to: root).z
                        farthest = min(farthest, z); nearest = max(nearest, z)
                    }
                }
            }
        }
        guard farthest.isFinite, nearest.isFinite else { return }
        root.scale = SIMD3(repeating: HeartViewportDepth.scale(root.scale.x, depth: nearest - farthest))
        root.position = [0, 0, HeartViewportDepth.offset(minimumZ: farthest, scale: root.scale.x)]
    }
}

private struct HeartProjectViewport: View {
    let model: HeartProjectModel
    var obscured = false
    let zoom: Double
    let yaw: Double
    let pitch: Double
    let rotating: Bool
    let resetRevision: Int
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotationOffset = 0.0
    @State private var presentation = HeartSpecimenPresentation()
    private var scene: HeartProjectScene { presentation.scene }
    @State private var retry = 0
    @State private var showingParts = false
    var body: some View {
        VStack(spacing: 8) {
        GeometryReader3D { geometry in
            RealityView { content in
                presentation.root.isEnabled = !obscured
                content.add(presentation.root)
                presentation.fit(content.convert(geometry.frame(in: .local), from: .local, to: .scene), zoom: zoom, yaw: yaw + rotationOffset, pitch: pitch)
            } update: { content in
                presentation.root.isEnabled = !obscured
                presentation.fit(content.convert(geometry.frame(in: .local), from: .local, to: .scene), zoom: zoom, yaw: yaw + rotationOffset, pitch: pitch)
            }.realityViewLayoutBehavior(.flexible).clipped()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(presentation.failed ? "Heart model unavailable" : !presentation.loading && presentation.displayedID == model.id ? "Heart model loaded" : "Loading heart model")
                .accessibilityIdentifier(presentation.failed ? "reference.failed" : !presentation.loading && presentation.displayedID == model.id ? "reference.ready" : "reference.loading")
                .overlay {
                    if presentation.failed {
                        VStack {
                            Text("This model could not be opened.").accessibilityIdentifier("reference.error")
                            if let id = presentation.displayedID, let previous = HeartProjectModel.all.first(where: { $0.id == id }) {
                                Text("Still showing \(previous.title)").font(.subheadline)
                            }
                            Button("Try again") { retry += 1 }
                        }.padding().heartPanel()
                    } else if presentation.loading || presentation.displayedID == nil {
                        VStack {
                            ProgressView("Opening \(model.title)…")
                            if let id = presentation.displayedID, let previous = HeartProjectModel.all.first(where: { $0.id == id }), id != model.id {
                                Text("Still showing \(previous.title)").font(.subheadline)
                            }
                        }.padding().heartPanel()
                    }
                }
        }
        .heartModelViewport()
        HStack(spacing: 12) {
            Button(scene.sectionAxis < 0 ? "Cross-section" : "Close section", systemImage: "circle.lefthalf.filled") {
                scene.setSection(scene.sectionAxis < 0 ? 2 : -1)
            }.accessibilityIdentifier("reference.section")
                .accessibilityValue(scene.preparingSection ? "Preparing" : scene.sectionAxis < 0 ? "Closed" : "Open")
                .accessibilityHint("Open the existing model surfaces to inspect inside. Keep the current pose and separated parts.")
            Button(scene.separated || scene.moved ? "Reassemble" : "Separate") { scene.separate(reduceMotion: reduceMotion) }
                .disabled(scene.parts.count < 2 && !scene.moved).accessibilityIdentifier("reference.separate")
                .accessibilityHint(scene.separated || scene.moved ? "Return all components to their assembled positions. Keep the current section and viewing pose." : "Spread source components apart for inspection.")
            Button("Parts") { showingParts.toggle() }.accessibilityIdentifier("reference.parts")
                .popover(isPresented: $showingParts) { partControls.heartPopover() }
            Spacer(minLength: 0)
            Button("Restore model") { scene.restore(reduceMotion: reduceMotion) }
                .accessibilityIdentifier("reference.restoreModel")
                .accessibilityHint("Show the whole model and return all parts to their assembled positions. Keep your viewing pose and lesson progress.")
        }.font(.subheadline).disabled(!scene.ready || presentation.loading || presentation.displayedID != model.id)
        if scene.sectionAxis >= 0 {
            HStack {
                Text("Cut direction").font(.subheadline)
                SpatialChoicePicker(title: "Cut direction",
                    selection: Binding(get: { String(scene.sectionAxis) }, set: { if let axis = Int($0) { scene.setSection(axis) } }),
                    choices: [.init(id: "2", title: "Depth"), .init(id: "0", title: "Width"), .init(id: "1", title: "Height")])
                    .accessibilityIdentifier("reference.sectionDirection")
            }
        }
        if scene.preparingSection { ProgressView("Preparing section…").font(.subheadline).accessibilityIdentifier("reference.preparingSection") }
        if let error = scene.sectionError { Text(error).font(.subheadline).accessibilityIdentifier("reference.sectionError") }
        if scene.sectionAxis >= 0 {
            Text("Geometric section: existing surfaces only. Missing walls and tissue layers are not reconstructed.").font(.footnote).foregroundStyle(HeartDesign.secondary)
        }
        }
        .task(id: model.id + "/" + String(retry)) {
            showingParts = false; rotationOffset = 0
            #if DEBUG
            if retry == 0 && ProcessInfo.processInfo.arguments.contains("--preview-reference-failure") {
                await presentation.present(HeartProjectModel(id: "Missing_Preview_Specimen", title: model.title, note: "", url: "", license: ""), reducedMotion: reduceMotion)
                return
            }
            #endif
            await presentation.present(model, reducedMotion: reduceMotion)
        }
        .onChange(of: presentation.loading) { _, loading in
            #if DEBUG
            guard !loading, presentation.displayedID == model.id else { return }
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "--preview-specimen-section"), index + 1 < args.count,
               let axis = Int(args[index + 1]), (0...2).contains(axis) { scene.setSection(axis) }
            if args.contains("--preview-specimen-separated") { scene.separate(reduceMotion: true) }
            #endif
        }
        .onChange(of: scene.selectedPart) { _, _ in scene.updateTether() }
        .onChange(of: resetRevision) { _, _ in rotationOffset = 0 }
        .onDisappear { presentation.cancel() }
            .task(id: rotating) {
                guard rotating, !reduceMotion, scenePhase == .active else { return }
                let clock = ContinuousClock()
                var previous = clock.now
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                    guard rotating, !reduceMotion, scenePhase == .active else { return }
                    let now = clock.now
                    let elapsed = previous.duration(to: now).components
                    previous = now
                    let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                    // One revolution per 30 seconds; avoid jumps after a stalled frame.
                    rotationOffset = (rotationOffset + min(0.1, max(0, seconds)) * .pi / 15).truncatingRemainder(dividingBy: 2 * .pi)
                }
            }

    }
    private var partControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("Inspect parts").font(.headline); Spacer(); Button("Done") { showingParts = false } }
            Picker("Selected part", selection: Binding(get: { scene.selectedPart }, set: { scene.selectedPart = $0 })) {
                ForEach(scene.parts) { Text($0.label).tag($0.id) }
            }.accessibilityIdentifier("reference.selectedPart")
            Text("Move the selected component. The line marks its assembled position.").font(.subheadline)
            HStack {
                Button("Left") { scene.movePart([-0.04, 0, 0], reduceMotion: reduceMotion) }
                Button("Right") { scene.movePart([0.04, 0, 0], reduceMotion: reduceMotion) }
                Button("Up") { scene.movePart([0, 0.04, 0], reduceMotion: reduceMotion) }
                Button("Down") { scene.movePart([0, -0.04, 0], reduceMotion: reduceMotion) }
            }
            HStack {
                Button("Nearer") { scene.movePart([0, 0, 0.04], reduceMotion: reduceMotion) }
                Button("Farther") { scene.movePart([0, 0, -0.04], reduceMotion: reduceMotion) }
                Button("Return part") { scene.returnPart(reduceMotion: reduceMotion) }
                    .accessibilityHint("Return only the selected component to its assembled position.")
            }
            Text(scene.parts.count < 2 ? "This source is not anatomically segmented. Its material fragments stay together." : "Source components are not necessarily individual organs or histological layers.").font(.subheadline)
        }.padding(24).frame(width: 480)
    }
}

struct HeartProjectView: View {
    var initialModel = "Normal_Teenage_Heart"
    var embedded = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotating = false
    @State private var resetRevision = 0
    @State private var selected = "Normal_Teenage_Heart"
    @State private var choosingModel = false
    @State private var showingModelInfo = false
    @State private var zoom = 1.0
    @State private var yaw = 0.0
    @State private var pitch = 0.0
    @GestureState private var drag = CGSize.zero
    private var model: HeartProjectModel { HeartProjectModel.all.first { $0.id == selected } ?? HeartProjectModel.all[0] }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("HEART ANATOMY").font(.subheadline).foregroundStyle(HeartDesign.secondary)
                    Text("See the anatomy you are learning to explain").font(.title2.bold())
                }
                Spacer()
                if !embedded { Button("Return to learning") { dismiss() } }
            }
            HStack {
                Text(model.title).font(.headline).accessibilityIdentifier("reference.currentModel")
                Spacer()
                Button("Choose model", systemImage: "square.grid.2x2") { choosingModel = true }
                    .accessibilityIdentifier("reference.chooseModel")
                    .popover(isPresented: $choosingModel) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { Text("Choose a heart model").font(.title2.bold()); Spacer(); Button("Done") { choosingModel = false } }
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                                    ForEach(HeartProjectModel.all) { candidate in
                                        Button { selected = candidate.id; choosingModel = false } label: {
                                            Text(candidate.title).font(.headline).fixedSize(horizontal: false, vertical: true)
                                                .frame(maxWidth: .infinity, minHeight: 72).padding(12)
                                        }.buttonStyle(HeartChipStyle(selected: candidate.id == selected))
                                            .accessibilityIdentifier("reference.choose." + candidate.id)
                                    }
                                }
                            }
                        }.padding(24).frame(width: 600, height: 480).heartPopover()
                    }
                Button("Model info", systemImage: "info.circle") { showingModelInfo = true }
                    .popover(isPresented: $showingModelInfo) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { Text(model.title).font(.title2.bold()); Spacer(); Button("Done") { showingModelInfo = false } }
                            Text(model.note).font(.body).accessibilityIdentifier("reference.note.\(model.id)")
                            Text("These models show later anatomy, not embryonic stages. They are fitted for viewing, so their displayed sizes cannot be compared.")
                            Text("Drag to rotate. Pinch or use Size to resize. Cross-section opens the existing surfaces; Parts lets you move and return components.")
                        }.padding(24).frame(width: 520).heartPopover()
                    }
            }
            HeartProjectViewport(model: model, obscured: choosingModel || showingModelInfo, zoom: zoom, yaw: yaw + Double(drag.width) * 0.008,
                                 pitch: max(-1.3, min(1.3, pitch + Double(drag.height) * 0.008)),
                                 rotating: rotating, resetRevision: resetRevision)
                .contentShape(Rectangle())
                .gesture(DragGesture().updating($drag) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        rotating = false
                        yaw += Double(value.translation.width) * 0.008
                        pitch = max(-1.3, min(1.3, pitch + Double(value.translation.height) * 0.008))
                    })
                .modifier(HeartPinchResize(zoom: $zoom, resetRevision: resetRevision, onBegin: { rotating = false }))
            HStack {
                HeartSizeControl(value: $zoom, label: "Heart size").frame(maxWidth: 380)
                Button(rotating ? "Pause rotation" : "Rotate model") { rotating.toggle() }
                    .disabled(reduceMotion)
                    .accessibilityIdentifier("reference.rotation")
                Button("Reset view") { resetView() }
                    .accessibilityIdentifier("reference.reset")
                    .accessibilityHint("Restore size and rotation. Keep the section and component positions.")
                Spacer()
            }
        }.padding(embedded ? 12 : 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: embedded ? nil : 1040, height: embedded ? nil : 720)
            .onChange(of: selected) { _, _ in resetView() }
            .onChange(of: drag) { _, value in if value != .zero { rotating = false } }
            .onChange(of: scenePhase) { _, phase in if phase != .active { rotating = false } }
            .onChange(of: reduceMotion) { _, enabled in if enabled { rotating = false } }
            .onDisappear { rotating = false }
            .onAppear {
                selected = initialModel
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let index = args.firstIndex(of: "--preview-reference"), index + 1 < args.count,
                   HeartProjectModel.all.contains(where: { $0.id == args[index + 1] }) { selected = args[index + 1] }
                #endif
            }
    }

    private func resetView() {
        resetRevision += 1
        rotating = false
        zoom = 1
        yaw = 0
        pitch = 0
    }
}

/// Shared appearance and loading for a reference embedded beside a process explanation.
struct HeartReferenceAnatomyPreview: View {
    let modelID: String
    var obscured = false
    var allowsDuctalComparison = true
    @State private var closedDuctus = false
    private var displayedID: String { modelID == "PDA_Patent" && closedDuctus ? "PDA_Closed" : modelID }
    @State private var yaw = 0.0
    @State private var pitch = 0.0
    @State private var zoom = 1.3
    @State private var revision = 0
    @GestureState private var drag = CGSize.zero
    var body: some View {
        if let model = HeartProjectModel.all.first(where: { $0.id == displayedID }) {
            VStack {
                if modelID == "PDA_Patent" && allowsDuctalComparison {
                    SpatialChoicePicker(title: "Ductal connection",
                        selection: Binding(get: { closedDuctus ? "closed" : "patent" }, set: { closedDuctus = $0 == "closed" }),
                        choices: [.init(id: "patent", title: "Patent ductus"), .init(id: "closed", title: "Closed remnant")])
                        .accessibilityIdentifier("reference.ductalComparison")
                    Text("Matched regional models · compare the connection after birth").font(.subheadline).foregroundStyle(HeartDesign.secondary)
                }
                HeartProjectViewport(model: model, obscured: obscured, zoom: zoom, yaw: yaw + Double(drag.width)*0.008,
                                     pitch: max(-1.3, min(1.3, pitch + Double(drag.height)*0.008)), rotating: false, resetRevision: revision)
                    .opacity(obscured ? 0 : 1)
                    .contentShape(Rectangle())
                    .gesture(DragGesture().updating($drag) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            yaw += Double(value.translation.width)*0.008
                            pitch = max(-1.3, min(1.3, pitch + Double(value.translation.height)*0.008))
                        })
                    .modifier(HeartPinchResize(zoom: $zoom, enabled: !obscured, resetRevision: revision))
                    .allowsHitTesting(!obscured)
                HStack {
                    HeartSizeControl(value: $zoom, label: "Reference size")
                    Button("Reset view") { reset() }.accessibilityIdentifier("reference.previewReset")
                        .accessibilityHint("Restore size and rotation. Keep the section and component positions.")
                }.disabled(obscured)
                Text("Drag to rotate · Pinch to resize · later anatomy").font(.subheadline)
            }
            .onAppear { reset() }
            .onChange(of: modelID) { old, new in
                closedDuctus = false
                if !(old.hasPrefix("PDA_") && new.hasPrefix("PDA_")) { reset() }
            }
        }
    }
    private func reset() { yaw = 0; pitch = modelID.hasPrefix("PDA_") ? 0.6 : 0; zoom = 1.3; revision += 1 }
}

/// An embedded guided comparison, scoped to this lesson's examples. Changing
/// representation keeps the lesson phase; it does not advance or score a learner.
struct HeartGuidedSpecimenView: View {
    let study: HeartGuidedAnatomy
    var obscured = false
    var startsAltered = false
    @State private var altered = false
    @State private var zoom = 1.0
    @State private var yaw = 0.0
    @State private var pitch = 0.0
    @State private var revision = 0
    @GestureState private var drag = CGSize.zero
    private var modelID: String { altered ? study.alteredID ?? study.normalID : study.normalID }
    private var model: HeartProjectModel? { HeartProjectModel.all.first { $0.id == modelID } }

    var body: some View {
        if let model {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Later anatomy · \(model.title)").font(.headline)
                        .accessibilityIdentifier("learning.specimenTitle")
                    Spacer()
                    if study.alteredID != nil {
                        SpatialChoicePicker(title: "Anatomy example",
                            selection: Binding(get: { altered ? "altered" : "normal" }, set: { altered = $0 == "altered" }),
                            choices: [.init(id: "normal", title: study.normalLabel), .init(id: "altered", title: study.alteredLabel)])
                            .frame(width: 310)
                            .accessibilityIdentifier("learning.specimenExample")
                    }
                }
                HeartProjectViewport(model: model, obscured: obscured, zoom: zoom,
                    yaw: yaw + Double(drag.width) * 0.008,
                    pitch: max(-1.3, min(1.3, pitch + Double(drag.height) * 0.008)),
                    rotating: false, resetRevision: revision)
                    .opacity(obscured ? 0 : 1)
                    .contentShape(Rectangle())
                    .gesture(DragGesture().updating($drag) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            yaw += Double(value.translation.width) * 0.008
                            pitch = max(-1.3, min(1.3, pitch + Double(value.translation.height) * 0.008))
                        })
                    .modifier(HeartPinchResize(zoom: $zoom, enabled: !obscured, resetRevision: revision))
                    .allowsHitTesting(!obscured)
                HStack {
                    HeartSizeControl(value: $zoom, label: "Specimen size")
                    Button("Reset view") { reset() }.accessibilityIdentifier("learning.specimenReset")
                        .accessibilityHint("Restore size and rotation. Keep the section and component positions.")
                }.disabled(obscured)
                Text(study.comparisonNote)
                    .font(.subheadline).foregroundStyle(HeartDesign.secondary)
            }
            .onChange(of: altered) { _, _ in if !study.isDuctalComparison { reset() } }
            .onAppear { altered = startsAltered && study.alteredID != nil; reset() }
        }
    }
    private func reset() { zoom = study.isDuctalComparison ? 1.3 : 1; yaw = 0; pitch = study.isDuctalComparison ? 0.6 : 0; revision += 1 }
}
