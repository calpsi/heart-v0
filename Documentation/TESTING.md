# Reproducing regression checks

From the repository root:

```sh
sh Tests/run-policy-tests.sh
```

This compiles the production resize and assessment state code with a standalone Swift runner. It covers 20,000 resize samples and assessment persistence, invalid selection, wrong-region feedback, hint/reveal/retry and prior-study distinctions. It also checks review due dates, session deduplication, confidence/assistance intervals and the separation of same-day repetition from later recall.

For app/UI validation, use Xcode's `HeartV3InteractionTests` scheme on a visionOS simulator. Added tests include `testFullResetAndUndo`, `testRecognitionDoesNotRevealAnswerUntilRequested`, `testReviewPracticeKeepsAnswersHidden` and `testSourcesReturnToModel`. The first verifies reset/undo starting with a detached part at maximum zoom and confirms there is no Close-up action. Existing tests cover navigation, state comparisons, guided recovery, sliders and all lesson progression.

Launch a Debug build with `--preview-exploration --validate-heart-assets` to run compiled-asset checks inside a live RealityView. Read the app container's `Documents/heart-asset-validation.json`. Use its modification time to ensure the report comes from the current run. The checks load 16 teaching assets and seven reference assets and exercise state visibility, isolation, part movement, transforms, step restoration, fit bounds, serialization, separation cancellation saved lesson progress, and invariant scale/centre/depth across comparison states.

Following the 23 October recording, tests require the renderer to preserve the requested 0.4–2.5× scale relative to its fitted baseline. They also require the nearest model surface to stay behind controls and the farthest surface ahead of the backdrop. The RealityView clips enlarged anatomy to its viewport; this needs visual and headset checking as well as entity geometry tests. The birth-transition opacity assertion was corrected to preserve the existing reading-key dimming; the app's opacity behavior was not changed.

Simulator tests do not verify physical hand tracking, angular readability, OS window placement, ergonomics, or clinical/educational effectiveness. See HEADSET_ACCEPTANCE.md.

Use `-test-timeouts-enabled YES -maximum-test-execution-time-allowance 180` for targeted reruns if simulator activation stalls. Keep the all-lesson progression check on its longer default allowance. Screenshot capture is performed with simctl outside XCTest because the visionOS remote automation interface may not support app.screenshot(). Simulator activation/capture failures are recorded separately from application assertion failures.

## Research-informed pilot verification — 24 October 2026

Six unique targeted UI checks passed across the initial and final runs (eight successful executions): normal-first coarctation, optional prediction/recall, dismissible investigation prompts, concealed recognition answers, direct review entry, and three repeated separation/reassembly cycles. The final live validation passed all 16 teaching and seven reference assets, including the saved-progress migration assertion. Portable resize/assessment/scheduling tests passed. Results: verification/research-pilot-tests.txt, research-pilot-assets.json and research-pilot-policy.txt.

Presentation: the separate ready-for-footage PPTX passed package integrity, layout checks and import validation. All eleven source slide positions and exact titles were checked; original NUS logo bytes are retained. No videos are embedded, per the user's final instruction. Slides 7/8 are editable footage spaces. The 174-second timing plan includes the user's future recordings. See verification/research-deck.json. Native PowerPoint playback was not tested.

## Development-first increment — 24 October 2026

Final targeted simulator run: 4/4 passed, no failures, 103.941 seconds:
- testDevelopmentConnectionReturnsToSameStage
- testDownloadedHeartModelsOpenAndSwitch (typical heart, coarctation, Fallot)
- testLoopingMorphScrubsAndResets
- testRecognitionDoesNotRevealAnswerUntilRequested

Additional concealed-check narration test passed in the initial run (27.662 seconds). The initial run had three failures, repaired before the final rerun; retained logs show both results. Portable tests pass including 20,000 resize samples and 9,797 morph centre/frame/continuity checks. These checks do not prove anatomical fidelity or absence of every surface intersection.

Imported heart geometry was separately opened in Blender with script execution disabled. Source meshes/materials remain unchanged. Typical-heart simulator rendering was visually inspected; headset quality/performance and full-timeline transitions remain unverified/incomplete respectively.

Looping layout follow-up: testLoopingMorphScrubsAndResets passed after the dedicated control-panel adjustment. testGuidedLoopingTransitionReturnsToLesson also passed on the final build. Logs: looping-controls-test.txt and guided-looping-test.txt. The earlier looping-layout-final-test.txt contains the failed slider drag and is retained as evidence, not a passing result.

## Home orientation and bottom timeline

The initial bottom-timeline and full development/anomaly navigation run passed both checks (122.915 seconds), recorded in verification/bottom-timeline-tests.txt.

Final build after the endpoint-navigation correction: all three targeted UI tests passed, no failures, 88.260 seconds. These cover Home → whole-heart load → Home → exploration, bottom-timeline morph scrubbing and popup return, and guided morph → original lesson → next phase. See verification/home-timeline-final-tests.txt.

Portable resize, assessment, scheduling, morph and timeline tests passed, including endpoint navigation in both directions: verification/timeline-endpoint-policy.txt. Full-timeline geometry remains incomplete and physical headset interaction/performance remains unverified.

After the visual placement correction, the bottom timeline test passed again. The guided test initially failed because earlier runs had persisted the final phase, where “Next phase” correctly becomes “Finish lesson”. The test now selects phase 1 explicitly and asserts that returning from the morph preserves phase 1. Its rerun passed (29.124 seconds): verification/morph-guided-deterministic-test.txt. The failed run is retained in morph-placement-tests.txt.

Visually inspected verification/bottom-timeline-placement.png at 70% looping: the tube sits inside the model area, clear of its description and controls. The earlier bottom-timeline-final.png records the overlapping placement before correction; it is not final visual evidence. This single simulator view does not replace checks of rotation, window resizing and headset reach.

## Persistent morph endpoints and deformed-surface shading

All three targeted UI tests passed (97.862 seconds, zero failures): timeline scrub → endpoint → open wall → reset → play to endpoint → leave interval; guided morph → original phase; exploration reset and detailed-anatomy switching. See verification/morph-continuity-tests.txt. Portable checks passed including 42 full closed/cutaway meshes with stable triangle connectivity, finite unit normals and noncollapsed triangles: verification/morph-surface-policy-final.txt. Self-intersections and anatomical fidelity are not certified by these checks.

## Paired-tube joining — 25 October

Three UI checks passed (118.173 seconds, zero failures): shared timeline playback across joining and looping, reset/open-wall behaviour, and guided looping return. See verification/fusion-interaction-tests.txt. After correcting the middle-stage detail-switch condition, the targeted reset/detail-switch test passed again with an explicit assertion that the procedural view disappears and can be restored: verification/fusion-detail-switch-test.txt.

