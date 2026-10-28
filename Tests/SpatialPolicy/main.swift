import Foundation
import simd
import RealityKit
import AppKit
import Metal
func check(_ condition: Bool, _ message: String) { precondition(condition, message) }
for limit in [HeartModelZoom.overviewMaximum, HeartModelZoom.range.upperBound] {
    var current = 1.0
    for index in 0..<10000 {
        let factor = [0.0001, 10000, Double.nan, .infinity, -1, 0, 1.01, 0.99][index % 8]
        let next = HeartModelZoom.resized(start: current, current: current, magnification: factor, maximum: limit)
        check(next.isFinite && next >= 0.4 && next <= limit, "Unsafe scale")
        check(next <= current * 1.15 + 1e-10 && next >= current / 1.15 - 1e-10, "Discontinuous scale")
        if !factor.isFinite || factor <= 0 { check(next == current, "Invalid sample changed scale") }
        current = next
    }
}
print("PASS: 20,000 resize samples; finite values, limits, discontinuities, invalid samples")
var enlarged = 1.0
for _ in 0..<40 {
    enlarged = HeartModelZoom.resized(start: 1, current: enlarged, magnification: 100,
                                     maximum: HeartModelZoom.overviewMaximum)
}
check(enlarged == 2.5, "In-place zoom cannot reach the requested upper limit")
check(HeartModelZoom.clamped(100) == 2.5 && HeartModelZoom.clamped(-100) == 0.4,
      "Restored scale bypassed zoom limits")
print("PASS: repeated pinch reaches 2.5x; restored scales obey limits")
var attempt = HeartRecognitionAttempt()
attempt.commit()
check(attempt.responses == 0 && !attempt.correct, "Empty response accepted")
attempt.selection = "Ligamentum"
attempt.commit()
check(!attempt.correct && attempt.feedback.contains("remnant"), "Missing misconception feedback")
attempt.selection = "LeftSubclavian_Posterior"
attempt.commit()
check(attempt.feedback.contains("branch"), "Wrong feedback for branch")
attempt.hintUsed = true
attempt.selection = "AorticIsthmus_Coarctation_Posterior"
attempt.commit()
check(attempt.outcome == "Correct with hint", "Hint counted as unaided")
var reveal = HeartRecognitionAttempt()
reveal.revealed = true
reveal.selection = "AorticIsthmus_Coarctation_Posterior"
reveal.commit()
check(!reveal.correct && reveal.responses == 0 && reveal.outcome == "Revealed", "Reveal awarded correctness")
let decoded = try JSONDecoder().decode(HeartRecognitionAttempt.self, from: JSONEncoder().encode(attempt))
check(decoded == attempt, "Assessment evidence lost in persistence")
var independent = HeartRecognitionAttempt()
independent.selection = "AorticIsthmus_Coarctation_Anterior"
independent.commit()
check(independent.outcome == "Correct without hint", "Valid region rejected")
print("PASS: recognition scoring, misconception feedback, hint/reveal separation, persistence")
var review = HeartRecognitionAttempt()
review.previouslyStudied = true
review.selection = "AorticIsthmus_Coarctation_Posterior"
review.commit()
check(review.outcome == "Correct during review", "Review counted as new recognition")
review.hintUsed = true
check(review.outcome == "Correct with hint", "Review concealed assistance")
print("PASS: prior study and hinted review remain distinct")
let day = 86_400.0
let epoch = Date(timeIntervalSince1970: 1_000_000)
var first = HeartRecognitionAttempt()
first.selection = "AorticIsthmus_Coarctation_Anterior"
first.confidence = "Very sure"
first.commit()
let firstRecord = HeartRecognitionRecord(date: epoch, attempt: first, practice: false)
let scheduled = HeartRecognitionReview(records: [firstRecord], intervalDays: 3)
check(scheduled.nextReview == epoch.addingTimeInterval(3 * day), "Confident review interval ignored")
check(!scheduled.isDue(at: epoch.addingTimeInterval(day)), "Review due too early")
check(scheduled.isDue(at: epoch.addingTimeInterval(3 * day)), "Due review missing")
var later = first
later.id = UUID()
later.previouslyStudied = true
let laterRecord = HeartRecognitionRecord(date: epoch.addingTimeInterval(3 * day), attempt: later, practice: true)
check(HeartRecognitionReview(records: [firstRecord, laterRecord]).laterRecallCount == 1, "Later recall not distinguished")
let sameDay = HeartRecognitionRecord(date: epoch.addingTimeInterval(600), attempt: later, practice: true)
check(HeartRecognitionReview(records: [firstRecord, sameDay]).laterRecallCount == 0, "Immediate retry counted as delayed recall")
later.hintUsed = true
let hinted = HeartRecognitionRecord(date: epoch.addingTimeInterval(3 * day + 10), attempt: later, practice: true)
let combined = HeartRecognitionReview(records: [hinted, firstRecord, laterRecord])
check(combined.sessions.count == 2 && combined.laterRecallCount == 0, "Session deduplication/assistance failed")
check(combined.nextReview == hinted.date.addingTimeInterval(day), "Hinted session not brought forward")
check(HeartRecognitionReview(records: []).nextReview == nil, "Review invented without an attempt")
print("PASS: review due dates, session deduplication, assistance and delayed recall")

// Pilot checks cannot award correctness for skipped or invalid answers.
let prediction = HeartLearningPilot.check(lesson: HeartLearningPilot.cushionLesson, step: 1)!
let recall = HeartLearningPilot.check(lesson: HeartLearningPilot.cushionLesson, step: 4)!
assert(HeartLearningPilot.cushionCards.count == 5)
assert(HeartLearningPilot.coarctationCards.count == 5)
assert(HeartLearningPilot.check(lesson: HeartLearningPilot.cushionLesson, step: 0) == nil)
assert(!HeartKnowledgeRecord(check: prediction, selectedOption: nil, explanationViewed: true).correct)
assert(!HeartKnowledgeRecord(check: prediction, selectedOption: 0, explanationViewed: true).correct)
assert(HeartKnowledgeRecord(check: prediction, selectedOption: 1, explanationViewed: true).correct)
assert(HeartKnowledgeRecord(check: recall, selectedOption: 2, explanationViewed: true).correct)
let skipped = HeartKnowledgeRecord(check: recall, selectedOption: nil, explanationViewed: true)
let recovered = try! JSONDecoder().decode(HeartKnowledgeRecord.self, from: JSONEncoder().encode(skipped))
assert(recovered.selectedOption == nil && !recovered.correct)
assert(HeartLearningPilot.cushionCards[1].concepts.isEmpty)
assert(HeartLearningPilot.cushionCards[4].concepts.isEmpty)
print("Learning pilot content and independent assessment records passed")

// Check the actual transported frames, including the intermediate bend path.
let straightCentres = HeartLoopingGeometry.centres(progress: 0)
for frame in 0...100 {
    let p = Float(frame) / 100
    let frames = HeartLoopingGeometry.frames(progress: p)
    let next = HeartLoopingGeometry.frames(progress: min(1, p + 0.001))
    for ring in 0...96 {
        let c = frames[ring].centre
        check(c.x.isFinite && c.y.isFinite && c.z.isFinite, "Nonfinite looping centre")
        check(abs(simd_length(frames[ring].side) - 1) < 0.0001
              && abs(simd_dot(frames[ring].side, frames[ring].dorsal)) < 0.0001, "Collapsed looping frame")
        check(simd_distance(next[ring].centre, c) < 0.01, "Discontinuous looping centre")
        if ring < 96 {
            check(simd_distance(frames[ring + 1].centre, c) >= 0.99 * simd_distance(straightCentres[ring + 1], straightCentres[ring]),
                  "Intermediate bend compressed its centreline")
        }
    }
}
check(HeartLoopingGeometry.centre(0.5, 0) != HeartLoopingGeometry.centre(0.5, 1), "Morph does not change geometry")
print("PASS: 9,797 transported frames; finite geometry, preserved segment length and continuous centreline")

