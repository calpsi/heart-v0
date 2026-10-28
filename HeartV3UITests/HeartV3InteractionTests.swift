import XCTest

@MainActor final class HeartV3InteractionTests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "phil.heart-v3")
    }
    func open(_ arguments: [String] = []) {
        app.launchArguments = ["--ui-testing"] + arguments
        app.launch()
    }
    @discardableResult func tap(_ name: String, timeout: TimeInterval = 30) -> XCUIElement {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "Missing button: \(name)\n\(app.debugDescription)")
        XCTAssertTrue(button.wait(for: \.isEnabled, toEqual: true, timeout: timeout), "Disabled button: \(name)")
        button.tap()
        return button
    }
    func openMorph() {
        if !app.buttons["morph.learning"].waitForExistence(timeout: 2) { tap("learning.loopingMorph") }
    }
    func shown(_ text: String) {
        XCTAssertTrue(app.staticTexts[text].firstMatch.waitForExistence(timeout: 15), "Missing result: \(text)\n\(app.debugDescription)")
    }
    func dragSlider(_ name: String, by distance: CGFloat) {
        let sizing = name == "Morph size"
        if sizing { tap("morph.size") }
        let slider = app.sliders[name].firstMatch
        XCTAssertTrue(slider.waitForExistence(timeout: 30))
        XCTAssertTrue(slider.wait(for: \.isEnabled, toEqual: true, timeout: 30))
        let before = slider.value as? String
        let knob = slider.otherElements["AXSliderKnob"].firstMatch
        if knob.exists {
            let thumb = knob.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            thumb.press(forDuration: 0.2, thenDragTo: thumb.withOffset(CGVector(dx: distance, dy: 0)))
        } else {
            // UIKit exposes the slider itself, not SwiftUI's private AXSliderKnob.
            let target = min(1, max(0, slider.normalizedSliderPosition + distance / max(1, slider.frame.width - 32)))
            slider.adjust(toNormalizedSliderPosition: target)
        }
        XCTAssertNotEqual(slider.value as? String, before, "Slider did not respond: \(name)")
        if sizing { tap("morph.sizeDone") }
    }
    func testDirectRotationAcrossViewerFamilies() {
        continueAfterFailure = true
        let cases: [([String], String, String)] = [
            (["--preview-exploration", "--preview-stage", "0"], "tool.Reset view", "model.viewport"),
            (["--preview-guided", "--preview-lesson", "3", "--preview-step", "0"], "morph.resetView", "morph.viewport"),
            (["--preview-exploration", "--preview-whole-heart"], "reference.reset", "reference.ready")
        ]
        for (arguments, reset, viewportID) in cases {
            open(arguments)
            let viewport = app.descendants(matching: .any)[viewportID].firstMatch
            XCTAssertTrue(viewport.waitForExistence(timeout: 60), app.debugDescription)
            if arguments.contains("--preview-whole-heart") {
                XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            }
            let state = app.descendants(matching: .any)["interaction.state"].firstMatch
            XCTAssertTrue(state.waitForExistence(timeout: 10), app.debugDescription)
            let before = state.value as? String
            XCTAssertNotNil(before)
            print("Gesture baseline \(arguments): \(before ?? "missing")")
            XCTAssertGreaterThan(state.frame.width, 100, "Diagnostic must cover the viewport, not a tiny text label")
            XCTAssertGreaterThan(state.frame.height, 100)
            print("Gesture viewport \(viewport.frame), input region \(state.frame)")
            let center = state.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.press(forDuration: 0.2, thenDragTo: center.withOffset(CGVector(dx: 60, dy: 30)))
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in state.value as? String != before }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed, "Direct model drag did not change orientation: \(arguments)")
            tap(reset)
            XCTAssertEqual(state.value as? String, before, "Reset did not restore the initial model pose")
        }
    }

    func testEmbeddedComparisonHasUsableModelArea() {
        open(["--preview-exploration", "--preview-stage", "4"])
        tap("development.otherBranches")
        tap("Atrioventricular Septal Defect (AVSD)")
        let ready = app.descendants(matching: .any)["reference.ready"].firstMatch
        XCTAssertTrue(ready.waitForExistence(timeout: 60))
        XCTAssertGreaterThanOrEqual(ready.frame.height, 150, "Embedded anatomy collapsed beneath its controls")
        XCTAssertGreaterThan(ready.frame.width, 250)
        let controls = app.buttons["reference.section"]
        XCTAssertLessThanOrEqual(ready.frame.maxY, controls.frame.minY + 4, "Model layout overlaps its controls")
        tap("reference.parts")
        shown("Inspect parts")
        tap("Right")
        tap("Return part")
        tap("Done")
        tap("Return to development")
        shown("Septation begins")
    }

    func testRecognitionDoesNotRevealAnswerUntilRequested() {
        open(["--preview-guided", "--preview-anomaly", "4", "--preview-step", "1"])
        shown("Which segment has an abnormal channel width?")
        XCTAssertFalse(app.staticTexts["Aortic isthmus just beyond the left subclavian branch."].exists)
        XCTAssertFalse(app.buttons["recognition.commit"].isEnabled)
        XCTAssertFalse(app.buttons["tool.Parts"].isEnabled)
        tap("Show hint")
        shown("Follow the channel through the main arch and compare its width on either side of each branch.")
        tap("recognition.reveal")
        shown("Revealed")
        shown("Aortic isthmus just beyond the left subclavian branch.")
        tap("Practise again without labels")
        XCTAssertFalse(app.staticTexts["Aortic isthmus just beyond the left subclavian branch."].exists)
    }

    func testReviewPracticeKeepsAnswersHidden() {
        open(["--preview-guided", "--preview-anomaly", "4", "--preview-step", "1"])
        tap("recognition.reveal")
        tap("Lessons")
        tap("review.practice")
        shown("Which segment has an abnormal channel width?")
        XCTAssertFalse(app.staticTexts["Aortic isthmus just beyond the left subclavian branch."].exists)
        XCTAssertFalse(app.buttons["recognition.commit"].isEnabled)
    }

    func testLearningPilotPredictionAndRecall() {
        open(["--preview-guided", "--preview-lesson", "5", "--preview-step", "1"])
        shown("Optional knowledge check")
        XCTAssertFalse(app.staticTexts["learning.checkRationale"].exists)
        XCTAssertFalse(app.buttons["tool.Compare"].exists)
        XCTAssertFalse(app.buttons["learning.detailedAnatomy"].exists)
        tap("learning.option.0")
        shown("Compare your prediction with the model.")
        XCTAssertTrue(app.staticTexts["learning.checkRationale"].exists)
        tap("Next phase")
        shown("Compare the earlier and later arrangements.")
        tap("learning.detailedAnatomy")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Return to learning")
        shown("Phase 3 of 5")
        tap("Next phase")
        shown("Later anatomy · Typical heart")
        tap("learning.returnDevelopment")
        shown(HeartPilotTestText.explanation)
        tap("Next phase")
        shown("Optional knowledge check")
        XCTAssertFalse(app.staticTexts["learning.checkRationale"].exists)
        XCTAssertFalse(app.buttons["learning.detailedAnatomy"].exists)
        tap("learning.skipCheck")
        shown("Explanation viewed without an answer.")
        tap("Finish lesson")
    }

    func testDevelopmentConnectionReturnsToSameStage() {
        open(["--preview-exploration", "--preview-stage", "6"])
        tap("development.connection")
        shown("What changes?")
        shown("Why does it matter?")
        tap("Return to development")
        XCTAssertTrue(app.buttons["Stages 7/8"].exists)
    }

    func testDownloadedHeartModelsOpenAndSwitch() {
        open(["--preview-exploration"])
        tap("Heart anatomy")
        shown("See the anatomy you are learning to explain")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("reference.chooseModel")
        tap("reference.choose.Coarctation")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("reference.chooseModel")
        tap("reference.choose.Tetralogy_of_Fallot")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.staticTexts["reference.error"].exists)
        tap("Reset view")
        tap("Development")
        tap("Next developmental stage")
    }

    func testLoopingMorphScrubsAndResets() {
        open(["--preview-exploration", "--preview-stage", "2"])
        shown("From a tube to a loop")
        dragSlider("Developmental stage", by: 24)
        tap("Open wall")
        tap("Reset morph")
        shown("0%")
        tap("Next developmental stage")
        tap("development.morph")
        XCTAssertFalse(app.staticTexts["Scrub the developmental timeline below"].exists)
        tap("development.morph")
        shown("From a tube to a loop")
    }

    func testMorphViewResetPreservesDevelopmentAndWallInBothModes() {
        open(["--preview-exploration", "--preview-timeline", "2.4"])
        shown("40%")
        let initialSize = app.buttons["morph.size"].value as? String
        tap("Open wall")
        dragSlider("Morph size", by: 45)
        shown("40%")
        tap("morph.resetView")
        XCTAssertEqual(app.buttons["morph.size"].value as? String, initialSize)
        XCTAssertTrue(app.buttons["Close wall"].exists)
        shown("40%")

        open(["--preview-guided", "--preview-lesson", "3", "--preview-step", "0"])
        openMorph()
        dragSlider("Looping progression", by: 55)
        let progress = app.sliders["Looping progression"].value as? String
        tap("Open wall")
        dragSlider("Morph size", by: 45)
        tap("morph.resetView")
        XCTAssertEqual(app.sliders["Looping progression"].value as? String, progress)
        XCTAssertTrue(app.buttons["Close wall"].exists)
        tap("Return to lesson")
        shown("Phase 1 of 3")
    }

    func testSpecimenLoadingFailureCanRetry() {
        open(["--preview-exploration", "--preview-whole-heart", "--preview-reference-failure"])
        shown("This model could not be opened.")
        XCTAssertFalse(app.descendants(matching: .any)["reference.ready"].firstMatch.exists)
        XCTAssertFalse(app.buttons["reference.parts"].isEnabled)
        tap("Try again")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.staticTexts["reference.error"].exists)
        XCTAssertTrue(app.buttons["reference.parts"].isEnabled)
    }

    private func wallState(_ value: String) {
        let ready = expectation(for: NSPredicate(format: "value == %@", value), evaluatedWith: app.buttons["morph.wall"].firstMatch)
        wait(for: [ready], timeout: 5)
    }

    func testTubeLayersFollowMorphInBothModes() {
        for guided in [false, true] {
            open(guided ? ["--preview-guided", "--preview-lesson", "3", "--preview-step", "0"]
                        : ["--preview-exploration", "--preview-timeline", "2.4"])
            if guided { openMorph() }
            tap("Open wall")
            wallState("Open")
            tap("Separate layers")
            XCTAssertTrue(app.buttons["Reassemble layers"].exists)
            tap("morph.moveLayer")
            shown("Inspect one layer")
            tap("Endocardium")
            shown("Inner cell layer lining the blood channel")
            tap("Right"); tap("Nearer")
            tap("Isolate layer")
            tap("Done")
            shown("Only Endocardium")
            dragSlider(guided ? "Looping progression" : "Developmental stage", by: 18)
            XCTAssertTrue(app.buttons["Reassemble layers"].exists)
            XCTAssertFalse(app.staticTexts["morph.error"].exists)
            tap("About layers")
            shown("About this animation")
            shown("Cardiac jelly: Extracellular matrix between the two cell layers.")
            tap("Done")
            tap("morph.moveLayer")
            shown("Inner cell layer lining the blood channel")
            tap("Reset layer move")
            tap("Done")
            tap("morph.resetView")
            XCTAssertTrue(app.buttons["Reassemble layers"].exists)
            shown("Only Endocardium")
            tap("morph.showAllLayers")
            XCTAssertFalse(app.staticTexts["morph.isolatedLayer"].exists)
            XCTAssertTrue(app.buttons["Reassemble layers"].exists)
            tap("Reassemble layers")
            tap("Reset morph")
            shown("0%")
            XCTAssertTrue(app.buttons["Separate layers"].exists)
            if guided { tap("Return to lesson"); shown("Phase 1 of 3") }
        }
    }

    func testMorphInspectionSurvivesRepresentationChanges() {
        for guided in [false, true] {
            open(guided ? ["--preview-guided", "--preview-lesson", "3", "--preview-step", "0"]
                        : ["--preview-exploration", "--preview-timeline", "2.4"])
            if guided { openMorph(); dragSlider("Looping progression", by: 45) }
            let progressName = guided ? "Looping progression" : "Developmental stage"
            let position = app.sliders[progressName].value as? String
            tap("Open wall"); wallState("Open")
            tap("Separate layers")
            tap("morph.moveLayer"); tap("Cardiac jelly"); tap("Isolate layer"); tap("Done")
            dragSlider("Morph size", by: 35)
            let size = app.buttons["morph.size"].value as? String
            if guided {
                tap("Return to lesson"); shown("Phase 1 of 3"); openMorph()
            } else { tap("Heart anatomy"); tap("Development") }
            XCTAssertTrue(app.buttons["Reassemble layers"].waitForExistence(timeout: 15))
            wallState("Open")
            shown("Only Cardiac jelly")
            XCTAssertEqual(app.sliders[progressName].value as? String, position)
            XCTAssertEqual(app.buttons["morph.size"].value as? String, size)
            XCTAssertTrue(app.buttons["Play morph"].exists)
            XCTAssertFalse(app.staticTexts["morph.error"].exists)
            tap("Reset morph"); shown("0%")
            XCTAssertFalse(app.staticTexts["morph.isolatedLayer"].exists)
            XCTAssertTrue(app.buttons["Separate layers"].exists)
        }
    }

    func testMorphWallInspectionKeepsProgressAcrossModes() {
        open(["--preview-exploration", "--preview-timeline", "2.4"])
        shown("40%")
        for _ in 0..<2 {
            tap("Open wall")
            wallState("Open")
            shown("40%")
            tap("Close wall")
            wallState("Closed")
        }
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
        open(["--preview-guided", "--preview-lesson", "7", "--preview-step", "0"])
        openMorph()
        dragSlider("Outflow progression", by: 55)
        let progress = app.sliders["Outflow progression"].value as? String
        tap("Close wall")
        wallState("Closed")
        tap("Open wall")
        wallState("Open")
        XCTAssertEqual(app.sliders["Outflow progression"].value as? String, progress)
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
        tap("Return to lesson")
        shown("Phase 1 of 3")
    }

    func testMorphPredictionDoesNotRevealExplanation() {
        open(["--preview-exploration", "--preview-timeline", "1.2"])
        tap("morph.learning")
        shown("As the paired channels join, what should you look for?")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("morph.answer.1")
        shown("Prediction saved — now observe")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("Return to the animation")
        shown("From paired tubes to one channel")
        tap("Next developmental stage")
        tap("morph.learning")
        shown("As the tube bends, what happens to its continuity?")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("Return to the animation")
    }

    func testMorphPracticeRequiresObservationBeforeExplanation() {
        open(["--preview-guided", "--preview-lesson", "3", "--preview-step", "0"])
        openMorph()
        tap("morph.learning")
        tap("morph.answer.1")
        shown("Prediction saved — now observe")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("Return to the animation")
        tap("Return to lesson")
        openMorph()
        tap("morph.learning")
        shown("Prediction saved — now observe")
        XCTAssertFalse(app.buttons["morph.reason.0"].exists)
        tap("Return to the animation")
        dragSlider("Looping progression", by: 100)
        tap("Explain what changed")
        shown("Explain what you observed")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("morph.reason.0")
        shown("Your explanation matches the illustrated change")
        XCTAssertTrue(app.staticTexts["morph.explanation"].exists)
        tap("morph.practiceAgain")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("morph.skipPractice")
        shown("Explanation viewed without completing practice")
    }

    func testGuidedJoiningMorphReturnsToSamePhase() {
        open(["--preview-guided", "--preview-lesson", "1", "--preview-step", "0"])
        openMorph()
        shown("From paired tubes to one channel")
        dragSlider("Development progression", by: 90)
        tap("Reset morph")
        shown("0%")
        tap("Return to lesson")
        shown("Phase 1 of 3")
    }

    func testGuidedIntegratedAnatomyKeepsPhaseAndReturns() {
        open(["--preview-guided", "--preview-lesson", "6", "--preview-step", "2"])
        shown("Phase 3 of 3")
        shown("Later anatomy · Typical heart")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.buttons["tool.Parts"].exists)
        tap("Related anomaly")
        shown("Later anatomy · VSD")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("learning.specimenReset")
        tap("learning.returnDevelopment")
        shown("Phase 3 of 3")
        XCTAssertFalse(app.staticTexts["Later anatomy · VSD"].exists)
        tap("Later anatomy")
        shown("Later anatomy · Typical heart")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Previous step")
        shown("Phase 2 of 3")
        XCTAssertFalse(app.staticTexts["Later anatomy · Typical heart"].exists)
    }

    func testGuidedSpecimensRespectPredictionAndRetrieval() {
        open(["--preview-guided", "--preview-lesson", "5", "--preview-step", "1"])
        XCTAssertFalse(app.buttons["Later anatomy"].exists)
        tap("Next phase")
        shown("Phase 3 of 5")
        tap("Later anatomy")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Related anomaly")
        shown("Later anatomy · AVSD")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Next phase")
        shown("Phase 4 of 5")
        tap("Next phase")
        shown("Phase 5 of 5")
        XCTAssertFalse(app.buttons["Later anatomy"].exists)
        XCTAssertFalse(app.staticTexts["Later anatomy · AVSD"].exists)
        XCTAssertFalse(app.buttons["Related anomaly"].exists)
    }

    func testGuidedCoarctationSpecimenAfterExplanation() {
        open(["--preview-guided", "--preview-anomaly", "4", "--preview-step", "3"])
        shown("Phase 4 of 5")
        shown("Later anatomy · Typical heart")
        tap("Related anomaly")
        shown("Later anatomy · Coarctation")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Next phase")
        shown("Phase 5 of 5")
        XCTAssertFalse(app.buttons["Later anatomy"].exists)
        XCTAssertFalse(app.staticTexts["Later anatomy · Coarctation"].exists)
        XCTAssertTrue(app.buttons["recognition.commit"].waitForExistence(timeout: 15))
    }

    func testGuidedSpecimenReplaysOutflowAndReturns() {
        open(["--preview-guided", "--preview-lesson", "7", "--preview-step", "2"])
        shown("Later anatomy · Typical heart")
        tap("learning.specimenMorph")
        shown("From one outflow channel to two routes")
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
        tap("Return to lesson")
        shown("Phase 3 of 3")
        shown("Later anatomy · Typical heart")
        tap("Related anomaly")
        shown("Later anatomy · Tetralogy of Fallot")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
    }

    func testGuidedRepresentationPreservesDevelopmentalView() {
        open(["--preview-guided", "--preview-lesson", "6", "--preview-step", "1"])
        tap("tool.Separate")
        tap("tool.View")
        dragSlider("Model size", by: 45)
        let before = app.sliders["Model size"].firstMatch.value as? String
        tap("Done")
        tap("Later anatomy")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.buttons["tool.Separate"].exists)
        tap("Developmental view")
        shown("Phase 2 of 3")
        XCTAssertTrue(app.buttons["tool.Reassemble"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["tool.Reassemble"].firstMatch.value as? String, "On")
        tap("tool.View")
        XCTAssertEqual(app.sliders["Model size"].firstMatch.value as? String, before)
        tap("Done")
        tap("tool.Reassemble")
    }

    func testGuidedASDOpensDetailedModel() {
        open(["--preview-guided", "--preview-anomaly", "3", "--preview-step", "0"])
        tap("learning.detailedAnatomy")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Model info")
        XCTAssertTrue(app.staticTexts["reference.note.Atrial_Septal_Defect_ASD"].exists)
        tap("Done")
        tap("Return to learning")
        shown("Phase 1 of 3")
    }

    func testReferenceStyleAndRotationAcrossModels() {
        open(["--preview-exploration", "--preview-whole-heart", "--preview-reference", "Atrial_Septal_Defect_ASD"])
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.buttons["reference.appearance"].exists)
        tap("reference.rotation")
        XCTAssertEqual(app.buttons["reference.rotation"].label, "Pause rotation")
        tap("reference.reset")
        XCTAssertEqual(app.buttons["reference.rotation"].label, "Rotate model")
        tap("reference.rotation")
        for (name, id) in [("VSD", "Ventricular_Septal_Defect"),
                           ("Typical heart", "Normal_Teenage_Heart"),
                           ("AVSD", "Atrioventricular_septal_defect_4_chamber_view")] {
            tap("reference.chooseModel")
            tap("reference.choose." + id)
            shown(name)
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            XCTAssertFalse(app.buttons["reference.appearance"].exists)
            XCTAssertEqual(app.buttons["reference.rotation"].label, "Rotate model")
        }
        tap("Development")
    }

    func testOutflowTimelineAndAnomalyReturn() {
        open(["--preview-exploration", "--preview-timeline", "5.4"])
        shown("From one outflow channel to two routes")
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
        tap("Close wall"); tap("Open wall")
        tap("morph.learning")
        shown("As the opposing cushions meet, what changes inside the outflow channel?")
        XCTAssertFalse(app.staticTexts["morph.explanation"].exists)
        tap("morph.answer.0"); tap("Return to the animation")
        tap("development.otherBranches")
        tap("Transposition of the Great Arteries (TGA)")
        shown("During outflow division and ventricular alignment")
        tap("Return to development")
        shown("From one outflow channel to two routes")
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
        shown("40%")
        tap("Reset morph"); shown("0%")
        tap("Play morph")
        shown("100%")
        XCTAssertTrue(app.buttons["Play morph"].waitForExistence(timeout: 15))
        tap("Reset morph"); shown("0%")
        tap("development.morph")
        XCTAssertFalse(app.staticTexts["From one outflow channel to two routes"].exists)
        tap("development.morph")
        shown("From one outflow channel to two routes")
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
    }

    func testAVSDTimelineBranchLoadsReference() {
        open(["--preview-exploration", "--preview-stage", "4"])
        tap("development.otherBranches")
        tap("Atrioventricular Septal Defect (AVSD)")
        shown("During formation of the central AV junction")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.staticTexts["reference.error"].exists)
        let originalSize = app.sliders["Reference size"].value as? String
        dragSlider("Reference size", by: 40)
        let enlargedSize = app.sliders["Reference size"].value as? String
        tap("Explore another anatomical model")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Return to learning")
        XCTAssertTrue(app.sliders["Reference size"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.sliders["Reference size"].value as? String, enlargedSize)
        tap("reference.previewReset")
        XCTAssertEqual(app.sliders["Reference size"].value as? String, originalSize)
        tap("Return to development")
        XCTAssertTrue(app.buttons["Stages 5/8"].exists)
    }

    func testHeartV0StartsWithDevelopment() {
        open()
        shown("Welcome to HeartV0")
        tap("Free Exploration")
        shown("From paired tubes to one channel")
        XCTAssertTrue(app.buttons["Play morph"].exists)
        tap("Home")
        open(["--preview-guided", "--preview-lesson", "2", "--preview-step", "0"])
        shown("From a tube to a loop")
        shown("0%")
        XCTAssertTrue(app.buttons["Play morph"].exists)
        XCTAssertFalse(app.buttons["tool.Parts"].exists)
    }

    func testGuidedProcessJourneyConnectsToAnomaly() {
        open()
        tap("Guided Learning")
        XCTAssertFalse(app.buttons["learning.startProcess"].exists)
        open(["--preview-guided", "--preview-lesson", "1", "--preview-step", "0"])
        shown("From paired tubes to one channel")
        shown("Two channels · follow their inner borders as you move forward.")
        tap("Play morph")
        XCTAssertTrue(app.buttons["Play morph"].waitForExistence(timeout: 20))
        shown("100%")
        shown("One channel · scrub backwards to compare with the paired starting shape.")
        shown("From paired tubes to one channel")
        tap("Separate layers")
        tap("learning.nextProcess")
        shown("From a tube to a loop")
        shown("0%")
        XCTAssertTrue(app.buttons["Separate layers"].exists)
        tap("learning.nextProcess")
        shown("From one outflow channel to two routes")
        tap("morph.developmentBranch")
        shown("During outflow division and ventricular alignment")
        XCTAssertFalse(app.staticTexts["connection.difference"].exists)
        tap("connection.explain")
        XCTAssertTrue(app.staticTexts["connection.difference"].exists)
        tap("connection.replayProcess")
        shown("From one outflow channel to two routes")
        tap("Return to lesson")
        shown("Phase 1 of 3")
    }

    func testRealisticAnomaliesOpenFromBothModes() {
        for anomaly in [0, 1, 2, 3, 4] {
            open(["--preview-exploration", "--preview-anomaly", "\(anomaly)"])
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            XCTAssertTrue(app.buttons["reference.section"].exists)
            XCTAssertFalse(app.buttons["tool.Parts"].exists, "Anomaly route still opened the old schematic")
            let image = XCTAttachment(screenshot: app.screenshot())
            image.name = "Realistic free anomaly \(anomaly)"; image.lifetime = .keepAlways; add(image)
        }
        for anomaly in [0, 3] {
            open(["--preview-guided", "--preview-anomaly", "\(anomaly)", "--preview-step", "0"])
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            shown(anomaly == 0 ? "Later anatomy · VSD" : "Later anatomy · ASD")
            let image = XCTAttachment(screenshot: app.screenshot())
            image.name = "Realistic guided anomaly \(anomaly)"; image.lifetime = .keepAlways; add(image)
        }
        open(["--preview-guided", "--preview-lesson-list"])
        XCTAssertFalse(app.buttons["learning.startProcess"].exists)
        XCTAssertFalse(app.buttons["Follow development in 3D"].exists)
    }

    func testAuthoredDuctusAcrossModesAndBirthConnection() {
        open(["--preview-exploration", "--preview-anomaly", "5"])
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertTrue(app.descendants(matching: .any)["reference.ductalComparison"].firstMatch.exists)
        tap("reference.section")
        tap("Separate")
        tap("Reassemble")
        tap("Closed remnant")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Patent ductus")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        let patent = XCTAttachment(screenshot: app.screenshot())
        patent.name = "Authored PDA in free exploration"; patent.lifetime = .keepAlways; add(patent)

        open(["--preview-guided", "--preview-anomaly", "5", "--preview-step", "0"])
        shown("Later anatomy · Patent ductus")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Closed remnant")
        shown("Later anatomy · Closed remnant")
        tap("Patent ductus")
        shown("Later anatomy · Patent ductus")
        tap("learning.developmentContext")
        shown("At the transition after birth")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertFalse(app.staticTexts["connection.difference"].exists)
        tap("Closed remnant")
        tap("connection.explain")
        XCTAssertTrue(app.staticTexts["connection.difference"].exists)
        tap("Return to development")
        shown("Later anatomy · Patent ductus")
        shown("Phase 1 of 3")
    }

    func testDevelopmentAnomalyStaysOnTimeline() {
        open(["--preview-exploration", "--preview-timeline", "5.4"])
        shown("Partition forming · follow the remaining space on either side.")
        let position = app.sliders["Developmental stage"].value as? String
        tap("development.connection")
        shown("During outflow division and ventricular alignment")
        XCTAssertTrue(app.sliders["Developmental stage"].exists)
        XCTAssertEqual(app.sliders["Developmental stage"].value as? String, position)
        XCTAssertFalse(app.staticTexts["connection.difference"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Typical anatomy")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        tap("Related anomaly")
        tap("connection.explain")
        XCTAssertTrue(app.staticTexts["connection.difference"].exists)
        tap("connection.replayProcess")
        shown("40%")
        XCTAssertEqual(app.sliders["Developmental stage"].value as? String, position)
        tap("development.connection")
        tap("Previous developmental stage")
        XCTAssertFalse(app.buttons["connection.explain"].exists)
    }

    func testAnomalyLessonReplaysNormalProcessInPlace() {
        open(["--preview-guided", "--preview-anomaly", "2", "--preview-step", "0"])
        shown("During outflow division and ventricular alignment")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        XCTAssertTrue(app.buttons["connection.explain"].isHittable, "Explanation should be visible without scrolling")
        tap("connection.replayProcess")
        shown("Normal development · compare with the related anomaly")
        shown("From one outflow channel to two routes")
        tap("morph.developmentBranch")
        shown("Transposition of the Great Arteries (TGA)")
        XCTAssertFalse(app.staticTexts["connection.difference"].exists)
        tap("Return to development")
        shown("Normal development · compare with the related anomaly")
    }

    func testRecordingContrastAndToolLabels() {
        open(["--preview-guided", "--preview-lesson", "0", "--preview-step", "0"])
        shown("Cardiogenic C-Shape")
        let slice = app.buttons["model.section"]
        XCTAssertTrue(slice.waitForExistence(timeout: 30))
        XCTAssertGreaterThanOrEqual(slice.frame.width, 60)
        XCTAssertGreaterThanOrEqual(slice.frame.height, 60)
        tap("model.section")
        tap("Section · depth")
        let lesson = XCTAttachment(screenshot: app.screenshot())
        lesson.name = "Readable guided lesson and Slice tool"; lesson.lifetime = .keepAlways; add(lesson)
        open(["--preview-guided", "--preview-lesson-list"])
        tap("Heart anatomy")
        tap("reference.chooseModel")
        XCTAssertTrue(app.buttons["reference.choose.Tetralogy_of_Fallot"].exists)
        let chooser = XCTAttachment(screenshot: app.screenshot())
        chooser.name = "Full model selector labels"; chooser.lifetime = .keepAlways; add(chooser)
        tap("reference.choose.Tetralogy_of_Fallot")
        XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
        shown("Size")
        let anatomy = XCTAttachment(screenshot: app.screenshot())
        anatomy.name = "Readable anatomy workspace"; anatomy.lifetime = .keepAlways; add(anatomy)
    }

    func testAnimationInformationCanScrollAndDismiss() {
        open(["--preview-exploration", "--preview-timeline", "2.4"])
        tap("About layers")
        shown("About this animation")
        let done = app.buttons["Done"].firstMatch
        XCTAssertTrue(done.isHittable)
        let explanation = app.scrollViews.firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 10))
        explanation.swipeUp()
        XCTAssertTrue(done.isHittable, "Dismissal scrolled away with the long layer explanation")
        tap("Done")
        XCTAssertFalse(app.staticTexts["About this animation"].exists)
        XCTAssertTrue(app.buttons["Play morph"].isHittable)
    }

    func testFreeMorphControlsFitWindow() {
        for position in ["1.2", "2.4", "5.6"] {
            open(["--preview-exploration", "--preview-timeline", position])
            XCTAssertTrue(app.buttons["Play morph"].waitForExistence(timeout: 30))
            let window = app.windows.allElementsBoundByIndex.map(\.frame)
                .filter { !$0.isEmpty }.min { $0.width * $0.height < $1.width * $1.height }
            guard let window else { XCTFail("Missing application window"); return }
            for name in ["Home", "Play morph", "morph.size", "morph.resetView", "Previous developmental stage", "Next developmental stage"] {
                let button = app.buttons[name].firstMatch
                XCTAssertTrue(button.exists, "Missing control: \(name)")
                XCTAssertTrue(button.isHittable, "Unreachable control: \(name)")
                XCTAssertTrue(window.contains(button.frame), "Control outside window: \(name), \(button.frame) in \(window)")
            }
            let viewport = app.otherElements["morph.viewport"].firstMatch
            XCTAssertTrue(viewport.exists)
            XCTAssertGreaterThan(viewport.frame.height, 160, "Controls crowded out the model")
        }
    }

    func testOutflowPracticeAppliesToRelatedAnatomyInBothModes() {
        for guided in [false, true] {
            open(guided ? ["--preview-guided", "--preview-lesson", "7", "--preview-step", "0"]
                        : ["--preview-exploration", "--preview-timeline", "5.2"])
            tap("morph.learning")
            XCTAssertFalse(app.buttons["morph.applyConnection"].exists)
            tap("morph.answer.0")
            tap("Return to the animation")
            tap("Play morph")
            XCTAssertTrue(app.buttons["Play morph"].waitForExistence(timeout: 20))
            shown("100%")
            tap("morph.learning")
            shown("Explain what you observed")
            tap("morph.reason.2")
            tap("morph.applyConnection")
            shown("During outflow division and ventricular alignment")
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            XCTAssertFalse(app.staticTexts["connection.difference"].exists)
            tap("Return to development")
            shown("100%")
            tap("morph.learning")
            shown("Your explanation matches the illustrated change")
            tap("Return to the animation")
        }
    }

    func testGuidedOutflowMorphAndBranch() {
        open(["--preview-guided", "--preview-lesson", "7", "--preview-step", "0"])
        openMorph()
        shown("From one outflow channel to two routes")
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
        tap("morph.developmentBranch")
        shown("During outflow division and ventricular alignment")
        tap("connection.replayProcess")
        shown("From one outflow channel to two routes")
        tap("morph.developmentBranch")
        shown("During outflow division and ventricular alignment")
        tap("Return to development")
        shown("Phase 1 of 3")
    }

    func testOutflowInspectionPersistsAcrossBothModes() {
        for guided in [false, true] {
            open(guided ? ["--preview-guided", "--preview-lesson", "7", "--preview-step", "0"]
                        : ["--preview-exploration", "--preview-timeline", "5.4"])
            if guided { openMorph() }
            shown("From one outflow channel to two routes")
            tap("Separate components")
            tap("Close wall"); wallState("Closed")
            let progression = guided ? "Outflow progression" : "Developmental stage"
            dragSlider(progression, by: 12)
            let position = app.sliders[progression].value as? String
            tap("morph.resetView")
            XCTAssertTrue(app.buttons["Reassemble components"].exists)
            wallState("Closed")
            if guided { tap("Return to lesson"); openMorph() }
            else { tap("Heart anatomy"); tap("Development") }
            XCTAssertTrue(app.buttons["Reassemble components"].waitForExistence(timeout: 15))
            XCTAssertEqual(app.sliders[progression].value as? String, position)
            wallState("Closed")
            tap("Reassemble components")
            XCTAssertEqual(app.sliders[progression].value as? String, position)
            wallState("Closed")
            tap("Separate components"); tap("Reset morph")
            shown("0%")
            XCTAssertTrue(app.buttons["Separate components"].exists)
            wallState("Open")
            XCTAssertFalse(app.staticTexts["morph.error"].exists)
        }
    }

    func testUMCGModelsOpenAndSwitch() {
        open(["--preview-exploration"])
        tap("Heart anatomy")
        for name in ["Neonatal heart", "ASD", "VSD", "TGA", "AVSD"] {
            tap(name)
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            XCTAssertFalse(app.staticTexts["reference.error"].exists)
        }
        tap("Development")
    }

    func testSpecimenSectionsAndPartsAcrossModes() {
        for args in [["--preview-exploration", "--preview-whole-heart"],
                     ["--preview-guided", "--preview-lesson", "6", "--preview-step", "2"]] {
            open(args)
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            tap("reference.section")
            tap("Width")
            tap("Depth")
            XCTAssertFalse(app.staticTexts["reference.sectionError"].exists)
            shown("Geometric section: existing surfaces only. Missing walls and tissue layers are not reconstructed.")
            tap("reference.separate")
            XCTAssertTrue(app.buttons["reference.separate"].wait(for: \.label, toEqual: "Reassemble", timeout: 10))
            tap("reference.parts")
            shown("Inspect parts")
            tap("Right")
            tap("Nearer")
            tap("Return part")
            tap("Done")
            let sizeLabel = args.contains("--preview-guided") ? "Specimen size" : "Heart size"
            let originalSize = app.sliders[sizeLabel].value as? String
            dragSlider(sizeLabel, by: 40)
            tap(args.contains("--preview-guided") ? "learning.specimenReset" : "reference.reset")
            XCTAssertEqual(app.sliders[sizeLabel].value as? String, originalSize)
            shown("Geometric section: existing surfaces only. Missing walls and tissue layers are not reconstructed.")
            XCTAssertEqual(app.buttons["reference.separate"].label, "Reassemble")
            tap("reference.separate")
            XCTAssertTrue(app.buttons["reference.separate"].wait(for: \.label, toEqual: "Separate", timeout: 10))
            shown("Geometric section: existing surfaces only. Missing walls and tissue layers are not reconstructed.")
            dragSlider(sizeLabel, by: 40)
            let enlargedSize = app.sliders[sizeLabel].value as? String
            tap("reference.separate")
            tap("reference.restoreModel")
            XCTAssertFalse(app.staticTexts["Geometric section: existing surfaces only. Missing walls and tissue layers are not reconstructed."].exists)
            XCTAssertEqual(app.buttons["reference.separate"].label, "Separate")
            XCTAssertEqual(app.sliders[sizeLabel].value as? String, enlargedSize)
            if args.contains("--preview-guided") { shown("Phase 3 of 3") }
        }
    }

    func testStaticViewportKeepsCaptionClearAcrossLessonChanges() {
        open(["--preview-guided", "--preview-lesson", "0", "--preview-step", "0"])
        func checkStage() {
            let stage = app.descendants(matching: .any)["model.viewport"].firstMatch
            let caption = app.staticTexts["model.interactionStatus"].firstMatch
            XCTAssertTrue(stage.waitForExistence(timeout: 30), app.debugDescription)
            XCTAssertTrue(caption.waitForExistence(timeout: 10))
            XCTAssertGreaterThanOrEqual(stage.frame.height, 180, "Lesson chrome squeezed the model stage")
            XCTAssertGreaterThan(stage.frame.width, 250)
            XCTAssertLessThan(stage.frame.maxY, caption.frame.minY, "Viewport overlaps its caption")
        }
        checkStage()
        tap("Next phase")
        shown("Phase 2 of 3")
        checkStage()
        tap("Hide lesson")
        checkStage()
        tap("Show lesson")
        tap("Reset model")
        checkStage()
        tap("Lessons")
        tap("Cardiogenic region")
        checkStage()
    }

    func testLessonSectionRestoreAndPartTools() {
        open(["--preview-guided", "--preview-lesson", "6", "--preview-step", "1"])
        tap("model.section")
        tap("Section · width")
        XCTAssertFalse(app.staticTexts["model.sectionError"].exists)
        tap("Move parts")
        shown("Rotate")
        tap("Separate")
        shown("Reassemble")
        tap("Reset model")
        shown("Separate")
        shown("Phase 2 of 3")
    }

    func testHeartAnatomySubsectionInBothModes() {
        open()
        XCTAssertFalse(app.buttons["home.wholeHeart"].exists)
        for mode in ["Free Exploration", "Guided Learning"] {
            tap(mode)
            tap("Heart anatomy")
            shown("HEART ANATOMY")
            shown("Typical heart")
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            XCTAssertFalse(app.buttons["Return to learning"].exists)
            XCTAssertFalse(app.links.matching(NSPredicate(format: "label CONTAINS 'CC BY'")).firstMatch.exists)
            tap("reference.chooseModel")
            tap("reference.choose.Atrial_Septal_Defect_ASD")
            shown("ASD")
            tap("Model info")
            shown("reference.note.Atrial_Septal_Defect_ASD")
            tap("Done")
            XCTAssertTrue(app.descendants(matching: .any)["reference.ready"].firstMatch.waitForExistence(timeout: 60))
            tap("Development")
            tap("Home")
        }
    }

    func testAnatomySubsectionPreservesTimeline() {
        open(["--preview-exploration", "--preview-timeline", "2.4"])
        shown("40%")
        tap("Heart anatomy")
        shown("HEART ANATOMY")
        tap("Development")
        shown("40%")
        shown("From a tube to a loop")
        XCTAssertFalse(app.staticTexts["morph.error"].exists)
    }

    func testBottomTimelineDrivesLoopingMorph() {
        open(["--preview-exploration", "--preview-timeline", "2.4"])
        shown("From a tube to a loop")
        XCTAssertTrue(app.sliders["Developmental stage"].exists)
        XCTAssertFalse(app.sliders["Looping progression"].exists)
        dragSlider("Developmental stage", by: 24)
        tap("exploration.investigate")
        tap("Done")
        tap("Next developmental stage")
        shown("100%")
        XCTAssertTrue(app.sliders["Developmental stage"].exists)
        tap("Open wall")
        tap("Previous developmental stage")
        tap("Previous developmental stage")
        shown("From paired tubes to one channel")
        XCTAssertFalse(app.buttons["Open wall"].isEnabled)
        tap("Next developmental stage")
        shown("From a tube to a loop")
        XCTAssertTrue(app.buttons["Close wall"].isEnabled)
        wallState("Open")
        tap("Reset morph")
        shown("0%")
        tap("Play morph")
        XCTAssertTrue(app.buttons["Play morph"].waitForExistence(timeout: 30))
        shown("100%")
        tap("Next developmental stage")
        XCTAssertFalse(app.otherElements["morph.viewport"].exists)
    }

    func testGuidedLoopingTransitionReturnsToLesson() {
        open(["--preview-guided", "--preview-lesson", "3", "--preview-step", "0"])
        openMorph()
        shown("From a tube to a loop")
        dragSlider("Looping progression", by: 90)
        tap("Return to lesson")
        XCTAssertTrue(app.buttons["learning.loopingMorph"].exists)
        shown("Phase 1 of 3")
        tap("Next phase")
    }

    func testHiddenLessonNarrationKeepsCheckAnswerConcealed() {
        open(["--preview-guided", "--preview-lesson", "5", "--preview-step", "1"])
        tap("Hide lesson")
        shown("Knowledge check")
        tap("Play narration")
        tap("Pause narration")
        XCTAssertTrue(app.buttons["Resume narration"].exists)
        tap("Show lesson")
        XCTAssertFalse(app.staticTexts["learning.checkRationale"].exists)
        XCTAssertFalse(app.buttons["learning.detailedAnatomy"].exists)
        tap("learning.skipCheck")
        XCTAssertTrue(app.staticTexts["learning.checkRationale"].exists)
    }

    func testCoarctationNormalReferenceFirst() {
        open(["--preview-guided", "--preview-anomaly", "4", "--preview-step", "0"])
        shown("Inspect the open aortic arch and its branches.")
        tap("Next phase")
        shown("Which segment has an abnormal channel width?")
        XCTAssertFalse(app.buttons["tool.Parts"].isEnabled)
        tap("recognition.reveal")
        tap("Next phase")
        shown("Compare the same aortic segment at the same viewpoint.")
        tap("Next phase")
        shown("The narrowed channel can obstruct blood flow through the aorta.")
        tap("Next phase")
        shown("Recognise again")
        XCTAssertFalse(app.buttons["tool.Parts"].isEnabled)
        tap("Next phase")
    }

    func testSeparateReassembleAfterZoom() {
        open(["--preview-exploration", "--preview-stage", "1", "--preview-zoom", "1.4"])
        tap("tool.Reset view")
        tap("tool.Cutaway")
        for _ in 0..<3 {
            tap("tool.Separate")
            XCTAssertTrue(app.buttons["tool.Reassemble"].isEnabled)
            tap("tool.Reassemble")
            XCTAssertTrue(app.buttons["tool.Separate"].isEnabled)
        }
        tap("tool.Reset model")
        tap("Home")
    }

    func testOptionalInvestigationCanBeDismissed() {
        open(["--preview-exploration"])
        tap("exploration.investigate")
        shown("Optional investigation")
        tap("Done")
        tap("tool.Reset view")
        tap("Next developmental stage")
        tap("exploration.investigate")
        shown("Follow each paired channel. What relationship would you compare with the next stage?")
        tap("Done")
    }

    func testSourcesReturnToModel() {
        open(["--preview-exploration"])
        tap("Model info")
        shown("Anatomical validation incomplete")
        tap("Sources and attribution")
        shown("Explore the science")
        tap("Done")
        tap("tool.Reset view")
        shown("FREE EXPLORATION")
    }

    func testFullResetAndUndo() {
        open(["--preview-exploration", "--preview-stage", "0", "--preview-detached", "--preview-zoom", "2.5"])
        tap("tool.Reset model")
        XCTAssertFalse(app.buttons["tool.Return part"].isEnabled)
        tap("tool.Undo")
        XCTAssertTrue(app.buttons["tool.Return part"].wait(for: \.isEnabled, toEqual: true, timeout: 10))
        tap("tool.Reset model")
        XCTAssertFalse(app.buttons["Close-up"].exists)
        tap("tool.Reset view")
        tap("Home")
    }

    func testHomeNavigationAndReferences() {
        open()
        tap("References"); shown("Explore the science"); tap("Done")
        tap("Free Exploration"); shown("FREE EXPLORATION"); tap("Home")
        tap("Guided Learning"); shown("Follow the heart from its first cells to birth."); tap("Home")
        XCTAssertTrue(app.buttons["Free Exploration"].firstMatch.exists)
    }
    func testExplorationPanelsAndIsolation() {
        open(["--preview-exploration"])
        tap("tool.Parts"); shown("Anatomy")
        tap("Whole model")
        tap("tool.Parts"); tap("part.CardiogenicCrescent")
        tap("tool.Isolate")
        XCTAssertTrue(app.buttons["tool.Show all"].waitForExistence(timeout: 10))
        tap("tool.Parts"); tap("part.whole")
        XCTAssertFalse(app.buttons["tool.Isolate"].firstMatch.isEnabled)
        tap("tool.Parts"); tap("part.CardiogenicCrescent")
        tap("tool.Isolate"); tap("tool.Show all")
        tap("tool.View"); shown("View controls")
        // Simulator screenshots are captured with simctl outside XCTest; the
        // visionOS remote automation interface may not support app.screenshot().
        for title in ["Part label", "Orientation cue", "Model backdrop", "Transparent surroundings", "Surrounding tissue"] {
            let toggle = app.switches[title].firstMatch
            XCTAssertTrue(toggle.exists, "Missing view switch: \(title)")
            let before = toggle.value as? String
            toggle.tap()
            XCTAssertNotEqual(toggle.value as? String, before, "Switch did not change: \(title)")
            toggle.tap()
            XCTAssertEqual(toggle.value as? String, before)
        }
        tap("View side"); tap("Opposite"); tap("Cranial"); tap("Done")
        tap("tool.Separate"); XCTAssertTrue(app.buttons["tool.Reassemble"].waitForExistence(timeout: 10))
        tap("tool.Reassemble"); tap("tool.Reset view")
        tap("tool.Move parts"); tap("tool.Rotate")
        tap("Location"); shown("Location guide"); tap("Done")
        tap("Model info"); shown("About this model"); tap("Done")
        XCTAssertFalse(app.buttons["Close-up"].exists)
    }
    func testDevelopmentAndAnomalyNavigation() {
        open(["--preview-exploration"])
        for _ in 0..<7 { tap("Next developmental stage") }
        XCTAssertFalse(app.buttons["Next developmental stage"].firstMatch.isEnabled)
        for _ in 0..<7 { tap("Previous developmental stage") }
        XCTAssertFalse(app.buttons["Previous developmental stage"].firstMatch.isEnabled)
        tap("Stages 1/8"); shown("Developmental stages"); tap("Day 22, Primitive heart tube")
        tap("Anomalies"); tap("All anomalies"); tap("Done")
        for _ in 0..<5 { tap("Next anomaly") }
        XCTAssertFalse(app.buttons["Next anomaly"].firstMatch.isEnabled)
        for _ in 0..<5 { tap("Previous anomaly") }
        tap("Development")
    }
    func testGuidedPhasesAndRecovery() {
        open(["--preview-guided", "--preview-lesson", "8", "--preview-step", "0"])
        tap("Phase 3 of 3: Later Valve Tissue Layers")
        XCTAssertTrue(app.buttons["Finish lesson"].exists)
        tap("Phase 1 of 3: AV Leaflet Delamination")
        XCTAssertFalse(app.buttons["Previous step"].firstMatch.isEnabled)
        tap("Hide lesson"); tap("Next step"); tap("Previous step"); tap("Show lesson")
        tap("Show narration"); shown("NARRATION"); tap("Hide narration")
        tap("Play narration"); tap("Pause narration"); tap("Resume narration"); tap("Pause narration")
        tap("Resume narration"); tap("Next phase"); tap("Pause narration")
        tap("tool.Focus"); XCTAssertTrue(app.buttons["tool.Show all"].waitForExistence(timeout: 10))
        tap("tool.Show all"); tap("tool.Separate"); tap("tool.Reassemble")
        tap("tool.Restore step"); tap("tool.Reset view")
        tap("Next phase"); tap("Finish lesson")
        shown("Follow the heart from its first cells to birth.")
    }
    func testEveryLessonCanAdvanceAndFinish() {
        for category in ["--preview-lesson", "--preview-anomaly"] {
            for lesson in 0..<(category == "--preview-lesson" ? 10 : 6) {
                open(["--preview-guided", category, String(lesson), "--preview-step", "0"])
                tap("Hide lesson")
                for _ in 0..<12 {
                    let finish = app.buttons["Finish lesson"].firstMatch
                    if finish.exists { finish.tap(); break }
                    tap("Next step")
                }
                shown("Follow the heart from its first cells to birth.")
            }
        }
    }

    func testLessonCatalogueAndAtlas() {
        open(["--preview-guided", "--preview-lesson-list"])
        tap("Cardiogenic region"); tap("Lessons")
        tap("Anomalies"); tap("Ventricular Septal Defect (VSD)"); tap("Lessons")
        tap("Development"); tap("Home")
        tap("Free Exploration"); tap("Stage reconstructions")
        shown("Human embryonic heart atlas")
        tap("atlas.stage"); tap("Carnegie stage 20 · N913")
        tap("tool.Parts"); shown("Anatomy"); tap("part.whole")
        tap("tool.Separate"); tap("tool.Reassemble")
        tap("Done")
        shown("FREE EXPLORATION")
    }

    func testCutawaySearchAndSliders() {
        open(["--preview-exploration", "--preview-stage", "1"])
        tap("development.morph")
        tap("tool.Cutaway"); tap("tool.Cutaway")
        tap("tool.Parts")
        let search = app.textFields["Find a tissue or region"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("no-such-tissue")
        tap("Clear search"); tap("part.Myocardium_L_Posterior")
        tap("tool.Isolate"); tap("tool.View")
        dragSlider("Part separation", by: 90)
        dragSlider("Model size", by: -45)
        tap("Done")
        XCTAssertTrue(app.buttons["tool.Isolate"].exists)
        tap("tool.Reassemble"); tap("tool.Reset view")
        tap("tool.View")
        dragSlider("Model size", by: 160)
        tap("Done")
        tap("tool.Reset view")
    }

    func testLayerCompareAndDetachedPartRecovery() {
        open(["--preview-guided", "--preview-lesson", "8", "--preview-step", "1"])
        tap("tool.Layers")
        XCTAssertTrue(app.buttons["tool.Reassemble"].exists)
        tap("tool.Compare")
        tap("tool.Restore step")
        tap("tool.View"); tap("Restore step view")

        open(["--preview-exploration", "--preview-detached"])
        tap("tool.Return part")
        XCTAssertFalse(app.buttons["tool.Return part"].isEnabled)
        tap("tool.Rotate")

        open(["--preview-exploration", "--preview-detached"])
        tap("tool.Reassemble")
        XCTAssertFalse(app.buttons["tool.Return part"].isEnabled)
    }

    func testTransitionClarityAndLearningProgress() {
        open(["--preview-exploration", "--preview-stage", "7"])
        shown("Before birth: two connections let blood bypass the lungs")
        tap("transition.ForamenFlap_Fetal")
        tap("transition.Ductus_Fetal")
        tap("After birth · transitioning")
        shown("After birth: lung flow increases; the two connections begin closing")
        tap("transition.Ductus_Transition")
        tap("transition.ForamenFlap_Transition")
        tap("transition.Lung_R"); tap("transition.Aorta")
        open(["--preview-guided", "--preview-lesson-list"])
        XCTAssertTrue(app.staticTexts["learning.overallProgress"].exists)
        open(["--preview-guided", "--preview-lesson", "0", "--preview-step", "0"])
        XCTAssertTrue(app.staticTexts["learning.phaseProgress"].waitForExistence(timeout: 20))
        tap("Hide lesson")
        XCTAssertEqual(app.staticTexts["learning.phaseProgress"].label, "Phase 1 of 3")
        tap("Next step")
        XCTAssertEqual(app.staticTexts["learning.phaseProgress"].label, "Phase 2 of 3")
    }

}

private enum HeartPilotTestText {
    static let explanation = "Fusion of the superior and inferior cushions divides the common AV canal into separate left and right atrioventricular openings."
}