Portable checks passed on the final local-frame geometry, including 41 fusion states and agreement of joined tube radii with the looping start: verification/fusion-policy-final.txt. These validate numerical shape construction, not cellular fusion, body folding or clinical accuracy. The full developmental timeline and physical-headset performance remain unfinished/unverified respectively.

## UMCG integration and both learning modes

Initial three tests passed: developmental branch return, guided joining animation return, and neonatal/ASD/VSD model loads. Final corrected run passed direct guided ASD entry, cushion prediction/retrieval concealment with AVSD reference return, and all five UMCG model loads (neonatal, ASD, VSD, TGA, AVSD): verification/umcg-complete-tests.txt. The earlier umcg-final-tests.txt failed because XCTest rejects text identifiers longer than 128 characters; the model loaded, and the test now uses a stable identifier. That runner stalled collecting its failure report and was interrupted after the selected tests ended.

All five downloaded USDZ assets imported successfully in Blender with script execution disabled. Geometry/material inspection and download hashes are in HeartAssets/external/umcg. Simulator loading does not certify visual fidelity or headset performance.

## Morph prediction and observation

All three affected UI tests passed: full joining/looping playback, guided joining return, and explanation concealment/reset between joining and looping questions. See verification/morph-learning-tests.txt. The portable policy suite also passed, including both surface generators and content-answer checks: verification/morph-learning-policy.txt. No efficacy or retention claim is inferred from these interaction tests.

Neonatal material follow-up: all five UMCG model load/switch checks passed after applying the labelled uniform tissue material to the texture-free neonatal source. See verification/umcg-material-test.txt. Earlier white-render evidence is retained as verification/umcg-neonatal-render.png.

## Reference appearance and framing

The targeted simulator regression passed after the reversible material and placement changes (36.352 seconds): verification/reference-framing-tests.txt. It exercises ASD tissue/source appearance, VSD source-material preservation, AVSD loading and return. The earlier reference-shading-tests.txt is a compile failure from ambiguous SwiftUI/RealityKit Material naming, corrected with explicit RealityKit.Material qualification; reference-shading-final-tests.txt passed afterward. Visual evidence: verification/avsd-framing-final.png, with the anatomy below the selector. Physical-headset scale, initial source orientations and readability still need hands-on assessment.

Rotation regression: the first run compiled but failed because the generic Reset view query targeted the underlying exploration toolbar (tool.Reset view), leaving the reference rotation running. Added reference.reset and corrected the test to target the visible viewer's control. The failed runner was interrupted after its selected test finished and it stalled collecting the failure report. Evidence retained in verification/reference-rotation-tests.txt.

Final rotation regression passed (42.176 seconds, zero failures): verification/reference-viewport-rotation-tests.txt. It checks start → reset, original/tissue appearance, switching from a rotating ASD to VSD stops rotation, VSD retains source-only appearance, AVSD loads, and return works. The intermediate reference-rotation-final-tests.txt failed at model switching while animation state refreshed the entire reference view. Animation state now lives inside the 3D viewport; surrounding controls no longer refresh each frame. That change passed the same interaction sequence. Background/Reduce Motion handling is implemented but not newly exercised on a physical headset.

## Shared live model style — 25 October

Four simulator UI checks passed (177.109 seconds): guided morph return, exploration scrub/open-wall/reset, imported material switching, and all five UMCG models. Evidence: verification/model-style-interactions.txt. This run preceded the user's instruction to remove appearance switching. After removing that option, the replacement test passed (41.198 seconds): verification/model-style-final.txt. It asserts there is no appearance switch, starts/resets rotation, switches among ASD/VSD/typical/AVSD and returns to learning.

The live RealityKit asset validation also passed all 16 lesson assets and seven HDBR reference models with the shared lighting and finish, including existing selection, isolation, reassembly and layout checks: verification/model-style-assets.json. That report precedes the final regional hue-preserving saturation/brightness adjustment.

The GPU-enabled portable policy/material suite passed after that palette adjustment: verification/model-style-palette-policy.txt. It verifies the deep-rose palette; regional hue/alpha retention; bounded saturation/brightness; idempotence; original material immutability; transparent blending, culling and selection emission; preservation of real colour, normal, roughness, metallic and occlusion texture resources, UV channels and texture multipliers. Ordinary sandboxed runs explicitly skip material checks when no Metal device is available; numerical interaction and geometry checks still run.

Test-development notes: the first new texture test incorrectly compared Swift object identity; RealityKit material getters return different wrappers for the same texture resource. It now uses TextureResource equality and compares source/getter UV settings. No production texture change was needed. An earlier compiler run was interrupted by an edit to its input file; the complete suite was rerun. Legacy generate(from:) emits a deprecation warning in the host test, but remains used for compatibility with the host RealityKit runtime.

Visual evidence includes verification/style-neonatal.png, style-looping.png and style-typical.png. The last is the pre-regional-palette screenshot that exposed the overly saturated source colours. Physical-headset readability, perceived material consistency across every source, and thumbnail parity are not established by these automated tests.

Final textured-reference increment: simulator UI regression passed (47.108 seconds, zero failures), verification/model-style-texture-ui.txt. The complete GPU-enabled policy/material suite passed, including bounded reference texture tint, source-map equality, alpha and idempotence: verification/model-style-texture-policy.txt. The earlier untextured-palette UI regression also passed (46.553 seconds), verification/model-style-palette-ui.txt. style-typical-final.png is retained as evidence that an untextured-only palette change did not affect the typical-heart's colour texture; the final graded screenshot is style-typical-graded.png.

## Outflow transition and anomaly integration

The first three simulator interaction tests passed (97.597 seconds): process branch return to the same stage; guided outflow morph → developmental branch → original lesson phase; exploration at 40% → open/close wall → concealed prediction → TGA branch → exact 40% return → reset → detailed anatomy → morph. See verification/outflow-ui.txt. A preliminary build-only invocation used the test scheme's unavailable build destination; the normal test action compiled and ran successfully.

The final portable suite passed, including 82 outflow surfaces (closed/cutaway × 41 positions) with stable topology/material slots, finite unit normals and noncollapsed triangles; fractional outflow timeline handling; branch coverage and overlapping process windows; existing joining/looping, material, scaling and assessment checks. See verification/outflow-final-policy.txt. These checks do not certify anatomy, self-intersection-free geometry or physical-headset performance.

The expanded four-test run passed (132.797 seconds): AVSD timeline branch with embedded downloaded model; guided outflow branch return; joining/looping prediction concealment; outflow prediction, TGA branch, exact timeline return and detail/morph switching. Evidence: verification/outflow-final-ui.txt. Visual inspection of outflow-midpoint.png showed the default cutaway too edge-on; the follow-up adjusts its neutral yaw and pitch and modestly increases its fitted size. Percentage display now rounds correctly instead of showing 59% at a 60% floating-point position.

