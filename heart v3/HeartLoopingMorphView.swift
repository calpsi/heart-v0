import SwiftUI
import RealityKit
import simd

private struct HeartMorphWallRequest: Equatable {
    let target: Double
    let animated: Bool
}
private struct HeartLayerMoveRequest: Equatable {
    let offsets: [Int: SIMD3<Float>]
    let animated: Bool
}
struct HeartLoopingMorphView: View {
    var obscured = false
    var timelineProgress: Binding<Double>? = nil
    var includesFusion = false
    var joiningOnly = false
    var scrubbing = false
    var outflow = false
    var savedSession: HeartMorphSession? = nil
    var onExploreConnection: (() -> Void)? = nil
    @State private var localSession = HeartMorphSession()
    private var session: HeartMorphSession { savedSession ?? localSession }
    private var isFusion: Bool { includesFusion && (progress < 1 || joiningOnly) }
    private var maximumProgress: Double { includesFusion && !joiningOnly ? 2 : 1 }
    private var meshProgress: Double { includesFusion ? progress - 1 : progress }
    private var phaseProgress: Double { isFusion ? progress : meshProgress }
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var progress: Double {
        get { timelineProgress?.wrappedValue ?? session.progress }
        nonmutating set {
            if let timelineProgress { timelineProgress.wrappedValue = newValue }
            else { session.progress = newValue }
        }
    }
    private var progressBinding: Binding<Double> {
        Binding(get: { progress }, set: { progress = $0 })
    }
    @State private var showingPrediction = false
    @State private var applyAfterDismissal = false
    @State private var showingSize = false
    @State private var learningProcess = HeartMorphLearning.Process.looping
    private var activeProcess: HeartMorphLearning.Process { outflow ? .outflow : isFusion ? .joining : .looping }
    private var practiceTitle: String {
        switch session.practice(activeProcess).phase {
        case .predict: "Predict, observe, explain"
        case .observe: "Observe the change"
        case .explain: "Explain what changed"
        case .feedback: "Review your explanation"
        }
    }
    @State private var playing = false
    private var cutaway: Bool {
        get { session.cutaway }
        nonmutating set { session.cutaway = newValue }
    }
    @State private var wallPresentation = HeartSeparationPresentation()
    @State private var hasPresentedWall = false
    private var showingLayers: Bool { !outflow }
    private var layersSeparated: Bool {
        get { session.layersSeparated }
        nonmutating set { session.layersSeparated = newValue }
    }
    @State private var layerPresentation = HeartSeparationPresentation()
    @State private var hasPresentedLayers = false
    @State private var showingLayerInfo = false
    @State private var showingLayerControls = false
    @State private var layerMovePresentation = HeartLayerMovePresentation()
    @State private var hasPresentedLayerMoves = false
    private var yaw: Double {
        get { session.yaw }
        nonmutating set { session.yaw = newValue }
    }
    private var pitch: Double {
        get { session.pitch }
        nonmutating set { session.pitch = newValue }
    }
    private var zoom: Double {
        get { session.zoom }
        nonmutating set { session.zoom = newValue }
    }
    private var zoomBinding: Binding<Double> { .init(get: { zoom }, set: { zoom = $0 }) }
    @State private var viewResetRevision = 0
    @State private var studio = Entity()
    @State private var model = ModelEntity()
    @State private var meshCache = HeartMorphMeshCache()
    @State private var appearance = HeartMorphAppearance()
    @State private var error = false
    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 16) {
            Text(outflow ? "From one outflow channel to two routes" : isFusion ? "From paired tubes to one channel" : "From a tube to a loop")
                .font(.title2.bold()).frame(maxWidth: .infinity, alignment: .leading)
            Button(practiceTitle, systemImage: "questionmark.circle") {
                playing = false
                learningProcess = activeProcess
                showingPrediction = true
            }.accessibilityIdentifier("morph.learning")
            }
            Text(HeartMorphLearning.observation(activeProcess, progress: phaseProgress))
                .font(.subheadline).multilineTextAlignment(.leading).lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("morph.observation")
            if outflow {
                HStack(spacing: 12) {
                    Button(layersSeparated ? "Reassemble components" : "Separate components") {
                        playing = false; layersSeparated.toggle()
                    }.accessibilityIdentifier("morph.separateComponents")
                    Text(layersSeparated ? "Inspection arrangement · Reassemble to judge whether the cushions meet."
                         : "Wall and two cushions · separation is for inspection, not development.")
                        .font(.subheadline).foregroundStyle(HeartDesign.secondary)
                    Button("Model info", systemImage: "info.circle") { playing = false; showingLayerInfo = true }
                        .labelStyle(.iconOnly).accessibilityHint("Read the animation scope and anatomical colour key.")
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: 12) {
                    Text("Tissue layers").font(.subheadline.bold())
                        .accessibilityIdentifier("morph.layers")
                    if showingLayers {
                        Button(layersSeparated || session.layersMoved ? "Reassemble layers" : "Separate layers") {
                            playing = false
                            viewResetRevision += 1
                            if layersSeparated || session.layersMoved { layersSeparated = false; session.layerOffsets = [:] }
                            else { layersSeparated = true; cutaway = true }
                        }.accessibilityIdentifier("morph.separateLayers")
                        Button("Move a layer") { playing = false; showingLayerControls = true }
                            .accessibilityIdentifier("morph.moveLayer")
                        if let isolated = session.isolatedLayer {
                            Button("Show all layers") { session.isolatedLayer = nil }
                                .accessibilityIdentifier("morph.showAllLayers")
                            Text("Only \(isolated.title)").font(.subheadline)
                                .accessibilityIdentifier("morph.isolatedLayer")
                        }
                        Button("About layers", systemImage: "info.circle") { playing = false; showingLayerInfo = true }
                            .labelStyle(.iconOnly)
                    }
                    Spacer(minLength: 0)
                }
            }
            // Let the model area absorb a smaller window. A tall hard minimum
            // pushed the parent's Home button and timeline outside its bounds.
            morphViewport.frame(minHeight: 180, maxHeight: .infinity).padding(.vertical, 12)
            HStack {
                Button(playing ? "Pause morph" : "Play morph") { if progress >= maximumProgress { progress = 0 }; playing.toggle() }
                    .disabled(reduceMotion || obscured || scrubbing)
                    .buttonStyle(HeartPrimaryButtonStyle())
                if timelineProgress == nil {
                HeartSlider(value: progressBinding, in: 0...maximumProgress, onEditingChanged: { if $0 { playing = false } })
                    .frame(minHeight: 44)
                    .accessibilityLabel(outflow ? "Outflow progression" : includesFusion ? "Development progression" : "Looping progression")
                } else {
                    EmptyView()
                    Spacer()
                }
                Text("\(Int((phaseProgress*100).rounded()))%").monospacedDigit().frame(width: 48)
                Button(visibleCutaway ? "Close wall" : "Open wall") { playing = false; cutaway.toggle() }
                    .disabled(isFusion)
                    .accessibilityIdentifier("morph.wall")
                    .accessibilityValue(renderedOpening == (visibleCutaway ? 1 : 0) ? (visibleCutaway ? "Open" : "Closed") : "Changing inspection cut")
                    .accessibilityHint(isFusion ? "Wall opening is available after the tubes have joined. Your inspection choice will return when you scrub forwards." : "Reveal or close the tube lumen.")
                Button("Reset morph") { playing = false; progress = 0; resetView(); cutaway = false; layersSeparated = false; session.layerOffsets = [:]; session.isolatedLayer = nil }
                Button { playing = false; showingSize = true } label: {
                    Text("Size \(zoom, format: .number.precision(.fractionLength(1)))×").monospacedDigit()
                }.accessibilityIdentifier("morph.size")
                    .accessibilityLabel("Model size").accessibilityValue("\(zoom, format: .number.precision(.fractionLength(1)))×")
                    .popover(isPresented: $showingSize) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { Text("Model size").font(.headline); Spacer(); Button("Done") { showingSize = false }.accessibilityIdentifier("morph.sizeDone") }
                            Label("Drag the model to rotate · Pinch to resize", systemImage: "hand.draw").font(.subheadline)
                            HeartSlider(value: zoomBinding, in: HeartModelZoom.range)
                                .accessibilityLabel("Morph size")
                            Text("\(zoom, format: .number.precision(.fractionLength(1)))× · Changes viewing size only.")
                                .font(.subheadline)
                        }.padding(24).frame(width: 420).heartPopover()
                    }
                Button("Reset view") { resetView() }.accessibilityIdentifier("morph.resetView")
            }
            .padding(10)
            .zIndex(1)
        }.padding(.horizontal, 16).padding(.vertical, 12)

            .sheet(isPresented: $showingPrediction, onDismiss: {
                // Finish dismissing the practice panel before replacing its
                // parent workspace with the related anatomy.
                if applyAfterDismissal { applyAfterDismissal = false; onExploreConnection?() }
            }) { practiceSheet }
            .popover(isPresented: $showingLayerInfo) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("About this animation").font(.headline); Spacer(); Button("Done") { showingLayerInfo = false } }
                    ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                    scopeNote
                    regionLegend
                    if !outflow {
                    ForEach(HeartTubeLayer.allCases, id: \.rawValue) { layer in
                        Text("\(layer.title): \(layer.explanation).")
                    }
                    Text("Open the wall to see the layers together, or separate them to follow each through joining and looping. Separation is an inspection arrangement.")
                    Text("Simplified teaching layers. Their thickness and circular shape are illustrative, not measured histology. Later regional remodelling and trabeculation are not shown.")
                        .font(.subheadline).foregroundStyle(HeartDesign.secondary)
                    } else {
                        Text("The wall and two cushions can be separated for inspection. Reassemble them before judging whether the partition meets.")
                    }
                    }
                    }.scrollBounceBehavior(.basedOnSize)
                }.padding(24).frame(width: 460, height: 540).heartPopover()
            }
            .popover(isPresented: $showingLayerControls) { layerControls.heartPopover() }
            .onChange(of: progress) { _, value in
                guard !obscured && !showingPrediction && !showingLayerInfo else { return }
                if includesFusion {
                    session.updatePractice(.joining) { $0.observe(value) }
                    session.updatePractice(.looping) { $0.observe(value - 1) }
                } else { session.updatePractice(activeProcess) { $0.observe(value) } }
            }
            .onChange(of: scrubbing) { _, active in if active { playing = false } }
            .onChange(of: reduceMotion) { _, reduced in if reduced { playing = false } }
            .onChange(of: obscured) { _, hidden in if hidden { playing = false } }
            .task(id: wallRequest) {
                let request = wallRequest
                await wallPresentation.update(to: request.target, animated: request.animated)
                if !Task.isCancelled { hasPresentedWall = true }
            }
            .task(id: layerRequest) {
                await layerPresentation.update(to: layerRequest.target, animated: layerRequest.animated)
                if !Task.isCancelled { hasPresentedLayers = true }
            }
            .task(id: layerMoveRequest) {
                await layerMovePresentation.update(to: layerMoveRequest.offsets, animated: layerMoveRequest.animated)
                if !Task.isCancelled { hasPresentedLayerMoves = true }
            }
            .task(id: playing) {
                guard playing else { return }
                let clock = ContinuousClock()
                var previous = clock.now
                while !Task.isCancelled && progress < maximumProgress {
                    do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                    guard !obscured && !scrubbing && !reduceMotion && scenePhase == .active else { break }
                    let now = clock.now
                    let elapsed = previous.duration(to: now).components
                    let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                    previous = now
                    progress = min(maximumProgress, progress + min(seconds, 0.1) / 6)
                }
                playing = false
            }
            .onDisappear { playing = false }
            .onChange(of: scenePhase) { _, phase in if phase != .active { playing = false } }
            .onAppear {
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if args.contains("--preview-tube-layers-separated") { layersSeparated = true }
                if args.contains("--preview-tube-wall-open") && !outflow { cutaway = true }
                if let index = args.firstIndex(of: "--preview-isolated-tube-layer"), index + 1 < args.count,
                   let value = Int(args[index + 1]), let layer = HeartTubeLayer(rawValue: value), !outflow {
                    session.selectLayer(layer); session.isolatedLayer = layer
                }
                #endif
            }
    }
    private var layerControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("Inspect one layer").font(.headline); Spacer(); Button("Done") { showingLayerControls = false } }
            Picker("Selected tissue layer", selection: Binding(get: { session.selectedLayer }, set: { session.selectLayer($0) })) {
                ForEach(HeartTubeLayer.allCases, id: \.rawValue) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            Text(session.selectedLayer.explanation).font(.subheadline)
            Button(session.isolatedLayer == nil ? "Isolate layer" : "Show all layers") {
                session.isolatedLayer = session.isolatedLayer == nil ? session.selectedLayer : nil
            }.accessibilityIdentifier("morph.layerVisibility")
                .accessibilityHint("Changes visibility only. The wall opening, layer positions and developmental progress are retained.")
            HStack {
                layerMoveButton("Left", [-0.006, 0, 0]); layerMoveButton("Right", [0.006, 0, 0])
                layerMoveButton("Up", [0, 0.006, 0]); layerMoveButton("Down", [0, -0.006, 0])
            }
            HStack {
                layerMoveButton("Nearer", [0, 0, 0.006]); layerMoveButton("Farther", [0, 0, -0.006])
                Button("Reset layer move") { session.resetLayerMove() }
            }
            Text("Move only the selected layer within the inspection area. Reset layer move returns it to its current assembled or separated slot; Reassemble layers restores the whole arrangement.")
                .font(.subheadline).foregroundStyle(HeartDesign.secondary)
        }.padding(24).frame(width: 510)
    }
    private func layerMoveButton(_ title: String, _ delta: SIMD3<Float>) -> some View {
        Button(title) { session.moveLayer(model.orientation.inverse.act(delta)) }
    }
    private var practiceSheet: some View {
        let attempt = session.practice(learningProcess)
        let prediction = HeartMorphLearning.check(learningProcess)
        let explanation = HeartMorphLearning.explanationCheck(learningProcess)
        return VStack(alignment: .leading, spacing: 18) {
            switch attempt.phase {
            case .predict:
                Text("Predict before you replay").font(.title2.bold())
                Text(prediction.question).font(.headline)
                ForEach(prediction.options.indices, id: \.self) { index in
                    Button(prediction.options[index]) {
                        session.updatePractice(learningProcess) { $0.predict(index, at: phaseProgress) }
                    }.accessibilityIdentifier("morph.answer.\(index)")
                }
            case .observe:
                Text("Prediction saved — now observe").font(.title2.bold())
                Text("Return to the model and compare two positions using the timeline or playback. Watch what changes and what stays connected.")
                if learningProcess == .outflow && layersSeparated {
                    Text("Reassemble the components before judging whether a partition forms.")
                }
                Text("Then choose Explain what changed. Moving through the animation is a practice step, not a score.").font(.subheadline)
            case .explain:
                Text("Explain what you observed").font(.title2.bold())
                Text(explanation.question).font(.headline)
                ForEach(explanation.options.indices, id: \.self) { index in
                    Button(explanation.options[index]) {
                        session.updatePractice(learningProcess) { $0.explain(index) }
                    }.accessibilityIdentifier("morph.reason.\(index)")
                }
            case .feedback:
                Text(attempt.skipped ? "Explanation viewed without completing practice"
                     : attempt.explanation == explanation.answer ? "Your explanation matches the illustrated change"
                     : "Compare your explanation with the model").font(.headline)
                Text(explanation.explanation).accessibilityIdentifier("morph.explanation")
                Text(prediction.explanation)
                Text(explanation.observation).font(.subheadline)
                Text("Explain it again in your own words, without reading this panel. This practice is not a measure of clinical understanding.")
                    .font(.subheadline).foregroundStyle(HeartDesign.secondary)
                Button("Practise again") { session.updatePractice(learningProcess) { $0.restart() } }
                    .accessibilityIdentifier("morph.practiceAgain")
                if onExploreConnection != nil {
                    Button("Apply this to related anatomy", systemImage: "arrow.triangle.branch") {
                        applyAfterDismissal = true
                        showingPrediction = false
                    }.accessibilityIdentifier("morph.applyConnection")
                }
            }
            if attempt.phase != .feedback {
                Button("Show explanation without answering") { session.updatePractice(learningProcess) { $0.reveal() } }
                    .accessibilityIdentifier("morph.skipPractice")
            }
            Button("Return to the animation") { showingPrediction = false }
        }.padding(28).frame(width: 610)
    }
    private var regionLegend: some View {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                ForEach(outflow ? [.arterial, .atrioventricular] : isFusion ? [.ventricular] : HeartAnatomyRegion.allCases, id: \.rawValue) { region in
                    let rgb = outflow ? region.rgb : region.morphRGB(progress: meshProgress)
                    HStack(spacing: 5) {
                        Circle().fill(Color(red: rgb.x, green: rgb.y, blue: rgb.z)).frame(width: 14, height: 14)
                        Text(isFusion ? "Tube wall" : outflow && region == .atrioventricular ? "Outflow cushions" : region.title)
                    }
                }
            }.font(.subheadline).accessibilityIdentifier("morph.regionLegend")
    }
    private var scopeNote: some View {
        Text(outflow ? "Division illustration; ventricular alignment and cellular remodelling are not simulated."
             : isFusion ? "Joining illustration; body folding and cellular remodelling are not shown."
             : "Bending illustration; later chamber partitioning is not shown.")
            .font(.subheadline).foregroundStyle(HeartDesign.secondary)
    }

    private var visibleCutaway: Bool { outflow ? !cutaway : cutaway && !isFusion }
    private var wallRequest: HeartMorphWallRequest {
        .init(target: visibleCutaway ? 1 : 0,
              animated: hasPresentedWall && !reduceMotion && !obscured && !showingPrediction && scenePhase == .active && !isFusion)
    }
    private var renderedOpening: Double {
        isFusion ? 0 : hasPresentedWall ? wallPresentation.value : (visibleCutaway ? 1 : 0)
    }
    private var layerRequest: HeartMorphWallRequest {
        .init(target: layersSeparated ? 1 : 0,
              animated: hasPresentedLayers && !reduceMotion && !obscured && !showingPrediction && scenePhase == .active)
    }
    private var renderedSeparation: Double { hasPresentedLayers ? layerPresentation.value : (layersSeparated ? 1 : 0) }
    private var layerMoveRequest: HeartLayerMoveRequest {
        .init(offsets: session.layerOffsets, animated: hasPresentedLayerMoves && !reduceMotion && !obscured && scenePhase == .active)
    }
    private var renderedLayerOffsets: [Int: SIMD3<Float>] { hasPresentedLayerMoves ? layerMovePresentation.offsets : session.layerOffsets }

    private func installMorph() async {
        do {
            let mesh = try meshCache.resource(progress: meshProgress, opening: renderedOpening, outflow: outflow,
                                             layers: showingLayers, separation: renderedSeparation, offsets: renderedLayerOffsets, visibleLayer: session.isolatedLayer)
            model.model = ModelComponent(mesh: mesh, materials: [])
            appearance.apply(to: model, progress: meshProgress, outflow: outflow)
            studio.addChild(model)
            try await HeartModelLighting.install(on: studio, receiving: model)
        } catch { self.error = true }
    }

    private func updateMorph() {
        model.isEnabled = !obscured && !showingPrediction && !showingLayerInfo
        do {
            let mesh = try meshCache.resource(progress: meshProgress, opening: renderedOpening, outflow: outflow,
                                             layers: showingLayers, separation: renderedSeparation, offsets: renderedLayerOffsets, visibleLayer: session.isolatedLayer)
            // Mutable vertices update in place. Reinstall only at a topology
            // boundary; setting the same component every frame adds scene work.
            if model.model?.mesh !== mesh { model.model?.mesh = mesh }
            appearance.apply(to: model, progress: meshProgress, outflow: outflow)
            if error { error = false }
        } catch {
            self.error = true
            playing = false
        }
    }

    private func fitMorph(in frame: BoundingBox) {
        model.transform = meshCache.placement(in: frame, zoom: zoom,
            yaw: yaw, pitch: pitch, outflow: outflow, inspectionRotation: session.orientation)
    }

    private func resetView() { yaw = 0; pitch = 0; session.rotation = nil; zoom = 1; viewResetRevision += 1 }

    private var morphViewport: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                await installMorph()
                content.add(studio)
            } update: { content in
                updateMorph()
                fitMorph(in: content.convert(geometry.frame(in: .local), from: .local, to: .scene))
            }
            .realityViewLayoutBehavior(.flexible).clipped()
            .overlay {
                if error { Text("The morph could not be opened.").accessibilityIdentifier("morph.error") }
            }
        }
        .heartModelViewport()
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("morph.viewport")
        .accessibilityHint("Drag to rotate. Pinch to resize, or use Model size.")
        .modifier(HeartModelGestures(
            orientation: Binding(get: { session.orientation }, set: { session.orientation = $0 }),
            zoom: zoomBinding,
            enabled: !obscured && !showingPrediction && !showingLayerInfo && !showingLayerControls && !showingSize,
            resetRevision: viewResetRevision, targetsEntities: false, onBegin: { playing = false }))
        .allowsHitTesting(!obscured && !showingPrediction && !showingLayerInfo && !showingLayerControls && !showingSize)
    }
}