for value in [-100.0, -1, 0, 1.4, 2, 2.1, 2.5, 2.9, 3, 4.6, 5.2, 5.8, 6, 7, 100, .nan, .infinity] {
    let position = HeartDevelopmentTimeline.position(value)
    check(position.isFinite && (0...7).contains(position), "Unsafe timeline position")
    check((0...7).contains(HeartDevelopmentTimeline.stage(position)), "Invalid stage index")
    if (value >= 1 && value <= 3) || (value >= 5 && value <= 6) { check(position == value, "Lost continuous timeline position") }
    else { check(position == position.rounded(), "Unsupported morph interval") }
}
check(HeartDevelopmentTimeline.loopingProgress(2.5) == 0.5, "Incorrect morph mapping")
print("PASS: continuous timeline mapping, stage bounds and unsupported interval stops")

for position in [2.1, 2.4, 2.6, 2.9] {
    check(HeartDevelopmentTimeline.adjacentStage(from: position, forward: false) == 2, "Previous skipped transition start")
    check(HeartDevelopmentTimeline.adjacentStage(from: position, forward: true) == 3, "Next skipped transition end")
}
check(HeartDevelopmentTimeline.adjacentStage(from: 0, forward: false) == 0, "Previous escaped timeline")
check(HeartDevelopmentTimeline.adjacentStage(from: 7, forward: true) == 7, "Next escaped timeline")
check(HeartDevelopmentTimeline.adjacentStage(from: 3, forward: true) == 4, "Next did not leave endpoint")
print("PASS: timeline arrows preserve transition endpoints")

// Validate actual closed/cutaway surfaces, not only the tube centreline.
for cutaway in [false, true] {
    let baseline = HeartLoopingGeometry.surface(progress: 0, cutaway: cutaway)
    for frame in 0...20 {
        let surface = HeartLoopingGeometry.surface(progress: Double(frame) / 20, cutaway: cutaway)
        check(surface.triangles == baseline.triangles, "Morph changed vertex connectivity")
        check(surface.positions.count == baseline.positions.count, "Morph changed vertex count")
        for normal in surface.normals {
            check(normal.x.isFinite && normal.y.isFinite && normal.z.isFinite, "Invalid surface normal")
            check(abs(simd_length(normal) - 1) < 0.001, "Surface normal is not unit length")
        }
        for index in stride(from: 0, to: surface.triangles.count, by: 3) {
            let a = surface.positions[Int(surface.triangles[index])]
            let b = surface.positions[Int(surface.triangles[index + 1])]
            let c = surface.positions[Int(surface.triangles[index + 2])]
            check(simd_length_squared(simd_cross(b-a, c-a)) > 1e-20, "Collapsed surface triangle")
        }
    }
}
print("PASS: 42 closed/cutaway morph surfaces, stable topology, valid normals and noncollapsed triangles")

// Centreline continuity alone missed a world-axis frame flip at ~40%.
// Track corresponding surface vertices through fine forward/backward samples.
var largestMorphStep: Float = 0
for cutaway in [false, true] {
    var previous = HeartLoopingGeometry.surface(progress: 0, cutaway: cutaway)
    for frame in 1...200 {
        let surface = HeartLoopingGeometry.surface(progress: Double(frame) / 200, cutaway: cutaway)
        for i in surface.positions.indices {
            largestMorphStep = max(largestMorphStep, simd_distance(surface.positions[i], previous.positions[i]))
        }
        let frames = HeartLoopingGeometry.frames(progress: Float(frame) / 200)
        for ring in 0...96 {
            for side in 0..<48 {
                let i = ring * 49 + side
                let radial = simd_normalize(surface.positions[i] - frames[ring].centre * 0.1)
                check(simd_dot(radial, surface.normals[i]) > 0.1, "Outer wall folded inward during bending")
            }
        }
        for point in surface.positions {
            check(abs(point.x) < 0.25 && abs(point.y) < 0.25 && abs(point.z) < 0.25, "Morph escaped its GPU drawing bounds")
        }
        previous = surface
    }
    let replay = HeartLoopingGeometry.surface(progress: 0.4, cutaway: cutaway)
    _ = HeartLoopingGeometry.surface(progress: 0.8, cutaway: cutaway)
    check(replay.positions == HeartLoopingGeometry.surface(progress: 0.4, cutaway: cutaway).positions,
          "Reverse scrubbing changed the deformation path")
}
check(largestMorphStep < 0.004, "Tube surface flips between adjacent progress samples")
for region in HeartAnatomyRegion.allCases {
    check(region.morphRGB(progress: 0) == HeartAnatomyRegion.ventricular.rgb, "Colour pop at joining/looping boundary")
    check(simd_distance(region.morphRGB(progress: 0.18), region.rgb) < 0.000001, "Region colour did not reach its legend")
    check(simd_distance(region.morphRGB(progress: 0), region.morphRGB(progress: 0.001)) < 0.001,
          "Abrupt region-colour reveal")
}
print("PASS: fine-step surface continuity, deterministic reverse scrubbing and continuous region-colour reveal; largest step \(largestMorphStep)m")

for frame in 0...40 {
    let surface = HeartTubeFusionGeometry.surface(progress: Double(frame) / 40)
    check(!surface.triangles.isEmpty, "Missing fusion geometry")
    for point in surface.positions { check(point.x.isFinite && point.y.isFinite && point.z.isFinite, "Nonfinite fusion vertex") }
    for normal in surface.normals { check(abs(simd_length(normal)-1) < 0.001, "Invalid fusion normal") }
}
// At fusion completion both half-surfaces must have the straight tube radius.
let joined = HeartTubeFusionGeometry.surface(progress: 1)
for ring in 0...96 {
    let t = Float(ring)/96
    let centre = HeartLoopingGeometry.centre(t, 0)*0.1
    let expected = HeartLoopingGeometry.radius(t)*0.1
    for side in 0...48 {
        let point = joined.positions[ring*49+side]
        check(abs(simd_length(point-centre)-expected) < 0.00001, "Fusion endpoint differs from straight tube")
    }
}
print("PASS: 41 fusion states and shared straight-tube endpoint")

// A connected pose is not enough: the approach and departure should also slow
// down, rather than switching from lateral convergence to bending at full speed.
check(HeartMorphTiming.eased(.nan) == 0 && HeartMorphTiming.eased(-1) == 0 && HeartMorphTiming.eased(2) == 1,
      "Invalid morph time escaped its phase")