Replay/visual follow-up: both the guided anomaly → normal-process replay → anomaly → lesson path and the complete exploration outflow playback/reset/branch-return test passed (158.079 seconds combined), verification/outflow-replay-final-ui.txt. The preceding outflow-playback-ui.txt unexpectedly found Home after an anomaly return, despite first observing the animation title. This did not reproduce in the rerun; no crash or specific navigation root cause is established. The failed runner was terminated after tests completed when it stalled collecting its report.

Regional palette: verification/regional-final-policy.txt passes fixed six-region face assignments during looping, explicit name mapping, preserved surface-detail maps and wall-layer differences, alongside the geometry and interaction policies. The initial regional UI run passed guided replay and full outflow playback, but its existing 12-point looping-slider drag did not change the slider value (verification/regional-morph-ui.txt). That test now uses a 24-point drag and is being checked separately; no claim of a product fix is inferred from the test adjustment. The failed report collector was stopped only after the selected tests ended.

Final regional UI verification passed both tests (102.908 seconds, zero failures): the longer timeline drag, loop endpoint/open-wall/reset, playback across joining/looping, and leaving the interval; plus imported model rotation/reset/switches and no original-appearance control. Evidence: verification/regional-style-final-ui.txt. The previously unregistered 12-point drag remains documented; this run demonstrates a 24-point drag works in the simulator, not a minimum gesture threshold on headset.

## Regional catalogue follow-through

Final morph-presentation tests passed (111.090 seconds, two tests, zero failures): guided looping return and outflow playback/prediction/anomaly return/reset/detail switching. Evidence: verification/morph-presentation-final-ui.txt. The updated simulator screenshots regional-looping-presentation.png and regional-outflow-presentation.png show the larger default fit and corrected Outflow cushions legend, with no visible overlap at the captured orientations. They do not establish all rotated states or headset legibility.

The extended GPU-enabled material/policy suite passed: verification/regional-catalogue-policy.txt. Added actual catalogue aliases, exclusion of unnamed/context/valve-layer parts, matching paired-tube wall colours, preserved normal/roughness maps and wall-layer distinctions. Catalogue UI and live asset checks follow below once complete.

Catalogue UI checks passed (116.761 seconds, two tests, zero failures), verification/regional-catalogue-ui.txt: guided paired-tube morph/reset/return to the same lesson phase; lesson catalogue/anomaly navigation; atlas stage switching, separation/reassembly and return to exploration.

Live asset validation passed all 16 lesson assets and seven HDBR reconstructions after the catalogue update: verification/regional-catalogue-assets.json. The report records regionalPaletteMeshesTested per model, alongside the existing manipulation, layout, selection, isolation and reassembly checks. A zero count means that model has no explicitly mapped regions and retains its harmonised source palette; it is not a claim that every source part was recoloured. This run checks the installed materials, replacing the obsolete expectation that the displayed CS11 ventricle must retain its original red tint. Physical-headset interaction and perceptual consistency across every specimen remain unverified.

Final guided screenshot: verification/regional-guided-presentation.png shows the installed CS11 reconstruction with the regional palette. Across the 23 live validated assets, 205 mapped material instances were checked; unassigned source regions remain harmonised rather than receiving invented labels. Screenshots are simulator captures, not headset recordings.

## Morph deformation repair — 25 October

Verification/morph-repair-policy.txt passes the expanded GPU-enabled policy/material/geometry suite. The new tests follow corresponding vertices through 0.5% looping steps in closed and cutaway views, check outward-facing outer-wall normals, preserved centreline segment lengths, drawing bounds, reverse-scrub determinism and a continuous colour reveal at the joining boundary. Maximum sampled movement is 0.002411713 m, compared with approximately 0.04388771 m in the original world-axis frame calculation. These checks establish the sampled geometric properties, not a global proof against all surface intersections or anatomical fidelity.

Build-development failures are retained: morph-continuity-ui.txt lacked the explicit Metal import; morph-continuity-ui-final.txt and morph-repair-ui.txt hit Swift's expression type-checking limits; extracting typed rendering methods exposed the shadowed catch error variable in morph-repair-final-ui.txt, corrected with self.error. Those runs did not execute UI tests. The final UI and live-buffer results follow below when complete. Headset verification is deferred at the user's request.

Morph repair final results: all three UI tests passed (186.473 seconds), verification/morph-repair-verified-ui.txt. Coverage includes reverse navigation across joining/looping with cutaway restoration, complete playback/reset, guided joining return, outflow wall controls/prediction and exact anomaly-return position. Live validation passed all 23 lesson/atlas assets plus 16 mutable-mesh frame checks and joining-topology reuse: verification/morph-repair-assets.json. Mesh identity remains stable within each topology and vertex buffers match forward/reverse progress. Headset verification remains deferred.

## Realistic models integrated into Guided Learning — 26 October

Portable GPU-backed material/geometry/policy suite passed, verification/guided-integrated-anatomy-policy.txt. Added lesson coverage, specific specimen mappings and prediction/recognition availability gates. The first three-test simulator run (guided-integrated-anatomy-ui.txt) reached the loaded specimen but failed because the test looked for a static-text loading identifier and the parent workspace identifier propagated over child IDs. Removed the parent identifier and use the existing any-element ready query. The accessibility snapshot also exposed the hidden underlying schematic controls; the workspace now suspends its content while retaining its scene and controls, rather than relying on opacity. The scene reuses its installed entity when restored. Corrected UI and live catalogue validation results follow below.

Five final integration UI tests passed (174.667 seconds, zero failures), verification/guided-integrated-anatomy-final-ui.txt: coarctation specimen → concealed recognition; ventricular lesson normal/VSD switching and phase return; specimen → outflow morph → same lesson; AVSD access after prediction and removal during retrieval; existing cushion prediction, detailed-model sheet, explanation and recall. The hidden developmental toolbar is absent while later anatomy is active. A separate model-size/separation preservation check is recorded next.

The first dedicated preservation test (guided-representation-preservation-ui.txt) used the wrong toolbar query after separation: the active action is Reassemble, not Separate. Corrected the assertion to check the existing Reassemble control and its selected state; production code was unchanged for that correction.

The dedicated guided representation-preservation regression passed (49.342 seconds), verification/guided-representation-preservation-final.txt. It enlarges and separates the developmental model, switches to later anatomy, returns at the same phase, verifies the Reassemble state and identical model-size value, then reassembles. The earlier wrong Separate query remains documented above.

## Heart anatomy subsections — 26 October

