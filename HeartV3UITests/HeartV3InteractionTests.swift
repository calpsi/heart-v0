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
    func shown(_ text: String) {
        XCTAssertTrue(app.staticTexts[text].firstMatch.waitForExistence(timeout: 15), "Missing result: \(text)\n\(app.debugDescription)")
    }
    func dragSlider(_ name: String, by distance: CGFloat) {
        let slider = app.sliders[name].firstMatch
        XCTAssertTrue(slider.waitForExistence(timeout: 30))
        XCTAssertTrue(slider.wait(for: \.isEnabled, toEqual: true, timeout: 30))
        let before = slider.value as? String
        let knob = slider.otherElements["AXSliderKnob"].firstMatch
        XCTAssertTrue(knob.exists, "Missing slider thumb: \(name)")
        let thumb = knob.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        thumb.press(forDuration: 0.2, thenDragTo: thumb.withOffset(CGVector(dx: distance, dy: 0)))
        XCTAssertNotEqual(slider.value as? String, before, "Slider did not respond: \(name)")
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
        let viewControls = XCTAttachment(screenshot: app.screenshot())
        viewControls.name = "View controls outside the model"
        viewControls.lifetime = .keepAlways
        add(viewControls)
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
        tap("Close-up"); tap("Close 3D close-up")
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
        tap("Close-up")
        dragSlider("Close-up model size", by: 45)
        tap("closeUp.focus"); tap("closeUp.showAll")
        tap("Close 3D close-up")
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
        XCTAssertFalse(app.buttons["tool.Return part"].exists)
        tap("tool.Rotate")

        open(["--preview-exploration", "--preview-detached", "--preview-close-up"])
        tap("Return selected part")
        XCTAssertFalse(app.buttons["Return selected part"].firstMatch.isEnabled)
        tap("Close 3D close-up")
        // The close-up is an independent inspection snapshot; the overview
        // retains its detached part until its own Reassemble action.
        tap("Close-up"); tap("Reassemble")
        XCTAssertFalse(app.buttons["Reassemble"].firstMatch.isEnabled)
        tap("Close 3D close-up")
        tap("tool.Reassemble")
        XCTAssertFalse(app.buttons["tool.Return part"].exists)
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
        let clarity = XCTAttachment(screenshot: app.screenshot())
        clarity.name = "Circulatory transition reading key"
        clarity.lifetime = .keepAlways
        add(clarity)
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