var previousTime = 0.0
for step in 0...100 {
    let p = Double(step) / 100
    let t = HeartMorphTiming.eased(p)
    check(t >= previousTime && abs(t + HeartMorphTiming.eased(1 - p) - 1) < 1e-12,
          "Morph timing reversed direction or treated reverse scrubs differently")
    previousTime = t
}
func largestDisplacement(_ a: [SIMD3<Float>], _ b: [SIMD3<Float>]) -> Float {
    zip(a, b).map { simd_distance($0, $1) }.max() ?? 0
}
for layer in HeartTubeLayer.allCases {
    for endpoint in [0.0, 1.0] {
        let near = endpoint == 0 ? 0.01 : 0.99
        let far = endpoint == 0 ? 0.02 : 0.98
        let joining = HeartTubeFusionGeometry.surface(progress: endpoint, outerRadius: layer.outer, innerRadius: layer.inner)
        let joiningNear = HeartTubeFusionGeometry.surface(progress: near, outerRadius: layer.outer, innerRadius: layer.inner)
        let joiningFar = HeartTubeFusionGeometry.surface(progress: far, outerRadius: layer.outer, innerRadius: layer.inner)
        check(largestDisplacement(joining.positions, joiningNear.positions) <= largestDisplacement(joining.positions, joiningFar.positions) * 0.35 + 0.0000002,
              "Joining still reaches an endpoint at full speed")
        for opening in [0.0, 1] {
            let loop = HeartLoopingGeometry.surface(progress: endpoint, opening: opening, outerRadius: layer.outer, innerRadius: layer.inner)
            let loopNear = HeartLoopingGeometry.surface(progress: near, opening: opening, outerRadius: layer.outer, innerRadius: layer.inner)
            let loopFar = HeartLoopingGeometry.surface(progress: far, opening: opening, outerRadius: layer.outer, innerRadius: layer.inner)
            check(largestDisplacement(loop.positions, loopNear.positions) <= largestDisplacement(loop.positions, loopFar.positions) * 0.35 + 0.0000002,
                  "Looping starts or ends with a sudden velocity change")
        }
    }
}
print("PASS: reversible morph timing and eased geometric endpoints for all three tissue layers")

for process in [HeartMorphLearning.Process.joining, .looping, .outflow] {
    let checkContent = HeartMorphLearning.check(process)
    check(checkContent.options.indices.contains(checkContent.answer), "Invalid morph answer")
    check(Set(checkContent.options).count == checkContent.options.count, "Duplicate morph alternatives")
}
print("PASS: morph observation checks have valid distinct answers")


// Outflow morph keeps both cushion meshes connected across reversible progression.
for cut in [false, true] {
    let baseline = HeartOutflowGeometry.surface(progress: 0, cutaway: cut)
    for frame in 0...40 {
        let surface = HeartOutflowGeometry.surface(progress: Double(frame)/40, cutaway: cut)
        check(surface.positions.count == baseline.positions.count && surface.triangles == baseline.triangles,
              "Outflow morph changed connectivity")
        check(surface.materials.count * 3 == surface.triangles.count && Set(surface.materials) == [0,1],
              "Outflow tissue/material mapping invalid")
        for point in surface.positions { check(point.x.isFinite && point.y.isFinite && point.z.isFinite, "Nonfinite outflow geometry") }
        for normal in surface.normals { check(abs(simd_length(normal)-1) < 0.001, "Invalid outflow normal") }
        for i in stride(from: 0, to: surface.triangles.count, by: 3) {
            let a = surface.positions[Int(surface.triangles[i])], b = surface.positions[Int(surface.triangles[i+1])], c = surface.positions[Int(surface.triangles[i+2])]
            check(simd_length(simd_cross(b-a,c-a)) > 1e-12, "Collapsed outflow triangle")
        }
    }
}
check(HeartDevelopmentTimeline.position(5.4) == 5.4 && HeartDevelopmentTimeline.position(4.4) == 4,
      "Outflow interval or unsupported stage stops wrong")
print("PASS: 82 outflow surfaces, stable topology/materials, finite normals and noncollapsed triangles")

check(HeartDevelopmentConnection.at(2.5).isEmpty, "Later anomaly cue appeared during early looping")
check(Set(HeartDevelopmentConnection.at(4).map(\.id)) == ["atrial", "cushion"], "Missing atrial/AV junction branches")
check(Set(HeartDevelopmentConnection.at(5.4).map(\.id)) == ["outflow", "tga", "arch"], "Outflow branches did not follow fractional timeline")
check(Set(HeartDevelopmentConnection.at(7).map(\.id)) == ["ductus", "arch"], "Birth transition missing ductus/arch distinction")
check(HeartDevelopmentConnection.forLessons("Endocardial cushion fusion").first?.id == "cushion", "Cushion lesson missing AVSD link")
check(HeartDevelopmentConnection.forLessons("Outflow tract septation").count == 3, "Guided outflow missing alternatives")
check(Set(HeartDevelopmentConnection.all.map(\.id)).count == HeartDevelopmentConnection.all.count, "Duplicate branch identity")
print("PASS: developmental branch windows, fractional timeline mapping and guided lesson coverage")

let regionSurface = HeartLoopingGeometry.surface(progress: 0, cutaway: true)
for progress in [0.25, 0.5, 0.75, 1.0] {
    let surface = HeartLoopingGeometry.surface(progress: progress, cutaway: true)
    check(surface.materials == regionSurface.materials, "Region identity drifted during looping")
}
check(Set(regionSurface.materials) == Set(HeartAnatomyRegion.allCases.map { UInt32($0.rawValue) }), "Missing tube region colour")
check(regionSurface.materials.count * 3 == regionSurface.triangles.count, "Invalid regional triangle assignments")
check(HeartAnatomyRegion.identifiedPart("Myocardium_AVCanal_Anterior") == .atrioventricular
      && HeartAnatomyRegion.identifiedPart("CS18_cs18_N1645_left_atrium") == .atrial
      && HeartAnatomyRegion.identifiedPart("Default123") == nil, "Region mapping guessed or missed source anatomy")
print("PASS: six regional colours remain attached during looping; explicit named-region mapping")
// Actual catalogue aliases: export suffixes must not change a region's colour.
let catalogueAliases: [(String, HeartAnatomyRegion)] = [
    ("AtrialWall_Later_Posterior", .atrial), ("AtriumWall_R_Anterior", .atrial),
    ("CS16_right_atrium2", .atrial), ("CS14_N925_left_atrium_sm_dec", .atrial),
    ("VentricleWall_L_Posterior", .ventricular), ("CS16_left_vent", .ventricular),
    ("CS20_CS20_N913_right_ventricle_surf", .ventricular),
    ("CS14_N925_sinus_venosus_sm_dec", .inflow), ("CS14_N925_vena_cava_sm_dec", .inflow),
    ("CS16_sinus_venosus_vena_cava2", .inflow), ("SuperiorCavalMouth_Anterior", .inflow),
    ("CS14_N925_oft_sm_dec", .arterial), ("CS20_CS20_N913_outflow", .arterial),
    ("ArterialBranch_L", .arterial)
]
for (name, region) in catalogueAliases {
    check(HeartAnatomyRegion.identifiedPart(name) == region, "Unmatched catalogue region: \(name)")
}
for name in ["Default123", "CS16_epicardium", "CS14_N925_outside_tissue_sm_dec", "Ventricularis_AorticCusp1_Refined", "Myocardium_L_Anterior"] {
    check(HeartAnatomyRegion.identifiedPart(name) == nil, "Invented regional assignment: \(name)")
}
check(HeartAnatomyRegion.isUnsegmentedTubeWall("Myocardium_L_Anterior")
      && HeartAnatomyRegion.isUnsegmentedTubeWall("Endocardium_R_Posterior")
      && !HeartAnatomyRegion.isUnsegmentedTubeWall("Endoderm_Context"), "Paired tube wall identification failed")
print("PASS: catalogue aliases keep the palette across lessons and atlas stages without guessing unnamed regions")

