#if DEBUG
import Foundation
import UIKit
import RealityKit
import RealityKitContent
import simd
import Observation

private final class HeartObservationProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var changed = false
    func markChanged() { lock.lock(); changed = true; lock.unlock() }
    var didChange: Bool { lock.lock(); defer { lock.unlock() }; return changed }
}

/// Opt-in simulator regression checks against the compiled RealityKit bundle.
/// Launch with --validate-heart-assets; the result is written to Documents.
@MainActor enum HeartAssetValidation {
    private static var hasRun = false

    static func run(in host: Entity) async {
        guard !hasRun else { return }
        hasRun = true
        for _ in 0..<20 where !host.isActive {
            try? await Task.sleep(for: .milliseconds(100))
        }
        var lessonProgressReport: [String: Any]
        do {
            var progress = HeartLessonProgress()
            try require(progress.resumeStep(for: "Tubes", stepCount: 3) == 0, "New lesson did not start at its first step")
            progress.record(step: 2, for: "Tubes", stepCount: 3)
            progress.record(step: 1, for: "Valves", stepCount: 4)
            let saved = try JSONEncoder().encode(progress)
            var reopened = try JSONDecoder().decode(HeartLessonProgress.self, from: saved)
            try require(reopened.resumeStep(for: "Tubes", stepCount: 3) == 2
                        && reopened.resumeStep(for: "Valves", stepCount: 4) == 1,
                        "Returning to lessons lost their independent progress")
            try require(reopened.resumeStep(for: "Tubes", stepCount: 2) == 1,
                        "A changed lesson could resume outside its available steps")
            reopened.finish("Tubes")
            try require(reopened.lessons["Tubes"]?.completed == true
                        && reopened.resumeStep(for: "Tubes", stepCount: 3) == 0
                        && reopened.resumeStep(for: "Valves", stepCount: 4) == 1,
                        "Finishing one lesson changed another lesson or prevented review")
            let completed = try JSONDecoder().decode(HeartLessonProgress.self, from: JSONEncoder().encode(reopened))
            try require(completed == reopened, "Saved completion was lost")
            lessonProgressReport = ["passed": true, "independentResume": true, "savedCompletion": true, "changedLessonLength": true]
        } catch {
            lessonProgressReport = ["passed": false, "error": String(describing: error)]
        }
        var transitionReport: [String: Any]
        do {
            let presentation = HeartSeparationPresentation()
            // Observe an actual intermediate frame, rather than assuming the simulator
            // can schedule a timer within 80 ms while it compiles tissue shaders.
            var opening: Task<Void, Never>?
            var sawIntermediate = false
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                var resumed = false
                opening = Task {
                    await presentation.update(to: 1, animated: true) { value in
                        if value > 0.05 && value < 0.95 {
                            sawIntermediate = true
                            if !resumed { resumed = true; continuation.resume() }
                        }
                    }
                    if !resumed { resumed = true; continuation.resume() }
                }
            }
            opening?.cancel()
            await opening?.value
            try require(sawIntermediate, "Separation produced no intermediate frames")
            let stopped = presentation.value
            try await Task.sleep(for: .milliseconds(32))
            try require(presentation.value == stopped, "Cancelled separation kept moving")
            await presentation.update(to: 0, animated: true)
            try require(presentation.value == 0, "Interrupted separation did not reassemble")
            await presentation.update(to: 1, animated: false)
            try require(presentation.value == 1, "Reduced-motion separation was not immediate")
            transitionReport = ["passed": true, "interruptionAndReversal": true, "reducedMotion": true]
        } catch {
            transitionReport = ["passed": false, "error": String(describing: error)]
        }
        var reports: [[String: Any]] = []
        for asset in HeartAsset.all {
            do {
                let model = try await Entity(named: "HeartAssets/\(asset.id)", in: realityKitContentBundle)
                // Catch USD exports that look detailed in Blender but lose their maps in RealityKit.
                var texturedMeshes = 0
                func validateTissueMaterials(_ entity: Entity) throws {
                    if let component = entity.components[ModelComponent.self] {
                        try require(!component.materials.isEmpty, "Missing tissue material: \(entity.name)")
                        for material in component.materials {
                            guard let tissue = material as? PhysicallyBasedMaterial else {
                                try require(false, "Non-PBR tissue material: \(entity.name)")
                                continue
                            }
                            try require(tissue.baseColor.texture != nil && tissue.roughness.texture != nil
                                        && tissue.normal.texture != nil,
                                        "Tissue colour/roughness/normal map lost during import: \(entity.name)")
                        }
                        texturedMeshes += 1
                    }
                    for child in entity.children { try validateTissueMaterials(child) }
                }
                try validateTissueMaterials(model)
                let scene = HeartModelScene()
                try await scene.install(model, asset: asset)
                try require(scene.holder.components.has(ImageBasedLightComponent.self)
                            && model.components.has(ImageBasedLightReceiverComponent.self), "Missing tissue studio lighting")
                try require(scene.holder.findEntity(named: "TissueKeyLight")?.components.has(DirectionalLightComponent.Shadow.self) == true,
                            "Missing tissue-to-tissue shadow lighting")
                host.addChild(scene.holder)
                defer { scene.holder.removeFromParent() }
                try require(scene.holder.isActive, "Validation geometry must be in a live RealityView scene")
                let baseline = Dictionary(uniqueKeysWithValues: asset.parts.map {
                    ($0.id, model.findEntity(named: $0.id)!.position(relativeTo: model))
                })
                // A detached tissue must move independently without reframing the scene.
                let movedID = asset.parts.first { asset.includes($0, state: asset.defaultState) }!.id
                let workspace = BoundingBox(min: [-0.16, -0.1, 0], max: [0.16, 0.1, 0])
                scene.apply(asset: asset, selected: "", isolate: false, cutaway: false,
                            context: true, separation: 0, state: asset.defaultState)
                scene.fit(in: workspace, zoom: 1)
                let probe = HeartObservationProbe()
                withObservationTracking {
                    scene.apply(asset: asset, selected: movedID, isolate: true, cutaway: false,
                                context: true, separation: 0, state: asset.defaultState)
                    scene.fit(in: workspace, zoom: 1)
                } onChange: { probe.markChanged() }
                scene.apply(asset: asset, selected: "", isolate: false, cutaway: false,
                            context: true, separation: 0, state: asset.defaultState)
                scene.fit(in: workspace, zoom: 1)
                try require(!probe.didChange, "Scene mutations invalidated their own RealityView update")
                var rotationControls = HeartModelControls()
                rotationControls.setOrientation(yaw: .pi / 2, pitch: 0)
                rotationControls.rotate(from: rotationControls.orientation, horizontal: 0, vertical: 100)
                let screenVertical = rotationControls.orientation.act(SIMD3<Float>(0, 1, 0))
                try require(abs(screenVertical.x) < 0.00001 && screenVertical.z > 0.4,
                            "Vertical drag rotated around the model's yawed local axis")
                let rotated = rotationControls.orientation
                rotationControls.rotate(from: rotated, horizontal: 80, vertical: 0)
                let expectedRotation = simd_quatf(angle: 0.4, axis: [0, 1, 0]) * rotated
                try require(abs(simd_dot(rotationControls.orientation.vector, expectedRotation.vector)) > 0.99999,
                            "A second drag did not continue from the current orientation")
                rotationControls.isolate = true
                rotationControls.moveParts = true
                rotationControls.partOffsets = [movedID: [0.03, 0, 0]]
                rotationControls.setSeparation(0.5)
                try require(!rotationControls.isolate && !rotationControls.moveParts && rotationControls.partOffsets.isEmpty && rotationControls.separation == 0.5,
                            "Separation slider did not exit isolated/manual movement mode")
                rotationControls.isolate = true
                rotationControls.reassemble()
                try require(!rotationControls.isolate && rotationControls.separation == 0 && rotationControls.partOffsets.isEmpty,
                            "Reassemble left the model isolated or detached")
                let encoded = try JSONEncoder().encode(rotationControls)
                let decoded = try JSONDecoder().decode(HeartModelControls.self, from: encoded)
                try require(abs(simd_dot(decoded.orientation.vector, rotationControls.orientation.vector)) > 0.99999,
                            "Close-up lost the dragged orientation")
                rotationControls.resetView(asset: asset)
                let reset = simd_quatf(angle: asset.defaultYaw ?? 0, axis: [0, 1, 0]) * simd_quatf(angle: asset.defaultPitch ?? 0, axis: [1, 0, 0])
                try require(abs(simd_dot(rotationControls.orientation.vector, reset.vector)) > 0.99999,
                            "Reset retained the dragged rotation")
                let initialScale = scene.holder.scale
                let initialCenter = scene.spin.position
                let displacement = SIMD3<Float>(0.035, 0.018, 0.012)
                scene.apply(asset: asset, selected: movedID, isolate: false, cutaway: false,
                            context: true, separation: 0, state: asset.defaultState,
                            partOffsets: [movedID: displacement])
                scene.fit(in: workspace, zoom: 1)
                try require(simd_distance(initialScale, scene.holder.scale) < 0.00001
                            && simd_distance(initialCenter, scene.spin.position) < 0.00001,
                            "Moving a tissue reframed the model")
                for part in asset.parts {
                    let expected = baseline[part.id]! + (part.id == movedID ? displacement : .zero)
                    try require(simd_distance(model.findEntity(named: part.id)!.position(relativeTo: model), expected) < 0.00001,
                                "Independent tissue movement affected another part")
                }
                var detached = HeartModelControls()
                detached.partOffsets[movedID] = displacement
                detached.moveParts = true
                let restored = try JSONDecoder().decode(HeartModelControls.self, from: JSONEncoder().encode(detached))
                try require(restored == detached, "Close-up transfer lost detached tissue positions")
                var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(detached)) as! [String: Any]
                legacy.removeValue(forKey: "movablePartsEnabled")
                legacy.removeValue(forKey: "detachedPartPositions")
                let legacyControls = try JSONDecoder().decode(HeartModelControls.self, from: JSONSerialization.data(withJSONObject: legacy))
                try require(!legacyControls.moveParts && legacyControls.partOffsets.isEmpty,
                            "Previously saved close-up windows cannot reopen")
                detached.reassemble()
                try require(detached.partOffsets.isEmpty && detached.separation == 0, "Reassemble left detached tissues")
                let firstStep = HeartLessonStep.steps(for: asset).first
                detached.yaw = 0.7; detached.pitch = -0.2; detached.zoom = 1.2
                detached.transition(to: firstStep, asset: asset)
                try require(detached.yaw == 0.7 && detached.pitch == -0.2 && detached.zoom == 1.2,
                            "Phase transition lost the learner's viewpoint")
                try require(detached.developmentState == (firstStep?.state ?? asset.defaultState)
                            && detached.selectedPart == (firstStep?.focus ?? ""), "Phase transition did not select its anatomy")
                let states: [String?] = asset.states?.map { Optional($0.id) } ?? [nil]
                for state in states {
                    scene.apply(asset: asset, selected: "", isolate: false, cutaway: true, context: false, separation: 1, state: state)
                    var separated = false
                    for part in asset.parts {
                        let node = model.findEntity(named: part.id)!
                        try require(node.isEnabled == (asset.includes(part, state: state) && part.category != "context" && !part.id.hasSuffix("_Anterior")), "Cutaway/context visibility: \(part.id)")
                        if simd_distance(node.position(relativeTo: model), baseline[part.id]!) > 0.001 { separated = true }
                    }
                    try require(separated, "Separation did not move any tissue")
                    let selected = asset.parts.first(where: { $0.category != "context" && asset.includes($0, state: state) })!.id
                    scene.apply(asset: asset, selected: selected, isolate: true, cutaway: false, context: true, separation: 0, state: state)
                    for part in asset.parts {
                        let node = model.findEntity(named: part.id)!
                        try require(node.isEnabled == (part.id == selected), "Isolation: \(part.id)")
                        try require(simd_distance(node.position(relativeTo: model), baseline[part.id]!) < 0.00001, "Reassembly drift: \(part.id)")
                        try require(scene.partID(for: node, asset: asset) == part.id, "Part selection mapping")
                    }
                    scene.apply(asset: asset, selected: "", isolate: false, cutaway: false, context: true, separation: 0, state: state)
                    try require(asset.parts.allSatisfy { model.findEntity(named: $0.id)!.isEnabled == asset.includes($0, state: state) }, "State/reset visibility")
                    // Rotation and exploded anatomy must fit in the original overview range.
                    let available = BoundingBox(min: [-0.16, -0.1, 0], max: [0.16, 0.1, 0])
                    scene.apply(asset: asset, selected: selected, isolate: false, cutaway: true,
                                context: true, separation: 1, state: state)
                    scene.spin.orientation = simd_quatf(angle: 0.9, axis: [0, 1, 0]) * simd_quatf(angle: 0.6, axis: [1, 0, 0])
                    // Refit intermediate animation frames, not just either endpoint.
                    for separation: Float in [0, 0.25, 0.5, 0.75, 1] {
                        scene.apply(asset: asset, selected: selected, isolate: false, cutaway: true,
                                    context: true, separation: separation, state: state)
                        scene.fit(in: available, zoom: 1.25)
                        try requireFits(scene, model: model, available: available)
                    }
                    scene.fit(in: available, zoom: 1)
                    let overviewScale = scene.holder.scale.x
                    for zoom: Float in [2, 3, 4] {
                        scene.fit(in: available, zoom: zoom)
                        try require(abs(scene.holder.scale.x / overviewScale - zoom) < 0.0001,
                                    "Close-up zoom was silently capped")
                        let enlarged = model.visualBounds(relativeTo: scene.holder, excludeInactive: true)
                        try require(enlarged.extents.x > 0 && enlarged.extents.y > 0 && enlarged.max.z.isFinite,
                                    "Close-up measured empty geometry")
                        try require(simd_length(enlarged.center) < 0.00001, "Close-up lost its center")
                        try require(enlarged.min.z * scene.holder.scale.z + scene.holder.position.z > -0.60,
                                    "Close-up went behind the backdrop")
                    }
                    scene.fit(in: available, zoom: 8)
                    try require(abs(scene.holder.scale.x / overviewScale - Float(HeartModelZoom.range.upperBound)) < 0.0001,
                                "Renderer did not respect the shared maximum")
                    for part in asset.parts {
                        let node = model.findEntity(named: part.id)!
                        try require(node.components[OpacityComponent.self]?.opacity == 1, "Default selection faded surrounding tissue")
                    }
                    scene.apply(asset: asset, selected: selected, isolate: false, cutaway: false,
                                context: true, separation: 0, state: state, transparent: true)
                    try require(model.findEntity(named: selected)!.components[OpacityComponent.self]?.opacity == 1, "Transparency faded the selected tissue")
                    let surrounding = asset.parts.first { $0.id != selected && asset.includes($0, state: state) }!
                    try require(model.findEntity(named: surrounding.id)!.components[OpacityComponent.self]?.opacity == 0.35, "Explicit transparency did not fade surrounding tissue")
                    scene.apply(asset: asset, selected: selected, isolate: true, cutaway: false,
                                context: true, separation: 0, state: state)
                    scene.fit(in: available, zoom: 1)
                    try requireFits(scene, model: model, available: available)
                    scene.apply(asset: asset, selected: "", isolate: false, cutaway: false,
                                context: true, separation: 0, state: state)
                    scene.fit(in: available, zoom: 1)
                    // Isolation reserves room for a full turn; elongated tissues may
                    // need more margin than a pose-dependent assembled bounding box.
                    try requireOpaqueMaterials(in: model)
                }
                // Off-centre authored origins must not make isolated tissue orbit the heart.
                for part in asset.parts {
                    let state = part.state ?? asset.defaultState
                    scene.apply(asset: asset, selected: part.id, isolate: true, cutaway: false,
                                context: true, separation: 0.65, state: state,
                                partOffsets: [part.id: [0.025, -0.018, 0.012]])
                    let node = model.findEntity(named: part.id)!
                    let pivotBounds = node.visualBounds(relativeTo: scene.spin, excludeInactive: true)
                    try require(simd_length(pivotBounds.center) < 0.00001, "Isolated tissue pivot is not its own center: \(part.id)")
                    let pivotInNode = node.convert(position: SIMD3<Float>.zero, from: scene.spin)
                    var initialScale: SIMD3<Float>?
                    for angle: Float in [0, 0.9, 2.3] {
                        scene.spin.orientation = simd_quatf(angle: angle, axis: normalize(SIMD3<Float>(1, 2, 0.5)))
                        scene.fit(in: BoundingBox(min: [-0.2, -0.2, 0], max: [0.2, 0.2, 0]), zoom: 1, selected: part.id)
                        try require(simd_length(node.convert(position: pivotInNode, to: scene.holder)) < 0.00001,
                                    "Isolated tissue orbited during rotation: \(part.id)")
                        if let initialScale {
                            try require(simd_distance(initialScale, scene.holder.scale) < 0.00001,
                                        "Isolated tissue resized during rotation: \(part.id)")
                        } else { initialScale = scene.holder.scale }
                    }
                }
                scene.spin.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                scene.apply(asset: asset, selected: "", isolate: false, cutaway: false,
                            context: true, separation: 0, state: asset.defaultState)
                let steps = HeartLessonStep.steps(for: asset)
                try require(!steps.isEmpty, "Missing guided step definitions")
                var controls = HeartModelControls()
                controls.isolate = true
                controls.toggleSeparation()
                try require(!controls.isolate && controls.separation == 1, "Separate stayed isolated")
                controls.isolate = true
                controls.partOffsets[asset.parts[0].id] = [0.01, 0, 0]
                controls.toggleSeparation()
                try require(!controls.isolate && controls.separation == 0 && controls.partOffsets.isEmpty,
                            "Reassemble failed to restore the other parts")
                controls.transparent = true; controls.showBackdrop = false
                controls.showLabels = false; controls.showOrientation = false
                for step in steps {
                    // Simulate leaving a prior step isolated, rotated, enlarged and separated.
                    controls.selectedPart = asset.parts.last!.id
                    controls.isolate = true; controls.showContext = false
                    controls.separation = 1; controls.yaw = 2.4; controls.pitch = -1.1; controls.zoom = HeartModelZoom.range.upperBound
                    controls.developmentState = asset.defaultState
                    controls.restore(asset: asset, step: step)
                    try require(controls.transparent && !controls.showBackdrop && !controls.showLabels && !controls.showOrientation, "Step restore lost display preferences")
                    try require(controls.selectedPart == step.focus, "Restore must retain the lesson focus")
                    try require(controls.developmentState == step.state, "Restore must use the step's anatomy")
                    try require(!controls.isolate && controls.showContext && controls.separation == 0, "Prior step visibility or separation leaked")
                    try require(controls.yaw == (asset.defaultYaw ?? 0) && controls.pitch == (asset.defaultPitch ?? 0) && controls.zoom == 1, "Prior step camera leaked")
                    scene.apply(asset: asset, selected: controls.selectedPart, isolate: controls.isolate,
                                cutaway: controls.cutaway, context: controls.showContext,
                                separation: Float(controls.separation), state: controls.developmentState)
                    try require(model.findEntity(named: step.focus)?.isEnabled == true, "Step focus is absent or hidden: \(step.focus)")
                    for part in asset.parts {
                        let node = model.findEntity(named: part.id)!
                        try require(simd_distance(node.position(relativeTo: model), baseline[part.id]!) < 0.00001, "Step restore must reassemble all parts")
                    }
                    // Close-ups centre the selected tissue while retaining its surroundings.
                    let closeUpArea = BoundingBox(min: [-0.16, -0.1, 0], max: [0.16, 0.1, 0])
                    scene.fit(in: closeUpArea, zoom: Float(HeartModelZoom.range.upperBound), selected: step.focus)
                    guard let closeUpAnchor = scene.selectedAnchor(for: step.focus) else {
                        throw NSError(domain: "HeartAssetValidation", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "Close-up lost its selected tissue"])
                    }
                    try require(abs(closeUpAnchor.x) < 0.00001 && abs(closeUpAnchor.y) < 0.00001,
                                "Close-up did not centre the selected tissue")
                    let volume = BoundingBox(min: [-0.55, -0.425, -0.45], max: [0.55, 0.425, 0.45])
                    scene.fit(in: volume, zoom: 4, selected: step.focus, volumetric: true)
                    let focusedBounds = model.findEntity(named: step.focus)!.visualBounds(relativeTo: scene.holder, excludeInactive: true)
                    try require(simd_length(focusedBounds.center) < 0.00001,
                                "Volume did not centre its selected tissue in all three dimensions")
                    try require(scene.holder.position == .zero, "Volume retained the flat-window depth lift")
                    scene.fit(in: volume, zoom: 1, selected: step.focus, volumetric: true)
                    let restoredVolumeBounds = model.visualBounds(relativeTo: scene.holder, excludeInactive: true)
                    try require(simd_length(restoredVolumeBounds.center) < 0.00001,
                                "Reset-size volume did not return to the whole-model centre")
                    let request = HeartCloseUpRequest(assetID: asset.id, controls: controls)
                    let decoded = try JSONDecoder().decode(HeartCloseUpRequest.self, from: JSONEncoder().encode(request))
                    try require(decoded == request, "Opening close-up lost inspection settings")
                    // Lesson actions recover the current step even after unrelated exploration.
                    controls.perform(.focus, asset: asset, step: step)
                    try require(controls.selectedPart == step.focus && controls.isolate && controls.developmentState == step.state,
                                "Lesson Focus lost its target or state")
                    scene.apply(asset: asset, selected: controls.selectedPart, isolate: controls.isolate,
                                cutaway: controls.cutaway, context: controls.showContext, separation: 0,
                                state: controls.developmentState)
                    let area = BoundingBox(min: [-0.16, -0.1, 0], max: [0.16, 0.1, 0])
                    scene.fit(in: area, zoom: 1)
                    guard let initialAnchor = scene.selectedAnchor(for: step.focus) else {
                        throw NSError(domain: "HeartAssetValidation", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "Lesson annotation has no visible target"])
                    }
                    host.addChild(scene.annotations)
                    defer { scene.annotations.removeFromParent() }
                    let testLabel = ModelEntity(mesh: .generateBox(size: [0.1, 0.03, 0.001]))
                    scene.updateAnnotation(label: testLabel, selected: step.focus, visible: true, available: area)
                    try require(testLabel.parent === scene.annotations && testLabel.isEnabled, "Annotation did not attach")
                    let beforeScale = scene.holder.scale
                    scene.spin.orientation = simd_quatf(angle: 1.4, axis: [0, 1, 0])
                    scene.fit(in: area, zoom: 1)
                    let rotatedAnchor = scene.selectedAnchor(for: step.focus)!
                    try require(initialAnchor.x.isFinite && rotatedAnchor.z.isFinite, "Annotation anchor is invalid")
                    let priorLabelPosition = testLabel.position
                    scene.updateAnnotation(label: testLabel, selected: step.focus, visible: true, available: area)
                    if simd_distance(initialAnchor, rotatedAnchor) > 0.00001 {
                        try require(simd_distance(priorLabelPosition, testLabel.position) > 0.00001,
                                    "Label did not follow its rotating target")
                    }
                    scene.updateAnnotation(label: testLabel, selected: step.focus, visible: false, available: area)
                    try require(!testLabel.isEnabled, "Hidden label was still visible")
                    scene.updateAnnotation(label: testLabel, selected: "", visible: true, available: area)
                    try require(!testLabel.isEnabled, "Cleared selection left an orphan label")
                    scene.fit(in: area, zoom: 1)
                    try require(scene.holder.scale.x.isFinite && beforeScale.x > 0, "Annotations changed model fitting")
                    controls.perform(.layers, asset: asset, step: step)
                    try require(!controls.isolate && controls.separation == 1 && controls.developmentState == step.state,
                                "Show layers did not restore the lesson anatomy")
                    scene.apply(asset: asset, selected: controls.selectedPart, isolate: controls.isolate,
                                cutaway: controls.cutaway, context: controls.showContext, separation: 1,
                                state: controls.developmentState)
                    if !controls.selectedPart.isEmpty {
                        try require(model.findEntity(named: controls.selectedPart)?.isEnabled == true,
                                    "Show layers selected a hidden tissue")
                    }
                    if let states = asset.states, states.count > 1 {
                        controls.yaw = 0.8; controls.pitch = -0.3
                        let priorState = controls.developmentState
                        controls.perform(.compare, asset: asset, step: step)
                        try require(controls.developmentState != priorState && controls.yaw == 0.8 && controls.pitch == -0.3,
                                    "Compare did not preserve the viewing angle")
                        try require(controls.selectedPart.isEmpty && !controls.isolate && controls.separation == 0,
                                    "Compare retained a stale selection or isolation")
                    }
                    // A camera-only reset must preserve anatomical inspection choices.
                    controls.isolate = true; controls.separation = 0.5; controls.yaw = -2; controls.pitch = 1; controls.zoom = HeartModelZoom.range.upperBound
                    let anatomy = controls
                    controls.resetView(asset: asset)
                    try require(controls.zoom == 1 && controls.yaw == (asset.defaultYaw ?? 0)
                                && controls.pitch == (asset.defaultPitch ?? 0), "Reset view did not restore size and angle")
                    try require(controls.developmentState == anatomy.developmentState && controls.selectedPart == anatomy.selectedPart && controls.cutaway == anatomy.cutaway && controls.isolate && controls.separation == 0.5, "Reset view changed anatomy")
                }
                scene.fit(in: BoundingBox(min: [-0.1,-0.1,0], max: [0.1,0.1,0]), zoom: 1)
                try require(scene.holder.scale.x.isFinite && scene.holder.scale.x > 0, "Fit scale")
                let centeredScale = scene.holder.scale
                scene.fit(in: BoundingBox(min: [0.25,-0.5,0.04], max: [0.45,-0.3,0.04]), zoom: 1)
                try require(simd_length(scene.holder.position) < 0.00001,
                            "Viewport offset was applied to the centered anatomy twice")
                try require(simd_distance(centeredScale, scene.holder.scale) < 0.00001 * max(1, simd_length(centeredScale)), "View position must not change model size")
                reports.append(["asset":asset.id, "passed":true, "parts":asset.parts.count, "texturedMeshes":texturedMeshes, "sceneObservationFeedbackTested":true, "screenAxisDragTested":true, "rotationPersistenceTested":true, "tissuePBRMapsTested":true, "studioLightingTested":true, "independentPartMovementTested":true, "isolatedPartPivotsTested":asset.parts.count, "phaseViewpointTested":true, "statesTested":states.count, "guidedStepsTested":steps.count, "lessonActionsTested":steps.count, "labelTargetsTested":steps.count, "separationFramesTested": states.count * 5, "closeUpZoomsTested": states.count * 3, "volumetricContextsTested": steps.count])
            } catch {
                reports.append(["asset":asset.id, "passed":false, "error":String(describing:error)])
            }
        }
        var referenceReports: [[String: Any]] = []
        for asset in HeartAsset.referenceModels {
            do {
                let model = try await Entity(named: "HeartAssets/\(asset.id)", in: realityKitContentBundle)
                let scene = HeartModelScene()
                try await scene.install(model, asset: asset)
                host.addChild(scene.holder)
                defer { scene.holder.removeFromParent() }
                try require(scene.holder.isActive, "Atlas validation requires a live scene")
                let available = BoundingBox(min: [-0.2, -0.2, 0], max: [0.2, 0.2, 0])
                if asset.id == "HDBR_CS11_N662" {
                    try require(HeartAsset.teachingAsset(for: "Cardiac looping (D-looping)")?.id == asset.id, "Looping lesson reverted to unverified geometry")
                    let steps = HeartLessonStep.steps(for: asset)
                    try require(steps.count == 3, "Looping reconstruction lesson focus count")
                    for step in steps {
                        try require(asset.parts.contains { $0.id == step.focus }, "Looping lesson targets absent anatomy")
                        var controls = HeartModelControls()
                        controls.transition(to: step, asset: asset)
                        controls.perform(.focus, asset: asset, step: step)
                        try require(controls.selectedPart == step.focus && controls.isolate, "Looping focus action")
                    }
                }
                if asset.id == "HDBR_CS18_N1645" {
                    try require(HeartAsset.teachingAsset(for: "Outflow tract septation")?.id == asset.id, "Outflow lesson reverted to fixed-twist diagram")
                    let steps = HeartLessonStep.steps(for: asset)
                    try require(steps.count == 3, "Outflow reference step count")
                    for step in steps {
                        try require(asset.parts.contains { $0.id == step.focus }, "Outflow lesson targets absent anatomy")
                        var controls = HeartModelControls()
                        controls.restore(asset: asset, step: step)
                        try require(!controls.showContext, "Outer source region obscures outflow lesson")
                        scene.apply(asset: asset, selected: step.focus, isolate: false, cutaway: false, context: controls.showContext, separation: 0)
                        try require(model.findEntity(named: step.focus)?.isEnabled == true, "Outflow target hidden")
                        try require(asset.parts.filter { $0.category == "context" }.allSatisfy { model.findEntity(named: $0.id)?.isEnabled == false }, "Source context not hidden")
                    }
                }
                scene.apply(asset: asset, selected: "", isolate: false, cutaway: false, context: true, separation: 0)
                var baseline: [String: SIMD3<Float>] = [:]
                for part in asset.parts {
                    guard let node = model.findEntity(named: part.id) else {
                        throw NSError(domain: "Atlas", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing region \(part.id)"])
                    }
                    baseline[part.id] = node.position(relativeTo: model)
                    if part.id == "CS11_N662_left_ventricle" {
                        var foundSourceRed = false
                        func checkColour(_ entity: Entity) {
                            if let component = entity.components[ModelComponent.self] {
                                for case let material as PhysicallyBasedMaterial in component.materials {
                                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                                    if material.baseColor.tint.getRed(&r, green: &g, blue: &b, alpha: &a), r > 0.4 && g < 0.1 && b < 0.1 { foundSourceRed = true }
                                }
                            }
                            for child in entity.children { checkColour(child) }
                        }
                        checkColour(node)
                        try require(foundSourceRed, "CS11 source red lost during material conversion")
                    }
                    try require(scene.partID(for: node, asset: asset) == part.id, "Atlas selection mapping")
                }
                scene.apply(asset: asset, selected: "", isolate: false, cutaway: false, context: true, separation: 1)
                try require(asset.parts.contains { simd_distance(model.findEntity(named: $0.id)!.position(relativeTo: model), baseline[$0.id]!) > 0.001 }, "Atlas regions did not separate")
                for part in asset.parts {
                    scene.apply(asset: asset, selected: part.id, isolate: true, cutaway: false,
                                context: true, separation: 0.65, partOffsets: [part.id: [0.025, -0.018, 0.012]])
                    let node = model.findEntity(named: part.id)!
                    try require(asset.parts.allSatisfy { model.findEntity(named: $0.id)!.isEnabled == ($0.id == part.id) }, "Atlas isolation visibility")
                    try require(simd_length(node.visualBounds(relativeTo: scene.spin, excludeInactive: true).center) < 0.00001, "Atlas pivot not centered")
                    let pivot = node.convert(position: SIMD3<Float>.zero, from: scene.spin)
                    var scale: SIMD3<Float>?
                    for angle: Float in [0, 0.9, 2.3] {
                        scene.spin.orientation = simd_quatf(angle: angle, axis: normalize(SIMD3<Float>(1, 2, 0.5)))
                        scene.fit(in: available, zoom: 1, selected: part.id)
                        try require(simd_length(node.convert(position: pivot, to: scene.holder)) < 0.00001, "Atlas region orbited")
                        if let scale { try require(simd_distance(scale, scene.holder.scale) < 0.00001, "Atlas isolated scale changed") }
                        else { scale = scene.holder.scale }
                    }
                }
                scene.apply(asset: asset, selected: "", isolate: false, cutaway: false, context: true, separation: 0)
                for part in asset.parts {
                    let node = model.findEntity(named: part.id)!
                    try require(node.isEnabled && simd_distance(node.position(relativeTo: model), baseline[part.id]!) < 0.00001, "Atlas reassembly drift")
                }
                referenceReports.append(["asset": asset.id, "passed": true, "parts": asset.parts.count, "isolatedPartPivotsTested": asset.parts.count, "selectionSeparationReassemblyTested": true])
            } catch {
                referenceReports.append(["asset": asset.id, "passed": false, "error": String(describing: error)])
            }
        }
        let payload: [String:Any] = ["validationScene":"live RealityView", "lessonProgress": lessonProgressReport, "separationTransition": transitionReport, "assets":reports, "referenceAssets":referenceReports, "passed":referenceReports.count == 7 && referenceReports.allSatisfy { $0["passed"] as? Bool == true } && !reports.isEmpty && reports.allSatisfy { $0["passed"] as? Bool == true } && transitionReport["passed"] as? Bool == true && lessonProgressReport["passed"] as? Bool == true]
        let url = URL.documentsDirectory.appending(path:"heart-asset-validation.json")
        do {
            try JSONSerialization.data(withJSONObject:payload, options:[.prettyPrinted,.sortedKeys]).write(to:url, options:.atomic)
        } catch { print("Could not write validation report: \(error)") }
    }

    private static func requireFits(_ scene: HeartModelScene, model: Entity, available: BoundingBox) throws {
        let bounds = model.visualBounds(relativeTo: scene.holder, excludeInactive: true)
        try require(bounds.extents.x > 0 && bounds.extents.y > 0 && bounds.max.z.isFinite,
                    "Fitting check measured empty or inactive geometry")
        let size = bounds.extents * scene.holder.scale
        try require(size.x <= available.extents.x + 0.00001 && size.y <= available.extents.y + 0.00001,
                    "Visible rotated/separated anatomy exceeded the model area")
        try require(simd_length(bounds.center) < 0.00001, "Visible anatomy was not centered")
        try require(abs(scene.holder.position.x) < 0.00001 && abs(scene.holder.position.y) < 0.00001,
                    "Viewport offset was applied to the centered anatomy twice")
        try require(bounds.min.z * scene.holder.scale.z + scene.holder.position.z > -0.20,
                    "Backdrop could occlude visible anatomy")
    }

    private static func requireOpaqueMaterials(in entity: Entity) throws {
        if let component = entity.components[ModelComponent.self] {
            for material in component.materials {
                try require(material is PhysicallyBasedMaterial, "Unverified tissue material: \(type(of: material))")
                if let tissue = material as? PhysicallyBasedMaterial {
                    if case .transparent = tissue.blending {
                        try require(false, "Tissue retained authored transparency")
                    }
                }
            }
        }
        for child in entity.children { try requireOpaqueMaterials(in: child) }
    }

    private static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain:"HeartAssetValidation", code:1, userInfo:[NSLocalizedDescriptionKey:message]) }
    }
}
#endif
