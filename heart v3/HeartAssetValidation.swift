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

    static func runTransitions(in host: Entity) async {
        var report: [String: Any] = [:]
        do {
            var motionSamples: [Double] = []
            await HeartMorphTiming.animate(duration: 0.08) { motionSamples.append($0) }
            try require(motionSamples.count >= 2 && motionSamples.last == 1 &&
                        zip(motionSamples, motionSamples.dropFirst()).allSatisfy { $0 <= $1 },
                        "Elapsed-time specimen animation did not finish monotonically")
            var cancelledSamples = 0
            let cancelledMotion = Task { @MainActor in
                await HeartMorphTiming.animate(duration: 1) { _ in cancelledSamples += 1 }
            }
            try await Task.sleep(for: .milliseconds(40))
            cancelledMotion.cancel(); await cancelledMotion.value
            let stoppedCount = cancelledSamples
            try await Task.sleep(for: .milliseconds(40))
            try require(stoppedCount > 0 && cancelledSamples == stoppedCount,
                        "Cancelled specimen animation continued writing frames")
            let normal = HeartProjectModel.all.first { $0.id == "Normal_Teenage_Heart" }!
            let neonatal = HeartProjectModel.all.first { $0.id == "Normal_Neonatal_Heart" }!
            let vsd = HeartProjectModel.all.first { $0.id == "Ventricular_Septal_Defect" }!
            let presentation = HeartSpecimenPresentation { scene, model in
                if model.id == neonatal.id { try? await Task.sleep(for: .milliseconds(150)) }
                guard !Task.isCancelled else { return }
                await scene.load(model.id, uniformTissue: model.usesUniformTissueColor)
            }
            host.addChild(presentation.root)
            defer { presentation.cancel(); presentation.root.removeFromParent() }
            let inspectionRotation = HeartManipulationSession.rotated(
                from: simd_quatf(angle: 0.4, axis: [0, 1, 0]), horizontal: 70, vertical: 320)
            presentation.fit(BoundingBox(min: [-0.3, -0.3, 0], max: [0.3, 0.3, 0]), zoom: 1.3, yaw: 0.4, pitch: 0.2,
                             inspectionRotation: inspectionRotation)
            await presentation.present(normal, reducedMotion: true)
            try require(presentation.displayedID == normal.id && presentation.root.children.count == 1, "Initial specimen did not install exactly once")
            try require(simd_length(presentation.scene.spin.orientation.vector - inspectionRotation.vector) < 0.00001,
                        "Initial specimen ignored its shared inspection rotation")
            let original = presentation.scene
            try await validateSpecimenRecovery(original)
            let stale = Task { @MainActor in await presentation.present(neonatal, reducedMotion: false) }
            try? await Task.sleep(for: .milliseconds(25))
            try require(presentation.loading && presentation.scene === original && original.root.parent === presentation.root,
                        "Loading replacement removed displayed anatomy")
            // Deliberately leave this load running: the request token, rather
            // than cooperative task cancellation, must reject its result.
            await presentation.present(vsd, reducedMotion: false)
            await stale.value
            try require(presentation.displayedID == vsd.id && !presentation.loading && !presentation.failed,
                        "Stale load replaced the latest specimen")
            try require(presentation.root.children.count == 1 && original.root.parent == nil,
                        "Specimen transition left duplicate or orphaned anatomy")
            try require(presentation.scene.spin.components[OpacityComponent.self]?.opacity == 1, "Transition left a partially transparent model")
            try require(simd_length(presentation.scene.spin.orientation.vector - inspectionRotation.vector) < 0.00001,
                        "Specimen replacement lost its inspection rotation")
            try await validateSpecimenRecovery(presentation.scene)
            let missing = HeartProjectModel(id: "Missing_Validation_Specimen", title: "Missing", note: "", url: "", license: "")
            let retained = presentation.scene
            await presentation.present(missing, reducedMotion: true)
            try require(presentation.failed && presentation.scene === retained && presentation.displayedID == vsd.id,
                        "Failed replacement discarded the displayed specimen")
            await presentation.present(normal, reducedMotion: true)
            try require(!presentation.failed && presentation.displayedID == normal.id && presentation.root.children.count == 1,
                        "Model selection did not recover after a loading failure")
            let abandoned = Task { @MainActor in await presentation.present(neonatal, reducedMotion: false) }
            try? await Task.sleep(for: .milliseconds(25))
            presentation.cancel(); abandoned.cancel(); await abandoned.value
            try require(!presentation.loading && presentation.displayedID == normal.id && presentation.root.children.count == 1,
                        "Navigation cancellation installed stale geometry")
            let cache = HeartMorphMeshCache()
            var samples = 0
            for outflow in [false, true] {
                for cutaway in [false, true] {
                    for progress in (outflow ? [0, 0.5, 1, 0.5] : [-1, -0.5, 0, 0.5, 1, 0.5, -0.5]) {
                        _ = try cache.resource(progress: progress, cutaway: cutaway, outflow: outflow)
                        let positions = outflow ? HeartOutflowGeometry.surface(progress: progress, cutaway: cutaway).positions
                            : progress < 0 ? HeartTubeFusionGeometry.surface(progress: progress + 1).positions
                            : HeartLoopingGeometry.surface(progress: progress, cutaway: cutaway).positions
                        let bounds = cache.surfaceBounds
                        for point in positions {
                            try require(point.x >= bounds.min.x - 0.00001 && point.x <= bounds.max.x + 0.00001 &&
                                        point.y >= bounds.min.y - 0.00001 && point.y <= bounds.max.y + 0.00001 &&
                                        point.z >= bounds.min.z - 0.00001 && point.z <= bounds.max.z + 0.00001,
                                        "Cached morph envelope lost a surface point")
                        }
                        for zoom in [0.4, 1, 2.5] {
                            for rotation in [(0.0, 0.0), (1.4, -1.3), (-2.0, 1.3)] {
                                let placement = cache.placement(in: BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0]),
                                    zoom: zoom, yaw: rotation.0, pitch: rotation.1, outflow: outflow,
                                    inspectionRotation: HeartManipulationSession.rotated(from: inspectionRotation,
                                        horizontal: Float(rotation.0 * 200), vertical: Float(rotation.1 * 200)))
                                for point in positions {
                                    let placed = placement.matrix * SIMD4(point, 1)
                                    try require(placed.z > 0 && placed.z <= 0.501, "Morph escaped the visible workspace depth")
                                }
                            }
                        }
                        samples += 1
                    }
                }
            }
            var wallFrames = 0
            for outflow in [false, true] {
                let partial = try cache.resource(progress: 0.4, opening: 0.5, outflow: outflow)
                for opening in [0.1, 0.6, 0.99, 0.99995, Double(Float(1).nextDown), Double(1).nextDown, 1.0, 0.7, 0.2, 0.0, 0.5] {
                    let resource = try cache.resource(progress: 0.4, opening: opening, outflow: outflow)
                    let effectiveOpening = outflow ? HeartOutflowGeometry.inspectionOpening(opening) : Float(opening)
                    if effectiveOpening > 0 && effectiveOpening < 1 { try require(resource === partial, "Partial wall cut rebuilt its GPU resource") }
                    let expected = outflow ? HeartOutflowGeometry.surface(progress: 0.4, opening: opening).positions
                        : HeartLoopingGeometry.surface(progress: 0.4, opening: opening).positions
                    var matches = true
                    resource.lowLevelMesh?.withUnsafeBytes(bufferIndex: 0) { bytes in
                        let vertices = bytes.bindMemory(to: SIMD3<Float>.self)
                        matches = vertices.count >= expected.count && expected.indices.allSatisfy { simd_distance(vertices[$0], expected[$0]) < 0.000001 }
                    }
                    try require(resource.lowLevelMesh != nil && matches, "Wall reversal lost the expected surface")
                    let placement = cache.placement(in: BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0]), zoom: 2.5, yaw: 1.4, pitch: -1.3, outflow: outflow)
                    try require(expected.allSatisfy { (placement.matrix * SIMD4($0, 1)).z > 0 && (placement.matrix * SIMD4($0, 1)).z <= 0.501 }, "Partial wall escaped visible workspace depth")
                    wallFrames += 1
                }
            }
            // The same cancellable fraction driver is used by the wall view.
            let wall = HeartSeparationPresentation()
            let opening = Task { @MainActor in await wall.update(to: 1, animated: true) }
            try? await Task.sleep(for: .milliseconds(90))
            opening.cancel(); await opening.value
            let interrupted = wall.value
            try require(interrupted > 0 && interrupted < 1, "Wall animation did not expose an intermediate state")
            var previous = interrupted
            var reversedContinuously = true
            await wall.update(to: 0, animated: true) { value in
                if value > previous + 0.000001 { reversedContinuously = false }
                previous = value
            }
            try require(reversedContinuously && wall.value == 0, "Reversing the wall jumped or stopped short")
            await wall.update(to: 1, animated: false)
            try require(wall.value == 1, "Reduced-motion wall did not reach its endpoint")
            var layerFrames = 0
            var isolatedLayerFrames = 0
            let layerMoves: [Int: SIMD3<Float>] = [0: [1, 0, 0], 1: [0, -1, 0], 2: [0, 0, 1]]
            for progress in [-0.8, -0.01, 0.0, 0.4, 1, 0.4, -0.8] {
                for separation in [0.0, 0.5, 1] {
                    let resource = try cache.resource(progress: progress, opening: 1, outflow: false, layers: true, separation: separation, offsets: layerMoves)
                    let expected = HeartTubeLayerGeometry.surface(progress: progress, opening: 1, separation: separation, offsets: layerMoves)
                    guard let mesh = resource.lowLevelMesh else { throw CocoaError(.coderReadCorrupt) }
                    var matches = true
                    mesh.withUnsafeBytes(bufferIndex: 0) { bytes in
                        let vertices = bytes.bindMemory(to: SIMD3<Float>.self)
                        matches = vertices.count >= expected.positions.count && expected.positions.indices.allSatisfy {
                            simd_distance(vertices[$0], expected.positions[$0]) < 0.000001
                        }
                    }
                    try require(matches, "Layer GPU buffers did not follow development/separation")
                    try require(expected.positions.allSatisfy { simd_reduce_max(simd_abs($0)) < 0.30 }, "Moved layer escaped its drawing bounds")
                    try require(mesh.parts.allSatisfy { $0.materialIndex < 18 }, "Layer GPU material mapping escaped its palette")
                    let fit = cache.placement(in: BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0]), zoom: 2.5, yaw: 1.1, pitch: 0.6, outflow: false)
                    try require(expected.positions.allSatisfy { (fit.matrix * SIMD4($0, 1)).z > 0 && (fit.matrix * SIMD4($0, 1)).z <= 0.501 }, "Separated tissue escaped visible workspace depth")
                    let deformations = cache.layerDeformationBuildCount
                    for layer in HeartTubeLayer.allCases {
                        let isolated = try cache.resource(progress: progress, opening: 1, outflow: false, layers: true,
                            separation: separation, offsets: layerMoves, visibleLayer: layer)
                        try require(isolated === resource, "Isolating a layer rebuilt its GPU mesh")
                        try require(!mesh.parts.isEmpty && mesh.parts.allSatisfy {
                            $0.materialIndex / HeartAnatomyRegion.allCases.count == layer.rawValue
                        }, "Layer isolation retained hidden draw parts")
                        let isolatedFit = cache.placement(in: BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0]),
                            zoom: 2.5, yaw: 1.1, pitch: 0.6, outflow: false)
                        try require(isolatedFit == fit, "Layer isolation changed viewing placement")
                        isolatedLayerFrames += 1
                    }
                    let returned = try cache.resource(progress: progress, opening: 1, outflow: false, layers: true, separation: 0)
                    try require(returned === resource, "Reassembling layers rebuilt the GPU mesh")
                    try require(Set(mesh.parts.map { $0.materialIndex / HeartAnatomyRegion.allCases.count }) == Set(0...2),
                                "Showing all layers left a layer hidden")
                    try require(cache.layerDeformationBuildCount == deformations, "Translation-only layer inspection rebuilt developmental geometry")
                    layerFrames += 1
                }
            }
            let layerMotion = HeartLayerMovePresentation()
            let moving = Task { @MainActor in await layerMotion.update(to: layerMoves, animated: true) }
            try? await Task.sleep(for: .milliseconds(60))
            moving.cancel(); await moving.value
            try require((layerMotion.offsets[0]?.x ?? 0) > 0 && (layerMotion.offsets[0]?.x ?? 1) < 0.04, "Layer move skipped its intermediate positions")
            await layerMotion.update(to: [:], animated: false)
            try? await Task.sleep(for: .milliseconds(40))
            try require(layerMotion.offsets.isEmpty, "Cancelled layer move overrode reset")
            let appearance = HeartMorphAppearance()
            let styled = ModelEntity(mesh: try cache.resource(progress: 0.4, opening: 0, outflow: false, layers: true), materials: [])
            var paletteChecks = 0
            for progress in [-0.8, 0, 0.09, 0.18, 0.7, 1, 0.09, -0.2] {
                appearance.apply(to: styled, progress: progress, outflow: false)
                let revision = appearance.revision
                appearance.apply(to: styled, progress: progress, outflow: false)
                try require(appearance.revision == revision, "Unchanged morph appearance rebuilt its materials")
                guard let materials = styled.model?.materials, materials.count == 18 else {
                    throw CocoaError(.coderReadCorrupt)
                }
                for layer in HeartTubeLayer.allCases { for region in HeartAnatomyRegion.allCases {
                    guard let actual = materials[layer.rawValue * 6 + region.rawValue] as? PhysicallyBasedMaterial else {
                        throw CocoaError(.coderReadCorrupt)
                    }
                    let expected = HeartModelStyle.morphRegion(region, progress: progress, lightening: layer.lightening)
                    try require(actual.baseColor.tint.isEqual(expected.baseColor.tint) &&
                                actual.roughness.scale == expected.roughness.scale && actual.metallic.scale == expected.metallic.scale,
                                "Cached morph material changed the shared tissue style")
                    try require(actual.baseColor.texture != nil && actual.roughness.texture != nil,
                                "Morph surface finish missing from installed app")
                    paletteChecks += 1
                } }
            }
            appearance.apply(to: styled, progress: 0.18, outflow: false)
            let replacement = ModelEntity(mesh: styled.model!.mesh, materials: [])
            appearance.apply(to: replacement, progress: 0.4, outflow: false)
            try require(replacement.model?.materials.count == 18, "Recreated morph lost its cached tissue materials")
            replacement.model?.materials = []
            appearance.apply(to: replacement, progress: 0.4, outflow: false)
            try require(replacement.model?.materials.count == 18, "Reinstalled morph component stayed unstyled")
            appearance.apply(to: styled, progress: 0.4, outflow: false)
            let establishedPalette = appearance.revision
            for progress in [0.4, 0.8, 1, 0.3] { appearance.apply(to: styled, progress: progress, outflow: false) }
            try require(appearance.revision == establishedPalette, "Established regional palette rebuilt on every morph frame")
            appearance.apply(to: styled, progress: 0, outflow: true)
            let outflowPalette = appearance.revision
            for progress in [0.5, 1, 0.4] { appearance.apply(to: styled, progress: progress, outflow: true) }
            try require(appearance.revision == outflowPalette && styled.model?.materials.count == 2,
                        "Outflow palette rebuilt or retained tube-layer materials")
            var outflowInspectionFrames = 0
            for progress in [0.0, 0.4, 1] { for opening in [0.0, 0.5, 1] {
                let resource = try cache.resource(progress: progress, opening: opening, outflow: true, separation: 1)
                let expected = HeartOutflowGeometry.surface(progress: progress, opening: opening, separation: 1)
                var matches = false
                resource.lowLevelMesh?.withUnsafeBytes(bufferIndex: 0) { bytes in
                    let vertices = bytes.bindMemory(to: SIMD3<Float>.self)
                    matches = vertices.count >= expected.positions.count && expected.positions.indices.allSatisfy {
                        simd_distance(vertices[$0], expected.positions[$0]) < 0.000001
                    }
                }
                try require(matches, "Separated outflow GPU positions lost their authored shape")
                let fit = cache.placement(in: BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0]),
                    zoom: 2.5, yaw: 1.1, pitch: 0.6, outflow: true)
                try require(expected.positions.allSatisfy { (fit.matrix * SIMD4($0, 1)).z > 0 && (fit.matrix * SIMD4($0, 1)).z <= 0.501 },
                            "Separated outflow escaped visible workspace depth")
                let builds = cache.outflowDeformationBuildCount
                let restored = try cache.resource(progress: progress, opening: opening, outflow: true, separation: 0)
                try require(restored === resource && cache.outflowDeformationBuildCount == builds,
                            "Outflow reassembly rebuilt its developmental surface")
                outflowInspectionFrames += 1
            } }
            let ductal = HeartSpecimenPresentation()
            host.addChild(ductal.root)
            defer { ductal.cancel(); ductal.root.removeFromParent() }
            ductal.fit(BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0]), zoom: 1.3, yaw: -0.65, pitch: 0)
            for id in ["PDA_Patent", "PDA_Closed"] {
                let model = HeartProjectModel.all.first { $0.id == id }!
                await ductal.present(model, reducedMotion: true)
                try require(!ductal.failed && ductal.displayedID == id && ductal.scene.parts.count == 3, "Authored ductal model missing its three parts")
                for axis in [0, 1, 2] {
                    try await ductal.scene.prepareSection(axis)
                    try require(ductal.scene.sectionError == nil, "Authored ductal section failed")
                }
                try await validateSpecimenRecovery(ductal.scene)
            }
            try await ductal.scene.prepareSection(2)
            await ductal.present(HeartProjectModel.all.first { $0.id == "PDA_Patent" }!, reducedMotion: false)
            try require(ductal.scene.sectionAxis == 2, "Matched ductal comparison lost its cut plane")
            report = ["passed": true, "elapsedSpecimenAnimation": true, "cancelledSpecimenClock": true, "authoredDuctalModels": 2, "ductalSectionAxes": 3, "matchedDuctalSectionRetained": true, "retainedWhileLoading": true, "latestRequestWins": true, "singleInstalledRoot": true,
                      "failedLoadPreservesSource": true, "cancellation": true, "reducedMotion": true,
                      "specimenQuaternionRetained": true, "unrestrictedMorphInspectionPoses": samples * 9,
                      "morphEnvelopeFrames": samples, "morphVisibleDepthPoses": samples * 9,
                      "wallFrames": wallFrames, "wallReversal": reversedContinuously, "wallReducedMotion": true,
                      "independentSpecimenRecovery": true, "specimensRecoveryTested": 2,
                      "layerMorphFrames": layerFrames, "isolatedLayerFrames": isolatedLayerFrames,
                      "morphPaletteChecks": paletteChecks, "morphMaterialsReused": true, "recreatedMorphMaterialsRestored": true,
                      "outflowInspectionFrames": outflowInspectionFrames,
                      "boundedLayerMoves": true, "cancelledLayerMoveReset": true]
        } catch { report = ["passed": false, "error": String(describing: error)] }
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL.documentsDirectory.appending(path: "heart-transition-validation.json"), options: .atomic)
        }
    }

    private static func validateSpecimenRecovery(_ scene: HeartProjectScene) async throws {
        let parts = scene.parts
        let rest = parts.map { scene.spin.findEntity(named: $0.id)!.position(relativeTo: scene.spin) }
        try await scene.prepareSection(0)
        scene.separate(reduceMotion: true)
        let spread = parts.map { scene.spin.findEntity(named: $0.id)!.position(relativeTo: scene.spin) }
        for (index, part) in parts.enumerated() {
            scene.selectedPart = part.id
            scene.movePart([0.04, 0, 0], reduceMotion: true)
            scene.returnPart(reduceMotion: true)
            for (other, candidate) in parts.enumerated() {
                let expected = other <= index ? rest[other] : spread[other]
                try require(simd_distance(scene.spin.findEntity(named: candidate.id)!.position(relativeTo: scene.spin), expected) < 0.00001,
                            "Return part changed another component or failed to restore its own assembled position")
            }
            try require(scene.sectionAxis == 0, "Return part discarded the inspection section")
        }
        try require(!scene.separated && !scene.moved, "Returning every part left stale separation state")
        scene.separate(reduceMotion: true)
        try require(scene.separated, "Separate could not restart after individual returns")
        scene.returnPart(reduceMotion: false)
        try? await Task.sleep(for: .milliseconds(40))
        scene.separate(reduceMotion: true)
        try require(scene.sectionAxis == 0 && !scene.separated, "Reassemble changed the section")
        let frame = BoundingBox(min: [-0.3, -0.2, 0], max: [0.3, 0.2, 0])
        scene.fit(frame, zoom: 1.7, yaw: 0.8, pitch: -0.2)
        for zoom in [0.4, 1, 2.5] {
            for rotation in [(0.0, 0.0), (1.4, -1.3), (-2.0, 1.3)] {
                scene.fit(frame, zoom: zoom, yaw: rotation.0, pitch: rotation.1)
                let bounds = scene.root.visualBounds(relativeTo: scene.root.parent)
                try require(bounds.min.z > 0 && bounds.max.z <= 0.501,
                            "Specimen escaped visible workspace depth during rotation/resize")
            }
        }
        let scale = scene.root.scale, rotation = scene.spin.orientation
        scene.restore(reduceMotion: true)
        try? await Task.sleep(for: .milliseconds(50))
        try require(scene.sectionAxis == -1 && !scene.separated && !scene.moved, "Restore model retained inspection state")
        try require(scene.root.scale == scale && scene.spin.orientation == rotation, "Restore model changed viewing pose")
        for (index, part) in parts.enumerated() {
            try require(simd_distance(scene.spin.findEntity(named: part.id)!.position(relativeTo: scene.spin), rest[index]) < 0.00001,
                        "Cancelled return animation overrode model restoration")
        }
        try require(scene.sections.entries.allSatisfy { $0.entity.components[ModelComponent.self]?.mesh === $0.original.mesh },
                    "Restore model did not recover the original surfaces")
    }

    static func run(in host: Entity) async {
        guard !hasRun else { return }
        hasRun = true
        for _ in 0..<20 where !host.isActive {
            try? await Task.sleep(for: .milliseconds(100))
        }
        var morphReport: [String: Any]
        do {
            let cache = HeartMorphMeshCache()
            var verified = 0
            for outflow in [false, true] {
                for cutaway in [false, true] {
                    let initial = try cache.resource(progress: 0, cutaway: cutaway, outflow: outflow)
                    for progress in [0.4, 1.0, 0.6, 0.0] {
                        let resource = try cache.resource(progress: progress, cutaway: cutaway, outflow: outflow)
                        try require(resource === initial, "Morph rebuilt its mesh during progression")
                        guard let storage = resource.lowLevelMesh else {
                            try require(false, "Missing mutable morph mesh"); continue
                        }
                        let expected = outflow ? HeartOutflowGeometry.surface(progress: progress, cutaway: cutaway).positions
                            : HeartLoopingGeometry.surface(progress: progress, cutaway: cutaway).positions
                        var matches = true
                        storage.withUnsafeBytes(bufferIndex: 0) { bytes in
                            let vertices = bytes.bindMemory(to: SIMD3<Float>.self)
                            for i in expected.indices {
                                if simd_distance(vertices[i], expected[i]) > 0.000001 { matches = false }
                            }
                        }
                        try require(matches, "Morph vertex buffer did not follow forward/reverse progress")
                        try require(storage.parts.reduce(0) { $0 + $1.indexCount } == storage.indexCapacity,
                                    "Morph material grouping lost faces")
                        verified += 1
                    }
                }
            }
            let joining = try cache.resource(progress: -0.8, cutaway: false, outflow: false)
            _ = try cache.resource(progress: 0.4, cutaway: false, outflow: false)
            let returned = try cache.resource(progress: -0.1, cutaway: false, outflow: false)
            try require(joining === returned, "Returning to joining rebuilt its cached topology")
            morphReport = ["passed": true, "mutableMeshFramesTested": verified, "joiningTopologyReused": true]
        } catch {
            morphReport = ["passed": false, "error": String(describing: error)]
        }
        var specimenInteractionReports: [[String: Any]] = []
        for source in HeartProjectModel.all {
            writeProgress("specimen", asset: source.id)
            let scene = HeartProjectScene()
            host.addChild(scene.root)
            do {
                await scene.load(source.id, uniformTissue: source.usesUniformTissueColor)
                try require(scene.ready && !scene.failed, "Specimen failed to load")
                try require(!scene.parts.isEmpty && scene.sections.meshCount > 0, "Missing specimen parts or surfaces")
                let positions = scene.parts.map { scene.spin.findEntity(named: $0.id)!.position(relativeTo: scene.spin) }
                scene.setSection(2)
                try? await Task.sleep(for: .milliseconds(20))
                scene.restore(reduceMotion: true)
                try? await Task.sleep(for: .milliseconds(80))
                try require(scene.sectionAxis == -1 && !scene.preparingSection, "Cancelled section overrode Reset")
                for axis in [2, 0, 1, -1] {
                    try await scene.prepareSection(axis)
                    try require(scene.sectionError == nil, "Specimen section failed")
                    let visible = scene.sections.entries.filter { $0.entity.components[ModelComponent.self] != nil }
                    try require(!visible.isEmpty, "Section removed the entire specimen")
                    if axis == -1 {
                        try require(scene.sections.entries.allSatisfy { $0.entity.components[ModelComponent.self]?.mesh === $0.original.mesh }, "Section failed to restore source mesh identity")
                    }
                }
                scene.separate(reduceMotion: true)
                if scene.parts.count > 1 {
                    for (index, part) in scene.parts.enumerated() {
                        let delta = scene.spin.findEntity(named: part.id)!.position(relativeTo: scene.spin) - positions[index]
                        let expected = HeartSpecimenPart.separationDirection(model: source.id, part: part.id, index: index, count: scene.parts.count) * scene.diameter * 0.15
                        try require(simd_distance(delta, expected) < scene.diameter * 0.0001, "Source scale changed the visible separation distance")
                    }
                }
                scene.restore(reduceMotion: true)
                scene.movePart([10, -10, 10], reduceMotion: true)
                scene.fit(BoundingBox(min: [-0.3, -0.3, -0.3], max: [0.3, 0.3, 0.3]), zoom: 2.5, yaw: 1.2, pitch: 0.4)
                let movedBounds = scene.root.visualBounds(relativeTo: host)
                try require(movedBounds.min.z > 0 && movedBounds.max.z <= 0.501, "Moved specimen escaped visible workspace depth")
                scene.separate(reduceMotion: false)
                try? await Task.sleep(for: .milliseconds(45))
                scene.restore(reduceMotion: true)
                for (index, part) in scene.parts.enumerated() {
                    try require(simd_distance(scene.spin.findEntity(named: part.id)!.position(relativeTo: scene.spin), positions[index]) < 0.00001, "Interrupted specimen motion did not reassemble")
                }
                specimenInteractionReports.append(["asset": source.id, "passed": true, "sourceGroups": scene.parts.count, "sectionAxesTested": 3, "restoredOriginalMeshes": true, "movementAndReassembly": true, "cancelledSectionCannotOverrideReset": true])
            } catch {
                specimenInteractionReports.append(["asset": source.id, "passed": false, "error": String(describing: error)])
            }
            scene.stop(); scene.root.removeFromParent()
        }
        var guidedSpecimenReport: [String: Any]
        do {
            let lessons = HeartAsset.all.map(\.lesson)
            var mapped = 0
            for lesson in lessons {
                guard let study = HeartGuidedAnatomy.lesson(lesson) else { continue }
                for id in [study.normalID, study.alteredID].compactMap({ $0 }) {
                    try require(HeartProjectModel.all.contains { $0.id == id }, "Unknown guided specimen: \(id)")
                    try require(Bundle.main.url(forResource: id, withExtension: "usdz") != nil
                                || Bundle.main.url(forResource: id, withExtension: "usdz", subdirectory: "HeartProject") != nil,
                                "Missing bundled guided specimen: \(id)")
                }
                mapped += 1
            }
            try require(mapped == lessons.count, "A guided lesson is missing its bundled anatomy study")
            guidedSpecimenReport = ["passed": true, "lessonsWithBundledSpecimens": mapped]
        } catch {
            guidedSpecimenReport = ["passed": false, "error": String(describing: error)]
        }
        var lessonProgressReport: [String: Any]
        do {
            var progress = HeartLessonProgress()
            try require(progress.resumeStep(for: "Tubes", stepCount: 3) == 0, "New lesson did not start at its first step")
            var migrated = HeartLessonProgress()
            migrated.record(step: 1, for: HeartLearningPilot.cushionLesson, stepCount: 3)
            migrated.record(step: 0, for: HeartLearningPilot.coarctationLesson, stepCount: 4)
            migrated.finish("Unchanged")
            migrated.migrateLearningPilots()
            try require(migrated.resumeStep(for: HeartLearningPilot.cushionLesson, stepCount: 5) == 2
                        && migrated.resumeStep(for: HeartLearningPilot.coarctationLesson, stepCount: 5) == 1
                        && migrated.lessons["Unchanged"]?.completed == true, "Pilot migration lost saved progress")
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
            writeProgress("lesson", asset: asset.id)
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
                let styledMeshes = try validateRegionalPalette(model, asset: asset)
                if let states = asset.states, states.count > 1 {
                    var comparisonScale: SIMD3<Float>?
                    var comparisonCenter: SIMD3<Float>?
                    var comparisonDepth: SIMD3<Float>?
                    for state in states {
                        scene.apply(asset: asset, selected: "", isolate: false, cutaway: false,
                                    context: true, separation: 0, state: state.id)
                        scene.fit(in: workspace, zoom: 1.8)
                        if let scale = comparisonScale, let center = comparisonCenter, let depth = comparisonDepth {
                            try require(simd_distance(scale, scene.holder.scale) < 0.00001
                                        && simd_distance(center, scene.spin.position) < 0.00001
                                        && simd_distance(depth, scene.holder.position) < 0.00001,
                                        "Comparison changed model scale, centre or depth")
                        }
                        comparisonScale = scene.holder.scale
                        comparisonCenter = scene.spin.position
                        comparisonDepth = scene.holder.position
                    }
                    scene.apply(asset: asset, selected: "", isolate: false, cutaway: false,
                                context: true, separation: 0, state: asset.defaultState)
                    scene.fit(in: workspace, zoom: 1)
                }
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
                            "Snapshot lost the dragged orientation")
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
                var recovery = rotationControls
                recovery.isolate = true; recovery.separation = 1; recovery.partOffsets[movedID] = displacement
                recovery.zoom = 1.5; recovery.selectedPart = movedID
                let retainedState = recovery.developmentState ?? asset.defaultState
                recovery.resetModel(asset: asset)
                let recovered = recovery
                recovery.resetModel(asset: asset)
                try require(recovery == recovered && recovery.partOffsets.isEmpty && !recovery.isolate
                            && recovery.separation == 0 && recovery.selectedPart.isEmpty && recovery.zoom == 1
                            && recovery.developmentState == retainedState, "Full reset is not canonical / idempotent")
                var detached = HeartModelControls()
                detached.partOffsets[movedID] = displacement
                detached.moveParts = true
                let restored = try JSONDecoder().decode(HeartModelControls.self, from: JSONEncoder().encode(detached))
                try require(restored == detached, "Snapshot lost detached tissue positions")
                var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(detached)) as! [String: Any]
                legacy.removeValue(forKey: "movablePartsEnabled")
                legacy.removeValue(forKey: "detachedPartPositions")
                let legacyControls = try JSONDecoder().decode(HeartModelControls.self, from: JSONSerialization.data(withJSONObject: legacy))
                try require(!legacyControls.moveParts && legacyControls.partOffsets.isEmpty,
                            "Legacy viewing state failed to decode")
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
                        scene.fit(in: available, zoom: 1)
                        try requireFits(scene, model: model, available: available)
                    }
                    scene.fit(in: available, zoom: 1)
                    let baselineZoomScale = scene.holder.scale.x
                    for zoom: Float in [0.4, 1, 1.25, 1.5, 2.5, 4, 8, .infinity, .nan] {
                        scene.fit(in: available, zoom: zoom)
                        let zoomBounds = model.visualBounds(relativeTo: scene.holder, excludeInactive: !scene.usesMatchedComparison)
                        let expected = HeartViewportDepth.scale(baselineZoomScale * Float(HeartModelZoom.clamped(Double(zoom))), depth: scene.framingDiameter)
                        try require(abs(scene.holder.scale.x - expected) < 0.00001,
                                    "Renderer cancelled requested magnification")
                        try require(scene.holder.scale.x.isFinite, "Invalid rendered zoom")
                        try require(zoomBounds.min.z * scene.holder.scale.z + scene.holder.position.z > 0 &&
                                    zoomBounds.max.z * scene.holder.scale.z + scene.holder.position.z <= 0.501,
                                    "Zoomed anatomy escaped visible workspace depth")
                    }
                    scene.fit(in: available, zoom: 1)
                    try requireFits(scene, model: model, available: available)
                    for part in asset.parts {
                        let node = model.findEntity(named: part.id)!
                        // The birth-transition reading key intentionally dims other regions.
                        let expectedOpacity: Float = asset.id == "Heart_10_CirculatoryTransition" && part.id != selected ? 0.6 : 1
                        try require(node.components[OpacityComponent.self]?.opacity == expectedOpacity,
                                    "Selection opacity disagrees with the transition reading key")
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
                    if step.focus.isEmpty {
                        try require(controls.selectedPart.isEmpty && !controls.isolate,
                                    "Blind lesson step exposed a selected target")
                        try require(scene.selectedAnchor(for: "") == nil, "Blind step exposed a label anchor")
                        let pose = controls.orientation
                        let zoom = controls.zoom
                        controls.transition(to: step, asset: asset)
                        try require(controls.orientation == pose && controls.zoom == zoom,
                                    "Blind step lost the viewing context")
                        continue // Annotation assertions below require a deliberately named focus.
                    }
                    try require(model.findEntity(named: step.focus)?.isEnabled == true, "Step focus is absent or hidden: \(step.focus)")
                    for part in asset.parts {
                        let node = model.findEntity(named: part.id)!
                        try require(simd_distance(node.position(relativeTo: model), baseline[part.id]!) < 0.00001, "Step restore must reassemble all parts")
                    }
                    // In-place magnification retains a valid selected-tissue anchor.
                    let zoomArea = BoundingBox(min: [-0.16, -0.1, 0], max: [0.16, 0.1, 0])
                    scene.fit(in: zoomArea, zoom: Float(HeartModelZoom.range.upperBound), selected: step.focus)
                    guard let zoomAnchor = scene.selectedAnchor(for: step.focus) else {
                        throw NSError(domain: "HeartAssetValidation", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "Magnification lost its selected tissue"])
                    }
                    try require(zoomAnchor.x.isFinite && zoomAnchor.y.isFinite,
                                "Magnification lost its selected anchor")
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
                try require(simd_length(SIMD2<Float>(scene.holder.position.x, scene.holder.position.y)) < 0.00001,
                            "Viewport offset was applied to the centered anatomy twice")
                try require(simd_distance(centeredScale, scene.holder.scale) < 0.00001 * max(1, simd_length(centeredScale)), "View position must not change model size")
                try await validateSections(scene, asset: asset)
                reports.append(["sectionAxesTested": 3, "asset":asset.id, "passed":true, "parts":asset.parts.count, "texturedMeshes":texturedMeshes, "regionalPaletteMeshesTested":styledMeshes, "sceneObservationFeedbackTested":true, "screenAxisDragTested":true, "rotationPersistenceTested":true, "tissuePBRMapsTested":true, "studioLightingTested":true, "independentPartMovementTested":true, "isolatedPartPivotsTested":asset.parts.count, "phaseViewpointTested":true, "statesTested":states.count, "guidedStepsTested":steps.count, "lessonActionsTested":steps.count, "labelTargetsTested":steps.count, "separationFramesTested": states.count * 5, "inPlaceZoomSamplesTested": states.count * 9])
            } catch {
                reports.append(["asset":asset.id, "passed":false, "error":String(describing:error)])
            }
        }
        var referenceReports: [[String: Any]] = []
        for asset in HeartAsset.referenceModels {
            writeProgress("atlas", asset: asset.id)
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
                let styledMeshes = try validateRegionalPalette(model, asset: asset)
                try await validateSections(scene, asset: asset)
                referenceReports.append(["sectionAxesTested": 3, "asset": asset.id, "passed": true, "regionalPaletteMeshesTested": styledMeshes, "parts": asset.parts.count, "isolatedPartPivotsTested": asset.parts.count, "selectionSeparationReassemblyTested": true])
            } catch {
                referenceReports.append(["asset": asset.id, "passed": false, "error": String(describing: error)])
            }
        }
        let payload: [String:Any] = ["validationScene":"live RealityView", "specimenInteractions": specimenInteractionReports, "morphMeshes": morphReport, "guidedSpecimens": guidedSpecimenReport, "lessonProgress": lessonProgressReport, "separationTransition": transitionReport, "assets":reports, "referenceAssets":referenceReports, "passed":specimenInteractionReports.count == HeartProjectModel.all.count && specimenInteractionReports.allSatisfy { $0["passed"] as? Bool == true } && guidedSpecimenReport["passed"] as? Bool == true && morphReport["passed"] as? Bool == true && referenceReports.count == 7 && referenceReports.allSatisfy { $0["passed"] as? Bool == true } && !reports.isEmpty && reports.allSatisfy { $0["passed"] as? Bool == true } && transitionReport["passed"] as? Bool == true && lessonProgressReport["passed"] as? Bool == true]
        writeProgress("complete", asset: "all")
        let url = URL.documentsDirectory.appending(path:"heart-asset-validation.json")
        do {
            try JSONSerialization.data(withJSONObject:payload, options:[.prettyPrinted,.sortedKeys]).write(to:url, options:.atomic)
        } catch { print("Could not write validation report: \(error)") }
    }

    private static func writeProgress(_ stage: String, asset: String) {
        let report = ["stage": stage, "asset": asset, "updated": ISO8601DateFormatter().string(from: Date())]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: .sortedKeys) {
            try? data.write(to: URL.documentsDirectory.appending(path: "heart-section-progress.json"), options: .atomic)
        }
    }

    private static func validateSections(_ scene: HeartModelScene, asset: HeartAsset) async throws {
        scene.apply(asset: asset, selected: "", isolate: false, cutaway: false, context: true, separation: 0)
        let available = BoundingBox(min: [-0.2, -0.2, 0], max: [0.2, 0.2, 0])
        scene.sectionAxis = -1; scene.fit(in: available, zoom: 1)
        let originalScale = scene.holder.scale, originalPosition = scene.holder.position
        for axis in [2, 0, 1, -1] {
            try await scene.sections.prepare(axis: axis)
            scene.sectionAxis = axis
            scene.apply(asset: asset, selected: "", isolate: false, cutaway: false, context: true, separation: 0)
            scene.fit(in: available, zoom: 1)
            try require(scene.sectionError == nil, "Lesson section failed")
            try require(simd_distance(originalScale, scene.holder.scale) < 0.00001 && simd_distance(originalPosition, scene.holder.position) < 0.00001, "Section changed fitted viewpoint")
            try require(scene.sections.entries.contains { $0.entity.components[ModelComponent.self] != nil }, "Lesson section removed every surface")
        }
        try require(scene.sections.entries.allSatisfy { $0.entity.components[ModelComponent.self]?.mesh === $0.original.mesh }, "Lesson section changed source mesh on restoration")
    }

    /// Check the installed scene materials, not just the source USDZ or style helper.
    /// The named anatomy lookup is independently covered by catalogue policy tests.
    private static func validateRegionalPalette(_ model: Entity, asset: HeartAsset) throws -> Int {
        var checked = 0
        for part in asset.parts {
            let region = HeartAnatomyRegion.identifiedPart(part.id)
            guard region != nil || HeartAnatomyRegion.isUnsegmentedTubeWall(part.id) else { continue }
            guard let node = model.findEntity(named: part.id) else {
                try require(false, "Missing styled region: \(part.id)")
                continue
            }
            let base = (region ?? .ventricular).rgb
            let lightening = part.id.hasPrefix("CardiacJelly_") ? 0.22 : part.id.hasPrefix("Endocardium_") ? 0.12 : 0.0
            let expected = base + (SIMD3<Double>(repeating: 1) - base) * lightening
            let countBefore = checked
            func inspect(_ entity: Entity) throws {
                if let component = entity.components[ModelComponent.self] {
                    for case let material as PhysicallyBasedMaterial in component.materials {
                        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                        try require(material.baseColor.tint.getRed(&r, green: &g, blue: &b, alpha: &a)
                                    && simd_distance(SIMD3<Double>(Double(r), Double(g), Double(b)), expected) < 0.001
                                    && material.baseColor.texture == nil,
                                    "Installed regional palette mismatch: \(part.id)")
                        checked += 1
                    }
                }
                for child in entity.children { try inspect(child) }
            }
            try inspect(node)
            try require(checked > countBefore, "No styled material in mapped region: \(part.id)")
        }
        return checked
    }

    private static func requireFits(_ scene: HeartModelScene, model: Entity, available: BoundingBox) throws {
        let bounds = model.visualBounds(relativeTo: scene.holder, excludeInactive: true)
        try require(bounds.extents.x > 0 && bounds.extents.y > 0 && bounds.max.z.isFinite,
                    "Fitting check measured empty or inactive geometry")
        let size = bounds.extents * scene.holder.scale
        try require(size.x <= available.extents.x + 0.00001 && size.y <= available.extents.y + 0.00001,
                    "Visible rotated/separated anatomy exceeded the model area")
        try require(simd_length(scene.spin.position + scene.spin.orientation.act(scene.framingCenter)) < 0.00001,
                    "Anatomical pivot left the model centre")
        try require(abs(scene.holder.position.x) < 0.00001 && abs(scene.holder.position.y) < 0.00001,
                    "Viewport offset was applied to the centered anatomy twice")
        try require(bounds.min.z * scene.holder.scale.z + scene.holder.position.z > 0 &&
                    bounds.max.z * scene.holder.scale.z + scene.holder.position.z <= 0.501,
                    "Anatomy escaped visible workspace depth")
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