// Material harmonization must not erase source anatomy or mutate the source copy.
if MTLCreateSystemDefaultDevice() != nil {
func rgba(_ color: NSColor) -> [CGFloat] {
    let rgb = color.usingColorSpace(.sRGB)!
    return [rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent]
}
func sameColor(_ left: NSColor, _ right: NSColor) -> Bool {
    zip(rgba(left), rgba(right)).allSatisfy { abs($0 - $1) < 0.0001 }
}
// Compare cases directly: older host RealityKit runtimes lack the newer SDK's
// synthesized Blending equality symbol, although the public cases are supported.
func sameBlending(_ left: PhysicallyBasedMaterial.Blending, _ right: PhysicallyBasedMaterial.Blending) -> Bool {
    switch (left, right) {
    case (.opaque, .opaque): return true
    case (.transparent(let a), .transparent(let b)):
        return a.scale == b.scale && a.texture?.resource == b.texture?.resource
    default: return false
    }
}
var sourceMaterial = PhysicallyBasedMaterial()
let sourceTint = NSColor(srgbRed: 0.2, green: 0.55, blue: 0.8, alpha: 0.35)
sourceMaterial.baseColor = .init(tint: sourceTint)
sourceMaterial.roughness = .init(floatLiteral: 0.04)
sourceMaterial.metallic = .init(floatLiteral: 0.9)
sourceMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.42))
sourceMaterial.faceCulling = .none
sourceMaterial.opacityThreshold = 0.17
sourceMaterial.emissiveIntensity = 0.06
let styledMaterial = HeartModelStyle.harmonized(sourceMaterial) as! PhysicallyBasedMaterial
check(sameColor(styledMaterial.baseColor.tint, sourceTint), "Styling recoloured semantic source tint")
check(sameBlending(styledMaterial.blending, sourceMaterial.blending), "Styling removed source transparency")
if case .none = styledMaterial.faceCulling {} else { check(false, "Styling culled visible cut surfaces") }
check(styledMaterial.opacityThreshold == 0.17 && styledMaterial.emissiveIntensity == 0.06,
      "Styling altered cutout or selection appearance")
check(styledMaterial.roughness.scale == HeartModelStyle.roughness && styledMaterial.metallic.scale == 0,
      "Untextured anatomy did not adopt shared surface response")
check(sourceMaterial.roughness.scale == 0.04 && sourceMaterial.metallic.scale == 0.9 && sameColor(sourceMaterial.baseColor.tint, sourceTint),
      "Styling mutated original source material")
let tissueMaterial = HeartModelStyle.tissue()
let adaptedMaterial = HeartModelStyle.harmonized(sourceMaterial, uniformTissue: true) as! PhysicallyBasedMaterial
check(sameColor(adaptedMaterial.baseColor.tint, tissueMaterial.baseColor.tint.withAlphaComponent(0.35)),
      "Uniform adaptation lost the shared tissue palette or source alpha")
check(sameBlending(adaptedMaterial.blending, sourceMaterial.blending), "Uniform adaptation changed source blending")
check(zip(rgba(tissueMaterial.baseColor.tint), [CGFloat(0.70), 0.39, 0.43, 1]).allSatisfy { abs($0 - $1) < 0.0001 },
      "Runtime tissue drifted from the selected regional palette")
let styledAgain = HeartModelStyle.harmonized(styledMaterial) as! PhysicallyBasedMaterial
check(sameColor(styledAgain.baseColor.tint, styledMaterial.baseColor.tint)
      && sameBlending(styledAgain.blending, styledMaterial.blending)
      && styledAgain.roughness.scale == styledMaterial.roughness.scale,
      "Repeated styling compounds material changes")
var unlitSource = UnlitMaterial(color: sourceTint)
unlitSource.blending = .transparent(opacity: .init(floatLiteral: 0.42))
let unchangedUnlit = HeartModelStyle.harmonized(unlitSource, uniformTissue: true)
check(unchangedUnlit is UnlitMaterial, "Unknown-to-style shader replaced by tissue")
let unlitResult = unchangedUnlit as! UnlitMaterial
check(sameColor(unlitResult.color.tint, unlitSource.color.tint) && sameBlending(unlitResult.blending, unlitSource.blending),
      "Unsupported material appearance changed")
print("PASS: source tint/transparency/culling preserved; shared tissue palette, source immutability and idempotence")

// Regional hue stays stable while bright source colours adopt the restrained palette.
var brightRegion = sourceMaterial
brightRegion.baseColor.tint = NSColor(srgbRed: 1, green: 0.05, blue: 0.1, alpha: 0.4)
let tonedRegion = HeartModelStyle.harmonized(brightRegion, toneRegions: true) as! PhysicallyBasedMaterial
let tonedRGB = tonedRegion.baseColor.tint.usingColorSpace(.sRGB)!
let brightRGB = brightRegion.baseColor.tint.usingColorSpace(.sRGB)!
check(abs(tonedRGB.hueComponent - brightRGB.hueComponent) < 0.0001,
      "Regional palette changed the source hue")
check(tonedRGB.saturationComponent <= 0.5501 && tonedRGB.brightnessComponent <= 0.7201
      && abs(tonedRGB.alphaComponent - 0.4) < 0.0001, "Regional palette lost bounded colour or alpha")
let tonedAgain = HeartModelStyle.harmonized(tonedRegion, toneRegions: true) as! PhysicallyBasedMaterial
check(sameColor(tonedRegion.baseColor.tint, tonedAgain.baseColor.tint), "Repeated regional toning darkened the model")
print("PASS: regional hues and alpha retained with restrained saturation/brightness")

// Use one tiny real texture resource to verify every authored map survives by resource equality,
// not Swift wrapper identity (RealityKit returns a new wrapper from material getters),
// including its UV channel and scalar multiplier. No model downloads or files needed.
let textureContext = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8,
                               space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
textureContext.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1))
textureContext.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
let preservationTexture = try TextureResource.generate(from: textureContext.makeImage()!, options: .init(semantic: .color))
var authoredTexture = MaterialParameters.Texture(preservationTexture)
authoredTexture.uvIndex = 1
var texturedSource = sourceMaterial
texturedSource.baseColor.texture = authoredTexture
texturedSource.normal.texture = authoredTexture
texturedSource.roughness = .init(scale: 0.7, texture: authoredTexture)
texturedSource.metallic = .init(scale: 0.2, texture: authoredTexture)
texturedSource.ambientOcclusion.texture = authoredTexture
let texturedResult = HeartModelStyle.harmonized(texturedSource, uniformTissue: true, toneRegions: true) as! PhysicallyBasedMaterial
let beforeMaps = [texturedSource.baseColor.texture, texturedSource.normal.texture, texturedSource.roughness.texture,
                  texturedSource.metallic.texture, texturedSource.ambientOcclusion.texture]
let afterMaps = [texturedResult.baseColor.texture, texturedResult.normal.texture, texturedResult.roughness.texture,
                 texturedResult.metallic.texture, texturedResult.ambientOcclusion.texture]
for (index, pair) in zip(beforeMaps, afterMaps).enumerated() {
    let (before, after) = pair
    check(before != nil && after != nil && before?.resource == after?.resource && before?.uvIndex == after?.uvIndex,
          "Styling replaced texture or UV channel")
}
check(sameColor(texturedResult.baseColor.tint, texturedSource.baseColor.tint), "Uniform styling tinted a source colour map")
check(texturedResult.roughness.scale == 0.7 && texturedResult.metallic.scale == 0.2,
      "Styling changed authored texture multipliers")
check(texturedSource.baseColor.texture?.resource == preservationTexture && texturedSource.roughness.scale == 0.7,
      "Styling modified original textured source")
print("PASS: original colour, normal, roughness, metallic and occlusion textures and UV channels retained")
let mappedRegion = HeartModelStyle.identifiedRegion(texturedSource, partID: "Myocardium_AVCanal_Anterior")
check(mappedRegion.baseColor.texture == nil && mappedRegion.normal.texture?.resource == preservationTexture
      && mappedRegion.roughness.texture?.resource == preservationTexture,
      "Explicit region adaptation lost surface detail maps")
