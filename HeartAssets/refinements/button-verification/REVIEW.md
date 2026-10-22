# Interaction verification — 22 October 2026

## Result
All eight authored Xcode UI scenarios have passed on the visionOS 27 simulator. The final two-test run completed with zero failures. The live RealityView regression run at 01:28 passed all 23 assets and 429 isolated-part pivot checks.

UI coverage includes Home and References; both learning modes; eight developmental stages and six anomalies; all 16 lesson completions with 36 forward phase actions; direct phase selection; captions and narration across phase changes; Parts and search; isolation and whole-model recovery; View switches and presets; separation and size sliders; close-up resizing, focus and dismissal; Layers, Compare and Restore step; manual-part return and reassembly; catalogue and atlas selection.

## Implemented fixes
- Parts and View use anchored popovers outside the model's tool rail.
- Part rows, lesson cards and stage/anomaly cards have full-area hit targets.
- Whole model clears isolation. Separation exits isolation and manual movement; Reassemble clears detached offsets and restores the complete model.
- Close-up dismissal stays available while loading or after a loading error.
- Narration ignores callbacks from an older utterance after a phase change.
- Existing quaternion drag and isolated-part pivot fixes passed runtime regression checks.
- UI tests have stable control identifiers and an isolated progress store. Original simulator lesson progress was restored after the initial test changed it.

## Evidence
- `ui-summary.json`: latest successful result for each scenario and its log.
- `final-ui-test.log`: close-up/slider and detached-part recovery tests, zero failures.
- `runtime-validation.json`: fresh 22 October live asset/rotation results.
- `view-controls.png`: View panel placed outside the model.
- Earlier logs retain initial test failures and simulator/locked-Mac interruptions for traceability; final successful runs supersede them.

This verifies the tested simulator paths. Physical-headset eye/hand input and anatomical correctness are separate checks; this interaction pass is not a claim that the entire app is 95% complete or that every possible gesture combination was tested.