Replaced the Home whole-heart entry and free-exploration modal entry with Heart anatomy subsections in both mode selectors. Both embed the same collection/viewer with Normal_Teenage_Heart as the default. Updated navigation tests cover no Home entry, loaded identical source models under both modes, no in-app CC links, model rotation/reset, and exact fractional-timeline return. Results follow below.

All three subsection regression tests passed (108.783 seconds, zero failures), verification/anatomy-subsections-ui.txt: shared anatomy access from both modes, preserved 40% timeline position on return, and reference styling/rotation/reset across models. The same simulator build includes the previously verified guided specimen integration. Physical-headset verification remains deferred.

Final live validation passed: verification/anatomy-subsections-assets.json records 16 lesson assets, seven atlas reconstructions, installed specimen mappings for 15 guided lessons, 16 forward/reverse mutable-mesh frames, reused joining topology, independent saved lesson progress, and interruptible separation/reassembly. This checks the bundled resources and rendering/state contracts; it does not establish anatomical equivalence between unrelated sources or validate headset perception.

The final glass-surface correction also passed the two-mode anatomy-navigation regression (51.684 seconds), verification/anatomy-subsections-presentation-ui.txt. The correction restores the free-exploration subsection's readable backdrop after removing its former sheet; it does not change model styling or state.

Inspected loaded simulator captures: verification/anatomy-subsection-final.png and verification/guided-integrated-final.png. Both show the same typical-heart material treatment without the former CC rows. The anatomy collection has the restored glass background. Wider UI work remains deferred: the eight-option reference picker truncates the longest title at this width, and the guided workspace's transparent selector background has weaker contrast against the room. These captures do not verify headset legibility or every model orientation.

## Source-preserving sections and specimen part controls — 26 October

Portable geometry/material/policy tests passed: verification/specimen-section-final-policy.txt. New checks sample complementary clipping planes and require preserved surface area, interpolated UVs and unit normals, coplanar-surface retention, bounded movement including invalid input, and source grouping that keeps exported TGA fragments/Fallot material pieces together.

Two simulator interaction tests passed (112.964 seconds, zero failures), verification/specimen-inspection-async-ui.txt: sections, separation, per-part movement, reassembly and reset in both Free Exploration and embedded Guided Learning; developmental lesson section/reset and newly available part tools without phase loss. The first run, specimen-inspection-ui.txt, was interrupted during a test that incorrectly queried a plain button as StaticText; the test now checks the existing button's label. The lesson test had passed before interruption.

The first full live audit exposed heavy CPU work during synchronous section preparation. Clipping now runs on a cancellable detached task and mesh creation uses the asynchronous RealityKit initializer. Original geometry remains visible while preparation runs; cancelling or resetting cannot apply a late section. Final build-for-testing succeeded: verification/specimen-inspection-final-build.txt. A per-asset progress report is now written during live validation; final results follow below.

Final live validation passed all 31 static assets: verification/specimen-inspection-assets.json. All 16 teaching assets, seven HDBR reconstructions and eight imported specimens passed three-axis sections and original-mesh restoration. Lesson/atlas sections retained the fitted viewpoint. Specimens passed source-group movement, interrupted reassembly and controls-plane bounds at enlarged/rotated views. Existing material, lesson progression, morph-buffer, selection/isolation and separation checks also passed. This is a software/source-preservation result, not an anatomical accuracy certification.

The final two-mode interaction rerun passed (115.418 seconds, zero failures), verification/specimen-inspection-final-ui.txt. Visual inspection prompted a depth correction: instead of always pushing the entire specimen back by its full diameter, fit now uses the nearest original-surface bound at the current part transforms, with a small safety margin. The same original envelope is used during sectioning, and animated part movement updates depth continuously. Source-bound safety and reset-during-section-preparation are checked again in the final live report below.

Final source-scale correction passed the strengthened live audit: verification/specimen-inspection-final-assets.json. All 31 static models pass. Imported groups must now move by the expected 15% of visible diameter in their assigned direction, not merely a nonzero amount. The eight imported specimens also pass cancellation while section preparation is pending, original-resource restoration, enlarged/rotated controls-plane bounds, and interrupted reassembly. The final portable suite additionally verifies distinct separation directions for two through six groups. Inspected verification/specimen-section-separated.png confirms visible separation of the typical heart's myocardial shell and blood-pool representation with the width section active. This static capture does not verify animation feel, every source orientation or headset performance.

## Stable specimen transitions and morph manipulation — 26 October

The portable policy/material/geometry suite passed: verification/model-transition-policy.txt. Initial three-test simulator run passed (124.445 seconds of individual test time), verification/model-transition-ui.txt: guided normal/anomaly selection, morph resize/reset in both modes, and reference rotation/model switching.

After extracting the shared morph placement calculation and clearing the cancelled section-preparation state, the final three-test run passed (174.080 seconds, zero failures), verification/model-transition-final-ui.txt. Coverage: view reset preserves exact morph progress and open-wall state in both modes; guided normal/VSD switching and same-phase return; sections, bounded movement, separation/reassembly and reset in both specimen viewers.

The live RealityKit transition audit passed: verification/model-transition-assets.json. It checks retained visible source during replacement loading, an uncancelled superseded load, one installed specimen root, failed-source preservation/recovery, navigation cancellation and reduced motion. Twenty-two forward/reverse morph frames retained their cached surface envelope; 198 combinations of size/orientation kept every generated surface point behind the control plane. These checks exercise actual installed scene and mutable mesh APIs. They do not replace headset perception/performance checks or establish full developmental/anatomical fidelity.

The first visual capture (verification/morph-view-controls-before.png) exposed too little model space after adding viewing controls. The shared morph panel now combines its title/prediction row, consolidates repeated explanatory text, and reserves at least 220 points for geometry. All three affected morph tests passed after this change (139.180 seconds), verification/morph-view-space-ui.txt: full forward/reverse timeline playback and wall state, guided specimen → outflow → same lesson, and independent view reset in both modes. The during-test capture, verification/morph-space-during-tests.png, shows the larger closed looping view at 100%.

The dedicated failure/retry UI regression passed: verification/specimen-retry-ui.txt. A DEBUG-only missing-source fixture presents the error, keeps part controls disabled, exposes Try again, then loads the real source and restores inspection controls. Failure feedback is outside the viewport accessibility wrapper. No new source, geometry, material or timing changes followed the live transition audit.

Final visual check: verification/morph-view-controls.png shows the looping illustration at 40%, 1.0×, with the model clearly separated from the controls and the larger reserved viewport. This simulator capture was inspected; headset legibility and manipulation feel remain unverified.

## Progressive morph walls and shared manipulation — 26 October