check(sameBlending(mappedRegion.blending, texturedSource.blending), "Region adaptation changed transparency")
let mappedJelly = HeartModelStyle.identifiedRegion(texturedSource, partID: "CardiacJelly_AVCanal_Anterior")
check(!sameColor(mappedRegion.baseColor.tint, mappedJelly.baseColor.tint), "Regional colours erased wall-layer distinction")
check(texturedSource.baseColor.texture?.resource == preservationTexture, "Region adaptation changed original source")
print("PASS: explicit anatomical palette keeps normal/roughness maps, layers and source materials")
let pairedWall = HeartModelStyle.identifiedRegion(texturedSource, partID: "Myocardium_L_Anterior")
let pairedJelly = HeartModelStyle.identifiedRegion(texturedSource, partID: "CardiacJelly_R_Posterior")
check(zip(rgba(pairedWall.baseColor.tint).prefix(3), rgba(HeartModelStyle.tissue().baseColor.tint).prefix(3))
    .allSatisfy { abs($0 - $1) < 0.0001 }, "Detailed paired tube differs from the morph wall palette")
check(pairedWall.normal.texture?.resource == preservationTexture
      && pairedWall.roughness.texture?.resource == preservationTexture
      && !sameColor(pairedWall.baseColor.tint, pairedJelly.baseColor.tint), "Paired tube lost its texture detail or layer distinction")
let unnamed = HeartModelStyle.identifiedRegion(texturedSource, partID: "Default123")
check(unnamed.baseColor.texture?.resource == preservationTexture
      && sameColor(unnamed.baseColor.tint, texturedSource.baseColor.tint), "Unknown source anatomy was recoloured")
print("PASS: paired tubes match the morph wall colour; surface detail, layers and unknown anatomy preserved")
let tonedTexture = HeartModelStyle.harmonized(texturedSource, toneTextures: true) as! PhysicallyBasedMaterial
let tonedTwice = HeartModelStyle.harmonized(tonedTexture, toneTextures: true) as! PhysicallyBasedMaterial
check(tonedTexture.baseColor.texture?.resource == preservationTexture, "Texture grading replaced source detail")
check(rgba(tonedTexture.baseColor.tint).prefix(3).max()! <= 0.6501
      && abs(rgba(tonedTexture.baseColor.tint)[3] - 0.35) < 0.0001, "Texture grade lost ceiling or alpha")
check(sameColor(tonedTexture.baseColor.tint, tonedTwice.baseColor.tint), "Repeated texture grading darkened source")
print("PASS: reference texture grading retains maps/alpha and is idempotent")


} else {
    print("SKIP: material preservation requires Metal access; run with GPU access to verify materials")
}

// Guided specimens are available within the lesson without bypassing an answer gate.
let guidedDevelopment = ["Cardiogenic region", "Paired heart tubes", "Primitive heart tube segments", "Cardiac looping (D-looping)", "Atrial septation", "Endocardial cushion fusion", "Ventricular septation", "Outflow tract septation", "Valvular refinement", "Circulatory transition"]
for lesson in guidedDevelopment {
    check(HeartGuidedAnatomy.lesson(lesson) != nil, "Development lesson has no later-anatomy context: \(lesson)")
    check(!HeartGuidedAnatomy.isAvailable(lesson: lesson, step: 3, answerHidden: true), "Specimen bypasses concealed answer")
}
for lesson in [HeartLearningPilot.cushionLesson, HeartLearningPilot.coarctationLesson] {
    for step in [0, 1] {
        check(!HeartGuidedAnatomy.isAvailable(lesson: lesson, step: step, answerHidden: false), "Specimen pre-empts observation/prediction sequence")
    }
    check(HeartGuidedAnatomy.opensAutomatically(lesson: lesson, step: 3, lastStep: 4, answerHidden: false), "Explanation step lacks integrated anatomy")
    check(!HeartGuidedAnatomy.opensAutomatically(lesson: lesson, step: 4, lastStep: 4, answerHidden: true), "Retrieval exposed realistic answer")
}
check(HeartGuidedAnatomy.lesson("Atrial septation")?.alteredID == "Atrial_Septal_Defect_ASD", "Atrial lesson specimen mismatch")
check(HeartGuidedAnatomy.lesson("Endocardial cushion fusion")?.alteredID == "Atrioventricular_septal_defect_4_chamber_view", "Cushion lesson specimen mismatch")
check(HeartGuidedAnatomy.lesson("Ventricular septation")?.alteredID == "Ventricular_Septal_Defect", "Ventricular lesson specimen mismatch")
check(HeartGuidedAnatomy.lesson("Patent Ductus Arteriosus (PDA)")?.alteredID == "PDA_Patent", "PDA did not use the authored patent model")
check(HeartGuidedAnatomy.lesson("Circulatory transition")?.normalID == "PDA_Closed", "Birth lesson lost its matched closed-remnant comparison")
check(HeartGuidedAnatomy.lesson("Patent Ductus Arteriosus (PDA)")?.normalLabel == "Closed remnant", "Authored PDA model mislabelled as an unrelated specimen")
check(HeartSpecimenPart.parts(for: "PDA_Patent").map(\.id) == ["Aorta", "PulmonaryArteries", "Ductus"], "Authored PDA parts mismatch")
check(HeartSpecimenPart.parts(for: "PDA_Closed").last?.id == "Ligament", "Closed model retained a patent duct")
print("PASS: guided later-anatomy coverage, correct examples and prediction/recognition gates")

// Sections preserve source surfaces and interpolate UVs; no artificial caps.
let sectionTriangle = [
    HeartSectionGeometry.Vertex(position: [-1, 0, 0], normal: [0, 0, 1], uv: [0, 0]),
    HeartSectionGeometry.Vertex(position: [1, 0, 0], normal: [0, 0, 1], uv: [1, 0]),
    HeartSectionGeometry.Vertex(position: [0, 1, 0], normal: [0, 0, 1], uv: [0.5, 1])
]
func sectionArea(_ vertices: [HeartSectionGeometry.Vertex]) -> Float {
    stride(from: 0, to: vertices.count, by: 3).reduce(0) { total, i in
        total + simd_length(simd_cross(vertices[i+1].position - vertices[i].position, vertices[i+2].position - vertices[i].position)) / 2
    }
}
for cut in stride(from: Float(-1.2), through: 1.2, by: 0.025) {
    let a = HeartSectionGeometry.clip(sectionTriangle, plane: [1, 0, 0, -cut])
    let b = HeartSectionGeometry.clip(sectionTriangle, plane: [-1, 0, 0, cut])
    check(abs(sectionArea(a) + sectionArea(b) - 1) < 0.00001, "Section lost or invented surface area")
    for v in a {
        check(v.position.x <= cut + 0.00001, "Section crossed plane")
        check(abs(v.uv.x - (v.position.x + 1)/2) < 0.00001 && abs(v.uv.y - v.position.y) < 0.00001, "Section broke source UVs")
        check(abs(simd_length(v.normal) - 1) < 0.00001, "Section normal is invalid")
    }
}
check(HeartSectionGeometry.clip(sectionTriangle, plane: [0, 0, 1, 0]).count == 3, "Coplanar surface disappeared")
check(HeartSpecimenPart.parts(for: "Transposition_of_the_great_arteries").count == 3, "Export fragments became separate anatomical parts")
check(HeartSpecimenPart.parts(for: "Tetralogy_of_Fallot").count == 1, "Unsegmented Fallot was artificially separated")
for i in 1...1000 {
    let offset = HeartSpecimenPart.boundedOffset([Float(i), -Float(i), Float(i)], diameter: 0.5)
    check(simd_length(offset) <= 0.150001, "Specimen part escaped its movement envelope")
}
check(HeartSpecimenPart.boundedOffset([.nan, 0, 0], diameter: 1) == .zero, "Invalid specimen movement was accepted")
print("PASS: surface/UV/normal-preserving sections, source-group identity, bounded specimen movement")

