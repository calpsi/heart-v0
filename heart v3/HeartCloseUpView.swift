import SwiftUI
import RealityKit
import RealityKitContent
import simd

struct HeartCloseUpRequest: Codable, Hashable {
    let assetID: String
    let controls: HeartModelControls
}

/// A volume grows naturally in apparent size when moved toward the viewer.
/// Its ornament stays outside the bounds that contain the enlarged anatomy.
struct HeartCloseUpView: View {
    let asset: HeartAsset
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var controls: HeartModelControls
    @State private var scene = HeartModelScene()
    @State private var dragStart: simd_quatf?
    @State private var partDrag: (id: String, start: SIMD3<Float>)?
    @State private var pinchStart: Double?
    @State private var suppressSelectionUntil = Date.distantPast

    init(asset: HeartAsset, controls: HeartModelControls) {
        self.asset = asset
        _controls = State(initialValue: controls)
    }

    private var selectedLabel: String? {
        asset.parts.first { $0.id == controls.selectedPart }?.label
    }

    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                do {
                    let model = try await Entity(named: "HeartAssets/\(asset.id)", in: realityKitContentBundle)
                    guard !Task.isCancelled else { return }
                    try await scene.install(model, asset: asset)
                    content.add(scene.holder)
                    updateScene(in: content.convert(geometry.frame(in: .local), from: .local, to: .scene))
                    scene.ready = true
                } catch {
                    scene.errorMessage = "This model couldn’t be opened."
                }
            } update: { content in
                updateScene(in: content.convert(geometry.frame(in: .local), from: .local, to: .scene))
            }
            .realityViewLayoutBehavior(.flexible)
            .gesture(DragGesture(minimumDistance: 8).targetedToAnyEntity()
                .exclusively(before: SpatialTapGesture().targetedToAnyEntity())
                .onChanged { value in
                    if case .first(let drag) = value {
                        suppressSelectionUntil = Date().addingTimeInterval(0.25)
                        guard pinchStart == nil else { dragStart = nil; return }
                        if controls.moveParts {
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
                    case .first: dragStart = nil; partDrag = nil
                    case .second(let tap):
                        guard pinchStart == nil, Date() >= suppressSelectionUntil else { return }
                        controls.selectedPart = scene.partID(for: tap.entity, asset: asset) ?? ""
                    }
                })
            .simultaneousGesture(MagnifyGesture().targetedToAnyEntity()
                .onChanged { value in
                    guard partDrag == nil else { return }
                    suppressSelectionUntil = Date().addingTimeInterval(0.25)
                    if pinchStart == nil { pinchStart = controls.zoom }
                    controls.zoom = HeartModelZoom.clamped((pinchStart ?? 1) * value.magnification)
                }
                .onEnded { _ in
                    pinchStart = nil
                    suppressSelectionUntil = Date().addingTimeInterval(0.25)
                })
            .overlay {
                if let error = scene.errorMessage {
                    Text(error).padding(24).glassBackgroundEffect()
                } else if !scene.ready {
                    ProgressView("Loading close-up").padding(24).glassBackgroundEffect()
                }
            }
        }
        .ornament(attachmentAnchor: .scene(.topFront), contentAlignment: .bottomBack) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(controls.showLabels ? (selectedLabel ?? asset.lesson) : asset.lesson)
                            .font(.headline).fixedSize(horizontal: false, vertical: true)
                        Text(controls.moveParts ? "Drag individual tissues apart · Return parts when finished" : "Move this 3D window closer · Drag to rotate · Pinch to resize")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset view", systemImage: "arrow.counterclockwise") { resetView() }
                        .buttonStyle(.borderedProminent).foregroundStyle(.black)
                        .disabled(!scene.ready)
                        .accessibilityHint("Restore the original size and viewing angle.")
                    Button { dismissWindow() } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }.buttonStyle(.plain).accessibilityLabel("Close 3D close-up")
                }
                HStack(spacing: 16) {
                    Text("Size").font(.subheadline)
                    Slider(value: $controls.zoom, in: HeartModelZoom.range).frame(width: 250)
                        .accessibilityLabel("Close-up model size")
                        .accessibilityValue("\(Int((controls.zoom * 100).rounded())) percent")
                    Text("\(controls.zoom, format: .number.precision(.fractionLength(1)))×")
                    Spacer(minLength: 0)
                    Button(controls.isolate ? "Show all" : "Focus", systemImage: "scope") {
                        controls.moveParts = false
                        controls.isolate.toggle()
                        controls.zoom = 1
                    }.foregroundStyle(.black).disabled(controls.selectedPart.isEmpty)
                        .accessibilityIdentifier(controls.isolate ? "closeUp.showAll" : "closeUp.focus")
                    if asset.hasCutaway {
                        Toggle("Cutaway", isOn: $controls.cutaway).toggleStyle(.button)
                    }
                }.disabled(!scene.ready)
                HStack {
                    Toggle("Move parts", isOn: $controls.moveParts).toggleStyle(.button)
                    Button("Return selected part", systemImage: "arrow.uturn.backward") {
                        controls.partOffsets.removeValue(forKey: controls.selectedPart)
                    }.disabled(controls.partOffsets[controls.selectedPart] == nil)
                    Button("Reassemble", systemImage: "square.3.layers.3d") { controls.reassemble() }
                        .disabled(controls.partOffsets.isEmpty && controls.separation == 0)
                }.disabled(!scene.ready)
                if let states = asset.states, states.count > 1 {
                    SpatialChoicePicker(title: "Compare anatomy", selection: Binding(
                        get: { controls.developmentState ?? asset.defaultState ?? states[0].id },
                        set: { controls.developmentState = $0; controls.selectedPart = ""; controls.isolate = false; controls.reassemble() }
                    ), choices: states.map { .init(id: $0.id, title: $0.label) })
                        .disabled(!scene.ready)
                }
            }
            .padding(20).frame(width: 700)
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        }
        .onChange(of: controls.cutaway) { _, enabled in
            if enabled, controls.selectedPart.hasSuffix("_Anterior") {
                controls.selectedPart = controls.selectedPart.replacingOccurrences(of: "_Anterior", with: "_Posterior")
            }
        }
        .onChange(of: controls.moveParts) { _, moving in
            partDrag = nil; dragStart = nil
            if moving { controls.isolate = false }
        }
        .onChange(of: controls.selectedPart) { _, selected in
            guard partDrag == nil else { return }
            if selected.isEmpty { controls.isolate = false }
            if selected.hasSuffix("_Anterior") { controls.cutaway = false }
            if selected.hasSuffix("_Posterior") { controls.cutaway = true }
        }
    }

    private func updateScene(in available: BoundingBox) {
        scene.apply(asset: asset, selected: controls.selectedPart, isolate: controls.isolate,
                    cutaway: controls.cutaway, context: controls.showContext,
                    separation: Float(controls.separation), state: controls.developmentState,
                    transparent: controls.transparent, partOffsets: controls.partOffsets)
        scene.spin.orientation = controls.orientation
        scene.fit(in: available, zoom: Float(controls.zoom), selected: controls.selectedPart, volumetric: true)
    }

    private func resetView() {
        controls.resetView(asset: asset)
        dragStart = nil; pinchStart = nil
        suppressSelectionUntil = Date().addingTimeInterval(0.25)
    }
}