The new portable checks sample partial wall openings at three developmental positions, checking looping radius/thickness and small corresponding-vertex movements, unchanged outflow cushions/posterior wall, finite normals and noncollapsed faces. Initial results passed: verification/morph-wall-policy.txt. The first UI build failed in the test's use of an Any-valued XCTest key path; corrected to a predicate expectation without altering production behaviour. Both corrected UI tests passed (125.314 seconds), verification/morph-wall-final-ui.txt: repeated open/close at retained progression in free looping and guided outflow, plus the existing full timeline/backward/playback/reset path.

The shared manipulation suite adds active-reset suppression, cancellation, fresh gesture baselines and repeated upper-bound checks: verification/morph-inspection-policy.txt passed. A final suite also exercises Float endpoint slivers; its result and final UI/live results follow below.

Final portable suite passed: verification/morph-inspection-final-policy.txt, including near-endpoint Float geometry. Four integration UI tests passed (242.688 seconds), verification/morph-inspection-ui.txt: anomaly-preview size/reset/sheet return, morph view reset, wall inspection, and static specimen sections/part controls in both modes. After the final endpoint correction, the dedicated two-mode wall test passed again: verification/morph-inspection-final-ui.txt. These tests do not simulate physical two-hand tracking.

Live GPU/scene validation passed: verification/morph-inspection-assets.json. It verifies 22 partial/open/closed wall frames, exact GPU vertex buffers during reverse traversal, cached-resource reuse for intermediate cuts, near-endpoint topology selection, enlarged rotated control-plane bounds, interrupted animation reversal and immediate reduced-motion endpoints. The same run retains the previous 22 developmental frames, 198 placement combinations and specimen loading/cancellation/failure checks.

## Independent specimen recovery — 26 October

The two-mode interaction regression now changes size while sectioned/separated, verifies Reset view retains the section and separation, verifies Reassemble retains the section, and verifies Restore model removes the section/reassembles while preserving the enlarged size and guided phase. The live transition audit also checks selective return on the typical heart and VSD, unchanged neighbouring components, individual return of every part, separation restart, interrupted return/reassembly, source-mesh restoration and preserved viewing pose. Results follow below.

The initial two UI tests passed (151.506 seconds), verification/specimen-recovery-semantics-ui.txt: independent recovery in both modes and preserved anomaly-preview size through a nested specimen sheet. The final per-part-return implementation is checked in the subsequent build/live run below.

Final two-mode UI recovery regression passed (119.189 seconds), verification/specimen-recovery-final-ui.txt, with Return part included. Live validation passed: verification/specimen-recovery-assets.json. Typical-heart and VSD source groups return individually without disturbing neighbours; returning every group clears separation state; separation restarts; interrupted return/reassembly cannot override restoration; original MeshResource identities and viewing pose are preserved as specified. Existing transition, wall-buffer, reversal and bounds checks also pass.

Inspected verification/specimen-recovery-controls.png: the sectioned/separated typical heart shows Reassemble and Restore model beside inspection controls, with Reset view beside size/rotation controls. The known long specimen-picker title truncation remains; this pass does not claim a wider UI redesign or headset legibility verification.

## Early-tube tissue layers — 26 October

Portable policies passed: verification/tube-layers-policy.txt. New cases cover joining/looping at six progress positions, three wall-opening values and assembled/separated states; every component matches its generated layer source, separated vertices differ only by a rigid offset, normals stay finite/unit, GPU bounds hold, material identity remains within the common palette, and adjacent radial interfaces meet. Existing single-wall/outflow/material/spatial tests also pass.

The first two UI tests passed (165.038 seconds), verification/tube-layers-ui.txt: the existing complete forward/backward looping timeline and a new two-mode layer-inspection flow (open, separate, scrub, explain, reset view without reassembly, reassemble and reset morph, return to the same guided phase). The initial test build contained an appearance toggle; it was removed so the final tube consistently uses layered anatomy. Final UI/live evidence follows below.

Final two UI tests passed (146.027 seconds), verification/tube-layers-final-ui.txt, with the consistent layered tube and the existing outflow wall behaviour. Live validation passed, verification/tube-layers-assets.json: 21 layered joining/looping/separation frames matched GPU buffers, regional material indices stayed in range, reassembly reused the GPU resource, and enlarged/rotated separated layers stayed behind controls. Prior wall, developmental-bound, lifecycle and specimen-recovery checks also passed.

Final visual checks: verification/tube-layers-separated.png and verification/tube-layers-assembled.png were inspected at 40% looping with the wall open. The three shells occupy distinct offsets when separated and nest together when assembled. Controls remain visible in these simulator captures. They do not establish histological realism, physical-hand interaction quality or headset performance. The assembled-preview launch was temporarily blocked when automatic approval review hit a usage limit; retry after the user continued succeeded.

## Morph workspace context and practice cycle — 26 October

Context tests passed (108.025 seconds), verification/morph-context-ui.txt: retained progress, wall state, separated layers and size after free-anatomy/guided-sheet returns, plus the existing guided anomaly/outflow branch. Three learning-cycle tests passed (168.276 seconds), verification/morph-learning-cycle-ui.txt: prediction does not reveal explanation, comparison precedes explanation, saved practice survives dismissal, restart conceals answers and explicit reveal is labelled uncompleted practice. Portable state/geometry policies passed, verification/morph-learning-cycle-policy.txt.

Individual-layer movement adds portable checks for bounded offsets, unchanged neighbours and retained triangle/material identity. A final combined UI and live-buffer audit follows below.

Combined simulator regression passed: three tests, 278.365 seconds, verification/morph-layer-movement-ui.txt. It covers workspace returns, the prediction/observation/explanation sequence and individual-layer inspection in both modes. After the deformation-cache optimisation, the final two-mode layer test passed again (141.623 seconds), verification/morph-continuity-final-ui.txt. The final portable suite passed, verification/morph-continuity-final-policy.txt.

Live validation passed, verification/morph-continuity-assets.json: 21 moved/separated layer frames matched their expected GPU positions, reassembly retained the GPU resource without rebuilding the developmental deformation, offsets remained bounded, and cancelling a layer move could not overwrite reset. The existing 22 wall frames, 22 developmental frames, 198 control-plane placements and two-specimen recovery/lifecycle checks also passed.

Inspected verification/morph-layer-inspection-final.png at 40% looping with the wall open and layers separated. The three shells and the new movement control are visible; the shared regional colours remain attached to each layer. Text is still small at the captured window distance. This confirms the simulator composition only; wider UI legibility, surface realism and headset interaction remain outstanding.

## Layer isolation and mode consistency — 26 October

Initial isolation/context integration tests passed: two tests, 257.359 seconds, verification/layer-isolation-ui.txt. Both modes isolate a layer, retain it through movement, reset view and view dismissal, then restore all layers without reassembling them. Reset morph clears isolation. The final implementation additionally retains the whole arrangement's placement during isolation and shares elapsed-time movement/material caching.