for count in 2...6 {
    let directions = (0..<count).map { HeartSpecimenPart.separationDirection(index: $0, count: count) }
    for i in directions.indices {
        for j in directions.indices where i != j {
            check(simd_distance(directions[i], directions[j]) > 0.9, "Separate moved nested source parts together")
        }
    }
}
print("PASS: nested source components use distinct separation directions")

// Inspection cuts reveal the lumen without changing developmental geometry.
for progress in [0.0, 0.4, 1.0] {
    let frames = HeartLoopingGeometry.frames(progress: Float(progress))
    var previous = HeartLoopingGeometry.surface(progress: progress, opening: 0.02)
    for step in 1...50 {
        let opening = Double(step) / 50
        let surface = HeartLoopingGeometry.surface(progress: progress, opening: opening)
        check(surface.triangles == previous.triangles, "Partial loop cut rebuilt topology")
        for (a, b) in zip(previous.positions, surface.positions) {
            check(simd_distance(a, b) < 0.001, "Loop inspection cut jumped")
        }
        for wall in 0...1 { for ring in [0, 23, 48, 72, 96] { for side in [0, 12, 24, 48] {
            let point = surface.positions[wall * 97 * 49 + ring * 49 + side]
            let radius = HeartLoopingGeometry.radius(Float(ring) / 96) * 0.1 * (wall == 0 ? 1 : 0.72)
            check(abs(simd_distance(point, frames[ring].centre * 0.1) - radius) < 0.000001,
                  "Inspection cut changed tube radius or wall thickness")
        } } }
        for normal in surface.normals { check(abs(simd_length(normal) - 1) < 0.001, "Invalid partial-cut normal") }
        previous = surface
    }
    let open = HeartOutflowGeometry.surface(progress: progress, opening: 1)
    func materialVertices(_ surface: HeartOutflowGeometry.Surface, material: UInt32) -> [SIMD3<Float>] {
        var indices = Set<Int>()
        for face in surface.materials.indices where surface.materials[face] == material {
            for corner in 0..<3 { indices.insert(Int(surface.triangles[face * 3 + corner])) }
        }
        return indices.sorted().map { surface.positions[$0] }
    }
    let cushions = materialVertices(open, material: 1)
    let posterior = materialVertices(open, material: 0)
    for step in 0...50 {
        let surface = HeartOutflowGeometry.surface(progress: progress, opening: Double(step) / 50)
        check(materialVertices(surface, material: 1) == cushions, "Inspection cut moved or resized outflow cushions")
        check(Array(surface.positions.prefix(posterior.count)) == posterior, "Inspection cut changed posterior wall")
        for normal in surface.normals { check(abs(simd_length(normal) - 1) < 0.001, "Invalid outflow cut normal") }
        for i in stride(from: 0, to: surface.triangles.count, by: 3) {
            let a = surface.positions[Int(surface.triangles[i])], b = surface.positions[Int(surface.triangles[i+1])], c = surface.positions[Int(surface.triangles[i+2])]
            check(simd_length_squared(simd_cross(b-a,c-a)) > 1e-20, "Collapsed partial-cut face")
        }
    }
}
check(HeartLoopingGeometry.surface(progress: 0.4, opening: .nan).positions == HeartLoopingGeometry.surface(progress: 0.4, cutaway: false).positions, "Invalid inspection cut was accepted")
check(HeartOutflowGeometry.surface(progress: 0.4, opening: 4).positions == HeartOutflowGeometry.surface(progress: 0.4, cutaway: true).positions, "Inspection cut exceeded its endpoint")
print("PASS: progressive wall cuts preserve tube thickness, posterior wall and cushion geometry")

var pinchSession = HeartPinchResizeSession()
var pinchZoom = pinchSession.resize(current: 1, magnification: 1.5)
check(pinchZoom <= 1.15, "Pinch session bypassed rate limit")
pinchSession.interrupt(active: true)
pinchZoom = 1
for sample in [1.5, 2.0, 0.5, 4.0] {
    pinchZoom = pinchSession.resize(current: pinchZoom, magnification: sample)
    check(pinchZoom == 1, "Old pinch samples undid reset")
}
pinchSession.end()
pinchZoom = pinchSession.resize(current: 0.8, magnification: 1.1)
check(abs(pinchZoom - 0.88) < 0.00001, "Fresh pinch reused an old baseline")
pinchSession.interrupt(active: false)
check(abs(pinchSession.resize(current: 1, magnification: 1.1) - 1.1) < 0.00001, "Inactive suspension swallowed a fresh pinch")
for _ in 0..<100 { pinchZoom = pinchSession.resize(current: pinchZoom, magnification: 100) }
check(pinchZoom == HeartModelZoom.range.upperBound, "Repeated resizing escaped the shared maximum")
pinchSession.end()
check(pinchSession.resize(current: 1, magnification: .nan) == 1, "Invalid pinch sample moved the model")
print("PASS: pinch cancellation, reset suppression, fresh baselines and repeated scale bounds")

for opening in [0.9998, 0.9999, 0.99995, Double(Float(1).nextDown), Double(1).nextDown, 1.0] {
    let surface = HeartOutflowGeometry.surface(progress: 0.4, opening: opening)
    for i in stride(from: 0, to: surface.triangles.count, by: 3) {
        let a = surface.positions[Int(surface.triangles[i])], b = surface.positions[Int(surface.triangles[i+1])], c = surface.positions[Int(surface.triangles[i+2])]
        check(simd_length_squared(simd_cross(b-a,c-a)) > 1e-20, "Near-open wall produced a zero-area sliver")
    }
}
print("PASS: near-endpoint wall cuts avoid collapsed Float-resolution slivers")

// Early tube layers follow one deformation; layer topology/material identities
// remain stable and assembled interfaces meet without changing the outer wall.
for progress in [-1.0, -0.5, -0.001, 0, 0.4, 1] {
    for opening in [0.0, 0.5, 1] {
        let assembled = HeartTubeLayerGeometry.surface(progress: progress, opening: opening, separation: 0)
        let spread = HeartTubeLayerGeometry.surface(progress: progress, opening: opening, separation: 1)
        check(assembled.triangles == spread.triangles && assembled.materials == spread.materials, "Layer separation changed topology or anatomy identity")
        var base = 0
        for layer in HeartTubeLayer.allCases {
            let source = progress < 0
                ? HeartTubeFusionGeometry.surface(progress: progress + 1, outerRadius: layer.outer, innerRadius: layer.inner)
                : HeartLoopingGeometry.surface(progress: progress, opening: opening, outerRadius: layer.outer, innerRadius: layer.inner)
            for i in source.positions.indices {
                check(simd_distance(assembled.positions[base+i], source.positions[i]) < 0.000001, "Layer assembly changed source geometry")
                check(simd_distance(spread.positions[base+i] - assembled.positions[base+i], layer.offset(separation: 1)) < 0.000001, "Layer separation distorted rather than translated tissue")
                check(abs(simd_length(assembled.normals[base+i]) - 1) < 0.001, "Invalid layer normal")
                check(simd_reduce_max(simd_abs(spread.positions[base+i])) < 0.25, "Layer escaped GPU bounds")
            }
            base += source.positions.count
        }
        check(assembled.materials.allSatisfy { $0 < 18 }, "Layer material escaped the common palette")
        check(Set(assembled.materials.map { $0 / 6 }) == [0,1,2], "Missing tissue layer")
        check(assembled.positions == HeartTubeLayerGeometry.surface(progress: progress, opening: opening, separation: 0).positions, "Layer reverse scrub was nondeterministic")
    }
}
check(HeartTubeLayer.myocardium.inner == HeartTubeLayer.cardiacJelly.outer && HeartTubeLayer.cardiacJelly.inner == HeartTubeLayer.endocardium.outer, "Layer interfaces have a gap or overlap")
print("PASS: layered joining/looping surfaces, shared interfaces, rigid separation and regional identity")

for process in [HeartMorphLearning.Process.joining, .looping, .outflow] {
    let recall = HeartMorphLearning.explanationCheck(process)
    check(recall.options.indices.contains(recall.answer) && Set(recall.options).count == recall.options.count, "Invalid explanation options")
    var practice = HeartMorphLearning.Practice(process: process)
    practice.explain(0)
    practice.observe(1)
    check(practice.phase == .predict && practice.explanation == nil, "Practice skipped prediction")
    practice.predict(-1, at: 0)
    check(practice.phase == .predict, "Invalid prediction accepted")
    practice.predict(0, at: 0.5)
    for _ in 0..<100 { practice.observe(0.51); practice.observe(0.49) }
    practice.observe(.nan)
    check(practice.phase == .observe, "Jitter/invalid observation unlocked explanation")
    practice.explain(recall.answer)
    check(practice.explanation == nil, "Explanation accepted before observing positions")
    practice.observe(0.25)
    check(practice.phase == .explain, "Reverse observation did not unlock explanation")
    practice.explain(100)
    check(practice.phase == .explain, "Invalid explanation accepted")
    practice.explain(recall.answer)
    check(practice.phase == .feedback && !practice.skipped, "Reasoned response was not recorded distinctly")
    practice.restart()
    check(practice.prediction == nil && practice.explanation == nil && practice.phase == .predict, "Retrieval restart leaked an answer")
    practice.reveal()
    check(practice.phase == .feedback && practice.skipped && practice.explanation == nil, "Skipped practice was scored as an answer")
}
print("PASS: prediction/observation/explanation gates, reverse comparison, jitter rejection and unscored reveal")

for layer in HeartTubeLayer.allCases {
    let move = HeartTubeLayer.boundedMove([100, -50, 30])
    check(simd_length(move) <= 0.040001, "Layer movement escaped its inspection envelope")
    let baseline = HeartTubeLayerGeometry.surface(progress: 0.4, opening: 1, separation: 1)
    let moved = HeartTubeLayerGeometry.surface(progress: 0.4, opening: 1, separation: 1, offsets: [layer.rawValue: move])
    let stride = baseline.positions.count / 3
    for i in baseline.positions.indices {
        let expected = i / stride == layer.rawValue ? move : .zero
        check(simd_distance(moved.positions[i] - baseline.positions[i], expected) < 0.000001, "Layer movement altered a neighbouring layer or distorted tissue")
    }
    check(moved.materials == baseline.materials && moved.triangles == baseline.triangles, "Moving layer changed its topology/identity")
}
check(HeartTubeLayer.boundedMove([.nan,0,0]) == .zero, "Invalid layer move accepted")
print("PASS: individually bounded layer movement preserves neighbours and surface identity")

let inspection = HeartMorphSession()
inspection.progress = 0.42; inspection.cutaway = true; inspection.layersSeparated = true
inspection.zoom = 1.7; inspection.yaw = 0.6
inspection.moveLayer([0.2, 0, 0])
let muscleMove = inspection.layerOffsets[HeartTubeLayer.myocardium.rawValue]
check(abs(simd_length(muscleMove ?? .zero) - 0.04) < 0.000001, "Session accepted an unbounded layer move")
inspection.selectLayer(.cardiacJelly)
check(inspection.isolatedLayer == nil, "Selecting a layer unexpectedly hid its neighbours")
inspection.isolatedLayer = .cardiacJelly
inspection.moveLayer([0, 0.006, 0])
inspection.selectLayer(.endocardium)
check(inspection.isolatedLayer == .endocardium, "Selection did not follow the isolated layer")
inspection.moveLayer([0, 0, -0.006])
inspection.resetLayerMove()
check(inspection.layerOffsets[HeartTubeLayer.endocardium.rawValue] == nil &&
      inspection.layerOffsets[HeartTubeLayer.myocardium.rawValue] == muscleMove &&
      inspection.layerOffsets[HeartTubeLayer.cardiacJelly.rawValue] == SIMD3<Float>(0, 0.006, 0),
      "Resetting one layer discarded another layer's arrangement")
inspection.isolatedLayer = nil
check(inspection.layersMoved && inspection.layersSeparated && inspection.cutaway &&
      inspection.progress == 0.42 && inspection.zoom == 1.7 && inspection.yaw == 0.6,
      "Showing all layers reset spatial or developmental context")
print("PASS: layer selection/isolation, independent recovery and retained inspection context")

for progress in [0.0, 0.4, 1] {
    for opening in [0.0, 0.5, 1] {
        let assembled = HeartOutflowGeometry.surface(progress: progress, opening: opening)
        check(assembled.componentRanges.count == 3 && assembled.componentRanges.flatMap(Array.init) == Array(assembled.positions.indices),
              "Outflow inspection components lost source vertices")
        for separation in [0.0, 0.25, 0.5, 1] {
            let separated = HeartOutflowGeometry.placing(assembled, separation: separation)
            check(separated.normals == assembled.normals && separated.triangles == assembled.triangles && separated.materials == assembled.materials,
                  "Outflow separation altered surface identity or lighting")
            for component in 0..<3 {
                let expected = SIMD3<Float>(component == 0 ? 0 : component == 1 ? -0.12 : 0.12, 0, 0) * Float(separation)
                for vertex in assembled.componentRanges[component] {
                    check(simd_distance(separated.positions[vertex] - assembled.positions[vertex], expected) < 0.000001,
                          "Outflow separation distorted an authored component")
                    check(simd_reduce_max(simd_abs(separated.positions[vertex])) < 0.3, "Separated outflow escaped its drawing envelope")
                }
            }
        }
        check(HeartOutflowGeometry.placing(assembled, separation: .nan).positions == assembled.positions &&
              HeartOutflowGeometry.placing(assembled, separation: -1).positions == assembled.positions,
              "Invalid outflow separation altered anatomy")
    }
}
print("PASS: outflow component separation preserves source shapes, normals, materials and bounded placement")

// Separating enclosing tissue retains an anatomical reference instead of
// translating every layer away from the learner's original point of interest.
check(HeartTubeLayer.endocardium.offset(separation: 1) == .zero, "Separation displaced the inner reference")
let muscleLift = HeartTubeLayer.myocardium.offset(separation: 1)
let jellyLift = HeartTubeLayer.cardiacJelly.offset(separation: 1)
check(simd_length(muscleLift) < 0.07 && simd_length(muscleLift) > simd_length(jellyLift), "Layer inspection lost its local outer-to-inner order")
check(muscleLift.z < jellyLift.z && jellyLift.z < 0, "Posterior inspection shells do not retain depth order")
check(HeartSpecimenPart.separationDirection(model: "Normal_Teenage_Heart", part: "Retopo_TN_Blood_Pool_0", index: 0, count: 2) == .zero, "Specimen separation displaced the inner blood-pool reference")
check(HeartSpecimenPart.separationDirection(model: "Unknown", part: "Unknown", index: 1, count: 3) == HeartSpecimenPart.separationDirection(index: 1, count: 3), "Unknown source groups received invented layer roles")
print("PASS: local layer separation retains the inner reference and source-identified shell roles")