The first final-build attempt failed because the animation callback required an explicit self capture (verification/model-mode-consistency-ui.txt). Corrected before rerunning; no runtime validation is inferred from that failed build. Final results follow below.

Corrected final consistency suite passed: three tests, 259.424 seconds, verification/model-mode-consistency-final-ui.txt. Reverse traversal now restores the chosen wall opening; the full looping playback/reset path, both-mode layer isolation/movement and guided outflow/anomaly replay pass. Portable session/geometry policies passed, verification/model-mode-consistency-policy.txt.

Outflow separation policies passed, verification/outflow-inspection-policy.txt: three developmental positions, three wall-opening values and four separation fractions preserve source vertex ranges, wall position, rigid cushion offsets, normals, triangles and materials. Invalid separation values restore the assembled endpoint, and the full separated envelope remains inside drawing bounds. Final outflow UI/live results follow below.

The outflow UI regression passed in both modes (100.013 seconds), verification/outflow-inspection-ui.txt. It verifies separation across timeline changes and view dismissal, Reset view preserving arrangement/wall state, Reassemble preserving progress/wall state, and Reset morph restoring the default arrangement. The final guidance/preview build passed, verification/model-inspection-final-build.txt.

Final installed live validation passed, verification/model-inspection-final-assets.json: 63 isolation frames retained the same GPU mesh and viewing transform, 144 material comparisons matched the shared palette/lightness/roughness rules, and nine separated-outflow frames matched expected buffers and stayed behind controls at 2.5×/rotation. Reassembly did not rebuild outflow deformation. Existing layered morph, wall reversal, interrupted move/reset, lifecycle and two-specimen recovery tests also passed. These are software/simulator checks; headset acceptance and anatomical realism remain separate.

Final screenshots inspected: verification/outflow-components-final.png shows the fixed wall and displaced cushions at 40% with the reassembly reminder; verification/isolated-endocardium-final.png shows only the selected layer, its retained regional colours and Show all layers. Neither capture shows source geometry crossing the control rows. The small text and schematic procedural surface finish remain visible limitations; this pass does not certify headset legibility or realistic histological detail.

## Morph phase-boundary continuity — 26 October

Portable regressions passed, verification/morph-phase-continuity-policy.txt. New tests verify monotonic/reversible timing and decreasing displacement near both ends of joining and looping for all three tissue layers, with open and closed looping walls. Existing tests still verify the shared straight-tube endpoint, nonfolding surfaces, deterministic reverse scrubs, layer geometry/material identity and outflow components. Fine-step displacement remains below the existing 4 mm model-space threshold (maximum observed 3.196451 mm).

Two simulator tests passed (104.964 seconds), verification/morph-phase-continuity-ui.txt: the free timeline traverses forward/backward through joining and looping, restores wall inspection, plays through completion and resets; the guided joining morph returns to the same lesson phase. The tests exercise the shared revised geometry in both modes. Live GPU regression results follow below. No headset frame-rate or biological timing claim is made.

Installed live regression passed, verification/morph-phase-continuity-assets.json: revised deformations match the GPU vertex buffers, with all 21 layered frames, 63 isolation states, 144 material checks, nine outflow inspection frames, 22 wall frames and 198 control-plane placements passing. Existing cancellation, recovery and resource-reuse checks also pass.

## HeartV0 recording response — 27 October

The new recording was sampled at 10-second intervals (21 frames, duration 202.128 seconds); contact sheets are in verification/retest-oct27. This is a visual review, not a measurement of tracking or narration quality.

Initial build passed. The compiled Info.plist reports CFBundleDisplayName=HeartV0. Four core UI tests passed (154.963 seconds), verification/retest-oct27/core-flow-ui.txt: renamed home/default animations, free development→anomaly comparison→explanation→return with the same timeline, guided normal-process replay and protected coarctation recognition. Final layout/journey/inspection-state checks follow below.

The next core run passed inline timeline navigation, saved morph inspection in both modes, and coarctation concealment. The new catalogue-journey test used `--preview-guided`, which intentionally opens the cardiogenic lesson; it therefore failed to find the catalogue entry. Corrected the test to enter through Home → Guided Learning. This was a test entry-path error, not an app crash. The corrected journey and the final joining-only endpoint are checked in the subsequent run.

### 27 October follow-up: completed route and normal replay

`retest-oct27/journey-final-ui.txt`: all three corrected route/return/name tests passed in 108.766 seconds. `retest-oct27/anomaly-replay-ui.txt`: TGA → normal outflow replay → related anatomy → return passed in 27.117 seconds. The normal replay is explicitly labelled as normal development.

Inspected `retest-oct27/guided-process-final.png` and `inline-anomaly-final.png` from the simulator. Playback controls fit in the ordinary window; the anomaly explanation action was partly below its scroll viewport and the TGA source appeared small and pale. These were actionable findings, not a claim of headset acceptance. Follow-up changes pin the explanation action, improve embedded framing, adapt the texture-free TGA finish and add progress-linked observation prompts.

`retest-oct27/observation-flow-ui.txt` initially failed all three flow tests at the same developmental-window text assertion: deduplicating the sidebar left only the uppercase visual heading. The UI hierarchy showed the models and controls loaded. The heading now exposes the original sentence-case accessibility label and a stable `connection.window` identifier. The corrected run is `observation-flow-final-ui.txt`; result recorded below once finished.

Final regression: `retest-oct27/observation-flow-final-ui.txt` passed all three tests in 119.065 seconds, with zero failures. Covered joining endpoint/prompt changes, independent next-process state, in-place related anatomy, hidden-before-reveal explanation, typical/altered comparison, retained free-timeline position, closure on stage change, and TGA normal-process replay. The explanation button is explicitly checked as hittable without scrolling. `git diff --check` passed. This is targeted coverage, not a full-suite or headset pass.

Visual follow-up: `retest-oct27/inline-anomaly-updated.png` confirms the shared coral tissue finish, larger embedded TGA framing, and fully visible Explain/replay controls. `timeline-observation-updated.png` exposed clipping of Home and the bottom timeline in free exploration. This failed visual check prompted a responsive model-viewport fix and a new containment/hit-testing regression. The latter screenshot is pre-fix evidence, not final acceptance.

`retest-oct27/window-fit-ui.txt`: both tests passed in 57.102 seconds. The new check verifies Home, Play morph, Reset view, and both stage-navigation buttons are hittable and fully contained inside the application window at joining 20% and outflow 60%. The timeline branch/return test also passed on this final layout build.