// The default straight-tube cut must expose the lumen to the viewer, while
// leaving the posterior wall fixed. A side-facing slot concealed the layers.
let inspectionFrames = HeartLoopingGeometry.frames(progress: 0)
for opening in [0.0, 0.25, 0.5, 1] {
    let surface = HeartLoopingGeometry.surface(progress: 0, opening: opening)
    for ring in [0, 24, 48, 72, 96] {
        let frame = inspectionFrames[ring]
        let r = HeartLoopingGeometry.radius(Float(ring) / 96) * 0.1
        let centre = frame.centre * 0.1
        let back = surface.positions[ring * 49 + 24]
        check(simd_distance(back, centre - frame.dorsal * r) < 0.000001, "Opening displaced the posterior reference wall")
        if opening == 1 {
            let facing = surface.positions[(ring * 49)..<(ring * 49 + 49)].map { simd_dot($0 - centre, frame.dorsal) }.max()!
            check(facing <= r * 0.708, "Open wall still covers the viewer-facing lumen")
        }
    }
}
print("PASS: default cut exposes the lumen and preserves its posterior reference wall")

let layerDragOrientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
let layerDragOffset = HeartTubeLayer.draggedOffset(from: .zero, translation: [20, 0, 0], unitsPerPoint: 0.001, orientation: layerDragOrientation)
check(simd_distance(layerDragOrientation.act(layerDragOffset), [0.02, 0, 0]) < 0.000001, "Layer drag did not follow the viewing plane after rotation")
check(simd_length(HeartTubeLayer.draggedOffset(from: .zero, translation: [10000, -4000, 0], unitsPerPoint: 0.01, orientation: layerDragOrientation)) <= 0.040001, "Layer drag escaped its inspection envelope")
check(HeartTubeLayer.draggedOffset(from: layerDragOffset, translation: [.nan, 0, 0], unitsPerPoint: 0.001, orientation: layerDragOrientation) == layerDragOffset, "Invalid gesture moved a layer")
print("PASS: direct layer drag follows the viewing plane and remains bounded")

// Surface detail belongs to material coordinates, not world position. Moving
// and bending a layer must not slide its tissue finish across the anatomy.
for progress in [-1.0, -0.6, -0.001, 0, 0.2, 0.7, 1] {
    for opening in [0.0, 0.35, 1] {
        let original = HeartTubeLayerGeometry.surface(progress: progress, opening: opening, separation: 0)
        let moved = HeartTubeLayerGeometry.placing(original, separation: 1, offsets: [1: [0.01, 0.02, 0]])
        check(original.textureCoordinates.count == original.positions.count, "Tube detail has missing coordinates")
        check(original.textureCoordinates.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "Tube detail contains invalid coordinates")
        check(original.textureCoordinates == moved.textureCoordinates, "Layer inspection slides the surface finish")
    }
}
let straightDetail = HeartLoopingGeometry.surface(progress: 0, opening: 0).textureCoordinates
for progress in [0.1, 0.4, 0.8, 1] {
    check(HeartLoopingGeometry.surface(progress: progress, opening: 0).textureCoordinates == straightDetail,
          "Looping slides texture instead of carrying it with the wall")
}
for progress in [0.0, 0.4, 1] {
    for opening in [0.0, 0.35, 1] {
        let original = HeartOutflowGeometry.surface(progress: progress, opening: opening)
        let moved = HeartOutflowGeometry.placing(original, separation: 1)
        check(original.textureCoordinates.count == original.positions.count && original.textureCoordinates.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "Outflow detail has invalid coordinates")
        check(original.textureCoordinates == moved.textureCoordinates, "Outflow inspection slides the surface finish")
    }
}
print("PASS: morph surface coordinates remain complete, finite and attached through bending and separation")

for lesson in ["Atrial Septal Defect (ASD)", "Ventricular Septal Defect (VSD)"] {
    check(HeartGuidedAnatomy.opensAutomatically(lesson: lesson, step: 0, lastStep: 2, answerHidden: false), "Anomaly lesson still defaults to old schematic")
    check(!HeartGuidedAnatomy.opensAutomatically(lesson: lesson, step: 0, lastStep: 2, answerHidden: true), "Realistic anomaly bypassed an answer gate")
}
print("PASS: realistic anomaly entry preserves hidden-answer gates")

for pair in [(HeartDesignTokens.primary, HeartDesignTokens.surface),
             (HeartDesignTokens.secondary, HeartDesignTokens.surface),
             (HeartDesignTokens.primary, HeartDesignTokens.selected),
             (HeartDesignTokens.primary, HeartDesignTokens.panel),
             (HeartDesignTokens.surface, HeartDesignTokens.accent),
             (HeartDesignTokens.disabled, HeartDesignTokens.panel)] {
    check(HeartDesignTokens.contrast(pair.0, pair.1) >= 4.5, "UI text pair fails 4.5:1 contrast")
}
check(HeartDevelopmentStage.all.count == 8 && Set(HeartDevelopmentStage.all.map(\.id)).count == 8, "Development catalogue lost stage identity")
check(HeartDevelopmentStage.all[2].day == "Day 22" && HeartDevelopmentStage.all[3].day == "Days 23–28", "Stage labels reverted to the duplicated interval caption")
print("PASS: opaque UI contrast pairs and shared developmental stage identity")

// All three viewers route actual gestures through this same state machine.
let identityRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
var gesture = HeartManipulationSession()
let firstRotation = gesture.rotate(current: identityRotation, horizontal: 50, vertical: 30)
let repeatedRotation = gesture.rotate(current: firstRotation, horizontal: 50, vertical: 30)
check(simd_length(firstRotation.vector - repeatedRotation.vector) < 0.00001, "Repeated drag accumulated rotation")
let expectedRotation = HeartManipulationSession.rotated(from: identityRotation, horizontal: 50, vertical: 30)
check(simd_length(firstRotation.vector - expectedRotation.vector) < 0.00001, "Viewer rotation gain differs")
let pinchSize = gesture.resize(current: 1, magnification: 1.1)
check(abs(pinchSize - 1.1) < 0.00001, "Pinch did not use current size")
check(simd_length(gesture.rotate(current: firstRotation, horizontal: 200, vertical: 200).vector - firstRotation.vector) < 0.00001,
      "Pinch also rotated the model")
gesture.interrupt(active: true)
check(gesture.resize(current: 1, magnification: 2) == 1, "Active gesture undid reset size")
check(simd_length(gesture.rotate(current: identityRotation, horizontal: 200, vertical: 200).vector - identityRotation.vector) < 0.00001,
      "Active gesture undid reset pose")
gesture.finish()
let nextRotation = gesture.rotate(current: firstRotation, horizontal: -10, vertical: 5)
check(simd_length(nextRotation.vector - firstRotation.vector) > 0.001, "Fresh drag stayed locked after reset")
for vertical in [-900.0, 900.0] {
    let turned = HeartManipulationSession.rotated(from: identityRotation, horizontal: 0, vertical: Float(vertical))
    check(abs(simd_length(turned.vector) - 1) < 0.00001, "Large rotation lost normalization")
}
print("PASS: shared gesture gain, nonaccumulating drag, pinch ownership, reset interruption, fresh-gesture recovery, unrestricted rotation")