Inspected `retest-oct27/timeline-fit-final.png`: the full header, playback/resize controls, developmental branch actions, stage buttons and timeline caption are now inside the default window. The trade-off is a smaller model area at this window size; control simplification/model prominence remain usability work. Headset reach, readability and gesture feel remain unverified.

## Compact morph controls and applying practice — 27 October

Initial run `retest-oct27/compact-morph-apply-ui.txt`: the two-mode view-reset test passed in 59.717 seconds, and the complete two-mode prediction/observation/explanation/application/return test passed in 101.303 seconds. The new viewport-height check failed in outflow at 157 points (minimum test target: greater than 160), although all control containment/hit tests passed. Adjusted the scope/legend to share a row when they fit and reduced vertical padding. The corrected visibility check now includes joining, looping and outflow. This records an actual layout failure and its response, not a fully passing initial run.

### Spoken feedback, local layer placement and cross-sections

`retest-oct27/compact-morph-final-ui.txt`: viewport/control fit across joining, looping and outflow plus retained layer inspection across modes passed (34.886 and 105.813 seconds). `retest-oct27/spoken-feedback-ui.txt`: direct cross-sections/part controls and layer inspection in both modes passed, two tests in 264.509 seconds.

`retest-oct27/layer-cut-drag-policy.txt`: portable policies passed, including viewer-facing lumen opening, fixed posterior reference, unchanged layer interfaces, bounded local separation, rotation-corrected drag offsets and preservation of unknown source-group roles.

`retest-oct27/layer-cut-drag-ui.txt`: fit and wall/progress tests passed; the newly added direct-drag test failed because the selected layer did not move. A transparent viewport hit surface and gesture-cancellation cleanup were added; the corrected drag run is recorded separately. This was not counted as a passing feature.

## Emergency recovery from 19:40 recording — 27 October

The morning direct-drag experiments never passed their UI regression. The final rendered input proxy was left in the build and the user's evening recording exposed it as a solid black rectangle. It is removed together with the unverified direct-drag option; directional movement remains. The failed test is withdrawn with that feature, not reclassified as passing. The pure coordinate math check remains valid but does not establish working input.

`retest-oct27-evening/recovery-build.txt` and `white-build.txt`: simulator test builds succeeded. `recovery-policy.txt`: complete portable suite passed, including geometry/UV continuity, movement bounds, model material preservation, realistic anomaly defaults and hidden-answer gates. `morph-white.png` was visually inspected: white backing, visible open tube, no rectangular obstruction. The earlier `morph-white-first.png` showed a clipped background and is failed intermediate evidence.

The UI regression exercises five realistic anomalies in Free Exploration, guided ASD/VSD entry, absence of the removed shortcut, layer movement/reset in both modes, coarctation concealment, and morph viewport containment. Results will be recorded after completion. Screenshots attached to the anomaly test must be inspected in addition to accessibility/loaded-state checks.

Evening recovery result: `recovery-ui.txt` passed all four selected tests (298.283 seconds, zero failures). Exported and inspected free VSD/coarctation and guided ASD attachments: anatomy is visible without the black occluder. These are visibility checks, not a claim of complete visual consistency or headset acceptance.

Authored PDA checks: `pda-build.txt` passed Blender mesh validation for both states, all six component meshes manifold with positive volumes. The patent centreline ray reaches the aortic lumen without crossing a wall; the closed version intersects both parent walls and the ligament. `pda-policy.txt` passed the portable suite, including authored-model identity, matched birth comparison and hidden-answer gates. `pda-patent-first.png` is an intermediate render that led to roughness and viewing-angle corrections, not final acceptance. Targeted simulator UI and live mesh checks are recorded below once complete.

`pda-ui.txt`: the new two-mode PDA test passed in 64.504 seconds, including patent/closed toggles, sectioning, separation/reassembly, guided birth-context entry, concealed explanation, explicit reveal and return to the same phase. Existing imported anomaly regression follows in the same run.

`pda-ui.txt` completed with both tests passing (152.796 seconds, zero failures); VSD's pale untextured surfaces now visibly use the shared tissue colour. Screenshot inspection also confirmed that native segmented-control labels were white-on-white. Replaced the comparison, representation and section-direction selectors with the existing readable `SpatialChoicePicker`. This is a contrast repair using the existing component, not a layout redesign. The final UI run rechecks these changed controls.

`pda-final-ui.txt`: PDA comparison/lesson test passed again with the readable choices (63.268 seconds). The section/parts test stopped on an obsolete assertion for “Inspect source parts”; the panel is now “Inspect parts”. Its hierarchy confirmed the controls were present. Updated that assertion and reran it in `parts-final-ui.txt`; the failed run is retained as evidence, not counted as a pass.

Final results: `parts-final-ui.txt` passed section axes, component movement, individual return, reassembly, independent view reset and full model restoration in both modes (118.095 seconds, zero failures). The successful live `transition-validation.json`, written by the installed app at 20:13 on 27 October, covers both authored ductal assets, three section axes, retention of the matched ductal cut, 144 morph material checks (including installed grain/roughness maps), 198 model/control-plane poses, 63 isolated-layer frames, cancellation, latest-request-wins and recovery. `git diff --check` passed. The obsolete-heading failure above remains in its log; its xcodebuild result collector stalled after finishing the tests and was stopped after the corrected run completed. No headset verification is implied.

The final exterior screenshot still showed substantial duct overlap from the initial frontal/side angle. A scene ray-cast visibility sweep (`pda-view-visibility.txt`) compared 21 viewing poses without changing geometry: a 0.6-radian elevated frontal view exposed 158 sampled duct faces versus 65 at the earlier side-only angle. Both mode defaults now use that elevated view. This is an authoring visibility check, not anatomical measurement. Final build/render follows; the interaction behaviour is unchanged.

`final-build.txt`: final simulator test build succeeded after the viewing-angle-only adjustment. The source remains uncommitted for review. Headset comfort, hand tracking and depth perception remain pending.

Visually inspected `pda-final-elevated.png`: white workspace, unobstructed vessel anatomy, visible coral duct above the pulmonary branch, readable Patent ductus/Closed remnant choices and no rendered input rectangle. The model remains an enlarged regional reconstruction with simplified gross vessel contours; the screenshot does not establish patient-level realism or microscopic accuracy.

## 22:48 recording follow-up — 28 October

`retest-oct28/build.txt`: initial simulator build passed. `policy.txt`: portable suite passed, including five explicit reading/selection/primary contrast pairs at 4.5:1 or better and the centralized stage-anchor identity. These numerical checks apply to opaque tokens, not an assertion that every runtime text/background pair has been audited. `testFreeMorphControlsFitWindow` passed in 35.482 seconds at joining, looping and outflow; remaining controls stayed contained and the viewport exceeded its minimum test height. Guided/selector screenshots and results follow after the targeted run.

`retest-oct28/ui.txt`: all three targeted tests passed (149.043 seconds, zero failures): morph control/window fit, model chooser and info access across both modes, and the recorded guided Slice/contrast screens. Exported attachments confirm dark guided headings/tab labels and a single-line Slice label. XCTest's app screenshots crop portions of the spatial window; full simulator captures are required for whole-layout acceptance. The final follow-up also checks model selection cancels rotation and reset preserves the expected behaviour.

`retest-oct28/final-ui.txt`: both final tests passed (81.241 seconds, zero failures): joining/looping/outflow window containment and selected-specimen rotation/reset lifecycle. Contrast token measurements are 17.01:1 primary/white, 9.12:1 secondary/white and 4.62:1 white/accent; all tested selection/reading pairs also meet 4.5:1. Final source diff whitespace checks pass. Full-device rendering still requires the scheduled headset review; tests cover neither every mesh extremity at every scale nor AX3/VoiceOver acceptance.

## Viewport alignment and Build 2 UI follow-up — 28 October

The preceding placement repair passed the portable suite and live transition audit (`verification/retest-oct28/layout-transition-validation.json`): 22 morph frames, 198 placement combinations, 63 isolated-layer frames, 144 palette checks, wall/outflow inspection, cancellation and specimen recovery. Those local-space bounds are **not** a screen-space guarantee. A screenshot at 2.5× still shows caption overlap. The initial full asset audit's overall failure was caused by stale expectations of 8 specimen assets / 15 guided mappings after the PDA pair; individual lesson/atlas/specimen checks passed. Coverage assertions now use the current inventories.

The six-test placement batch passed five interaction tests; the new viewport test initially failed because its accessibility container ID was not exposed. After fixing the container, a second run failed an arbitrary 200-point height threshold; the shared 180-point minimum is the intended layout contract. The corrected viewport test passed in `aperture-ui.txt` (38.670 seconds). Experimental direct coordinate-tap tests failed identically on the portal and original rendering paths, before reaching selection. They cannot establish a portal-specific regression or a direct-interaction pass. The unverified prototype and its temporary tests/instrumentation have been removed. Physical direct-input acceptance is still open.

Build 2 visual changes are tracked in `BUILD2_RETEST_2026-10-28.md`. `verification/retest-build2/build.txt` passes the simulator build. `policy.txt` passes the portable suite, including white/accent and disabled-label contrast. Actual contrast ratios are 4.616:1 (white on #D6336C) and 4.870:1 (disabled grey on neutral control), recorded in `contrast.json`. Retaining neutral disabled labels avoids the audit's internally conflicting proposal to both fade everything to 40% opacity and preserve readable contrast.

Build 2 shared-style UI regression: all four selected tests passed, zero failures, 189.116 seconds (`verification/retest-build2/ui.txt`). Covered Home/References/both modes, guided narration/phase/isolation/reset, free morph controls at three timeline positions and viewport/caption layout after phase changes, hide/show, reset and reopen. Home rendering inspected in `home.png`; cards and References are readable and contained. This result precedes the subsequent native slider change.

The full installed model audit now passes (`verification/retest-build2/asset-validation.json`): 16 teaching assets, seven atlas reconstructions, ten specimen interaction checks, complete guided specimen mappings, mutable morph meshes, saved lesson progress and separation-transition checks. This resolves the stale coverage-count failure in the preceding run. It validates loading/rendering/state contracts, not anatomical fidelity or headset perception.

Native slider regression: the first run (`slider-ui.txt`) failed before exercising the intended operations: an obsolete heading, a static-view expectation predating default morph entry, and SwiftUI's private AXSliderKnob lookup. Corrected the test's current heading/entry path and used XCTest's public normalized slider API when testing UIKit. The rerun (`slider-ui-rerun.txt`) passed all three sequences: free timeline reverse traversal/wall restoration/playback, static cutaway/search/isolation/separation/size/reset, and independent morph view reset preserving development/wall state in guided and free modes. The final marker/popover follow-up is recorded separately.

Final slider/popover tests passed (`slider-final-ui.txt`), two tests, zero failures, 79.356 seconds: the long animation explanation scrolls while Done remains hittable, dismissal restores access to Play, and sizing still preserves development/wall state in both modes with the non-interactive marker installed. Screenshot review then found that visionOS's native thumb rectangle reported a resting location unrelated to the filled track; the marker now uses the normalized value along the native track instead. This visual-only calculation was rebuilt successfully (`final-build.txt`) and inspected in `final-timeline.png`: the white marker aligns with the pink/neutral boundary at timeline position 2.4. No additional input handling changed after the successful interaction tests. `git diff --check` passes. Direct manual Device Hub interaction was unavailable because macOS was locked; simulator XCTest and simctl rendering remained available. Headset acceptance is deferred.

## Model animation/coherence and diagram audit — 28 October

Scope limited to model rendering, geometry-generation work, inspection animation timing and material restoration. UI, navigation, lessons, source meshes, palette values and textures were not changed. Source-hash scope check is in `verification/model-motion-oct28/changed-app-files.json`.

All 189 benchmark geometry frames match their pre-change SHA-256 signatures exactly for positions, normals, indices, material IDs and UVs. Optimized-host geometry timings improved substantially in this run; they are not headset FPS measurements. See MODEL_MOTION_CHECK_2026-10-28.md and the before/after JSON reports. The portable continuity/texture/palette suite passed (`model-motion-oct28/policy.txt`). Simulator builds succeeded.

All four targeted simulator interaction tests passed, zero failures, 544.252 seconds (`model-motion-oct28/ui.txt`): joining/looping timeline playback and reset; timeline → related anomaly/typical comparison → explanation → same position; complete predict/observe/explain → related anatomy → return in both modes; and specimen sections/part movement/return/reassembly/view reset in both modes. Slower specimen readiness in this run completed within the existing test bounds; no timeout thresholds were relaxed. The tests do not establish a frame-rate or headset performance guarantee.

The user-provided flow diagram was compared against source and representative tested routes. Results and remaining coverage gaps are in FLOW_DIAGRAM_CHECK_2026-10-28.md. No unrequested flow/content edits were made.

The final installed live audit passed (`model-motion-oct28/live-transition-validation.json`), including the new same-entity empty-material restoration and replacement-entity styling checks, monotonic elapsed-time animation completion and cancellation. Existing 144 material/palette comparisons, 63 isolated-layer frames, 21 layered morph frames, 22 wall frames, 198 placement samples, nine outflow inspection frames, specimen recovery, latest-request-wins and matched ductal comparison also pass. These checks validate buffer/state/material contracts; they do not resolve the previously documented screen-space maximum-zoom overlap.
