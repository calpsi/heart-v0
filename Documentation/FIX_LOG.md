# Fix log — updated 24 October 2026

No ticket is marked Fixed: the review requires manual device acceptance as well as automated tests. “Confirmed” refers to code behavior, not reproduction of the recorded headset event.

## Follow-up recording — 23 October, 15:33

Supersedes the close-up-window changes and 1.25× overview limit described below.

- HV3-001/002/006/007: removed the separate close-up scene, launch actions, snapshot transfer and view implementation. All inspection stays in the original model workspace. Main zoom is 0.4–2.5× with the existing discontinuity/invalid-input guards. Renderer now fits the 1× baseline before magnification; it no longer silently cancels larger requested zoom. At high zoom the viewport crops the enlarged model, and the nearest anatomy surface stays behind the control plane. Back clipping/backdrop reserve 0.8 m to accommodate the bounded model depth. Test control occlusion and clipping on headset before accepting.
- HV3-009/012/020: left toolbar uses two columns and no changing Focus/instruction block. Reset model, Undo and Reset view remain pinned. Selection/isolation uses the existing Isolate / Show all pair. Return part remains in a fixed slot (disabled until applicable), preventing the grid from rearranging during manipulation. The toolbar has a darker backing for bright environments. A short window may still scroll the optional tools.
- HV3-009/010/020: selected-part label now occupies a fixed-height, opaque footer with the current zoom. Removed repeated gesture/status lines above the model. Narration transcript opens in a bounded, scrollable popover instead of appending a second copy of lesson text inside the lesson card. Anatomy temporarily hides behind transcript and View settings popovers to prevent occlusion; transforms remain intact. View settings pins Done, size and separation above the scrolling display options. This addresses an observed simulator failure when dragging the offscreen separation slider. The unchanged drag test passes with the sliders pinned.
- Video observations: 00:24–01:24 narrow scrolling toolbar and repeated text above anatomy; 01:48–02:48 independent close-up and controls leave the original workspace; 03:00–04:36 guided layout has competing header/label/action rows. Still-frame review supports these UI observations; it does not prove gesture timing or tracking causes.
- Validation: see `verification/oct23-followup-tests.txt`. Headset acceptance remains required, especially at 2.5×, after repeated manipulation, and in small windows.

## Remaining implementation pass — 23–24 October 2026

- HV3-004/005/022: lesson actions, anatomical view presets and Restore step now cancel all active manipulation baselines consistently; lesson actions and presets also retain the prior view for Undo.

- HV3-029: comparison states use a common geometry envelope, preserving magnification, centre and depth when toggling normal/abnormal anatomy. Runtime regression checks all stateful teaching models. Isolation retains its own pivot.
- HV3-014/033/035: narration has an explicit Listen label and speaker symbol, with an accessibility explanation that it does not animate the model. The synthesizer prefers higher-quality installed US English voices with a default fallback. No audio quality or pronunciation validation is claimed. Explanation disclosure reduces initial lesson density; congenital catalogue card IDs are replaced with a schematic-content label.
- HV3-018/034: Model info exposes the existing content-review date/scope and incomplete anatomical-validation status from the repository's audit metadata; Sources and attribution opens the existing references in context. This is not new expert approval.
- HV3-020: selected tools have a checkmark as well as colour. Lesson copy has a stronger backing for contrast.
- HV3-024/032: optional local coarctation review queue, 1/3/7-day preference after a confident first unaided response, next-day practice after assistance/uncertainty. Multiple saves in one session are deduplicated. Later unaided recalls require at least 24 hours between sessions. Review opens at the unlabelled task without overwriting saved lesson progress. No notifications, mastery score or clinical-transfer claim.
- Clinical-content dependencies are specified in CLINICAL_VALIDATION_HANDOFF.md. The review's ghost silhouettes, additional flow/causal annotations and new transformation animations remain design/content work; the delivered context aids are the origin tether, orientation cue and Show all. These are alternatives/partial coverage, not claims that every suggested enhancement was built.

## Issue-to-code mapping

| Issue | Evidence classification | Code path | Delivery status / remaining work |
|---|---|---|---|
| HV3-001 | Confirmed unsafe path; device symptom not reproduced | HeartModelZoom; HeartModelScene.fit | Implemented bounded 0.4–2.5× zoom, crop and control-plane depth; headset acceptance pending |
| HV3-002 | Confirmed independent window path; ergonomic cause remains hypothesis | heart_v3App; HeartModelView | Separate close-up removed; model/control workspace unified; OS window placement remains manual |
| HV3-003 | Intentional separation; weak context confirmed | HeartModelControls.partOffsets; HeartModelScene.apply | Partial: origin tether and full reset; no ghost silhouette |
| HV3-004 | Confirmed distinct but unclear operations | HeartModelControls; adjustmentsPanel; both toolbars | Partial: Reset model plus descriptions; granular operations retained |
| HV3-005 | Selection failure not reproduced | Targeted gestures; selectedLabel; collider generation | Partial: live mode status, invalid-sample handling; missed taps require headset |
| HV3-006 | Ergonomic hypothesis | HeartModelView viewport and toolbar | Removed secondary volume and upward offset; physical ergonomics pending |
| HV3-007 | Confirmed unowned close-up lifetime; entity leak not established | heart_v3App; viewer lifecycle | Separate-window lifecycle eliminated; cancellation and asset-scoped scenes retained |
| HV3-008 | Annotation helper exists but not attached to viewer | HeartModelScene annotations / relationshipRoot | Partial: selected-part origin line; full teaching annotation work remains |
| HV3-009 | Small captions confirmed; angular readability unknown | SpatialControls; fixed panel dimensions | Partial: tool captions/targets enlarged; large-text and device audit pending |
| HV3-010 | Background-dependent readability hypothesis | glassBackgroundEffect / secondary text | Remaining: contrast measurements in both environments |
| HV3-011 | Orientation widget already tracks quaternion; reference axes intentionally withheld | HeartOrientationCue; adjustmentsPanel | Remaining: headset recognition; no invented reference axes |
| HV3-012 | Confirmed tool vocabulary breadth | modelToolbar | Two-column stable tools; fixed Return part and recovery positions; novice acceptance pending |
| HV3-013 | Confirmed dense settings panel | adjustmentsPanel | Size, separation and Done pinned; secondary options scroll; slider regression passed |
| HV3-014 | Audio playback may be mistaken for anatomy animation | SpeechManager; narrationButton | Explicit narration affordance and best installed voice; no developmental animation claimed |
| HV3-015 | Navigation paths exist; physical comprehension untested | ContentView; GuidedLearningView; FreeExplorationView | Partial: close-up lifetime tied to navigation; breadcrumb work remains |
| HV3-016 | Neutral backdrop already exists; immersive environment is OS-owned | controls.showBackdrop; modelCanvas | Not reproduced: verify backdrop/readability on headset |
| HV3-017 | No crash established | scenePhase / gesture handling | Partial: clear gesture baselines on inactivity; collect device logs |
| HV3-018 | Model info accessible within viewer | informationPanel; HeartReviewStatus.json; ReferencesView | Existing review date/scope and validation limitations visible in context; source access available |
| HV3-019 | Modal suppression exists; physical overlap untested | modelViewport; showingInfo/Location/References/Adjustments; captions | Anatomy suspends behind secondary panels with transforms retained; headset check pending |
| HV3-020 | Small tool captions confirmed | SpatialToolButton | Larger labels/targets and non-colour selected checkmark; novice/device acceptance pending |
| HV3-021 | Isolation intentionally hides surrounding anatomy | HeartModelScene.apply; controls.isolate | Partial: explicit Show all status; context silhouette remains |
| HV3-022 | No undo found | gesture handlers; recovery actions | One-step drag/pinch/separation/return-part/reset undo; intentionally not a global editing history |
| HV3-023 | Confirmed answer in card, preselection and narration | GuidedTopicDetailView; HeartLessonStep; HeartModelView | Partial: blinded first-step workflow; UI conceal/reveal/retry passed; headset/educator acceptance pending |
| HV3-024 | Confirmed viewing-based completion, not mastery | HeartLessonProgress; catalogue | Partial: viewed wording, separate assessment records; no passive mastery awarded |
| HV3-025 | Content design gap | LearningTopic.cards; asset anatomyReview | Needs clinical approval: mechanism-to-failure links |
| HV3-026 | No validated unseen clinical representation found | Resources / HeartAssets | Needs clinical approval: licensed depiction and interpretation |
| HV3-027 | Snapshots and narration are explicit in existing content | LearningCard; HeartLessonStep | Needs clinical approval: validated time correspondence and predictive transformation |
| HV3-028 | Try this prompts exist; response evaluation absent | lessonPanel; HeartRecognitionAttempt | Partial: purposeful coarctation localisation; other modules unchanged |
| HV3-029 | Pose preserved but fitting recalculated per visible state | HeartModelScene.fit | Common comparison envelope locks scale, centre and depth across states; runtime assertion added |
| HV3-030 | Transition legend already includes words/roles | transitionGuide; selectedLabel | Remaining: greyscale validation and additional structural cues |
| HV3-031 | No previous challenge evaluator found | HeartRecognitionAttempt.feedback | Partial: branch/remnant/generic responses, retry/hint/reveal; educator review pending |
| HV3-032 | No delayed retrieval scheduler found | HeartRecognitionReview; catalogue | Optional local review scheduling and separate later-recall evidence; only coarctation is scored; no validated retention claim |
| HV3-033 | Dense cards confirmed | lessonPanel | First-view observation/action with optional Explanation; bounded transcript; device readability pending |
| HV3-034 | Existing caveats; anomaly class not always visible | model header; informationPanel; anatomyReview | Partial: schematic badge for anomalies; per-claim approval metadata remains |
| HV3-035 | Multiple numeric referents confirmed | phaseNavigation; lessonPanel; catalogue | Named step/phase referents, congenital card IDs removed, explicit Listen; learner comprehension pending |

## Patch boundaries

- Spatial/recovery: HeartModelZoom.swift, HeartModelView.swift, HeartAssetValidation.swift; HeartCloseUpView.swift removed.
- Clarity: SpatialControls.swift, viewer status and source badge.
- Learning: HeartRecognition.swift, GuidedLearningView.swift. Existing medical explanations retained; no new clinical mechanism authored.
- Regression: Tests/SpatialPolicy/main.swift and HeartV3UITests/HeartV3InteractionTests.swift.

## Verification results

- Initial visionOS simulator build: passed.
- Portable resize policy: 20,000 extreme/invalid/repeated samples passed.
- Final simulator build and test build: passed on visionOS 27.0.
- Live RealityKit regression on visionOS 26.5: all 16 teaching assets and seven reference assets passed; saved progress and separation interruption/reversal checks passed. See verification/asset-validation.json.
- Five UI regressions passed: developmental/anomaly navigation, full reset/undo, guided phase recovery, home/references navigation, recognition concealment/hint/reveal/retry.
- Final affected-test rerun: reset/undo (including leaving an open close-up via Home) and recognition both passed.
- Portable assessment tests passed: invalid/incorrect/correct selections, branch/remnant feedback, hinted/revealed responses, persistence and prior-study distinction. See verification/policy-tests.txt.
- Visual inspection caught initially off-screen response controls. The unanswered task now has a compact panel with the question and pinned Confidence/Commit/Hint/Reveal controls. The affected UI regression passed again on this final layout.
- Final compact challenge panel visually inspected: question, instructions and response actions visible without scrolling at default simulator layout. See verification/coarctation-before-response.png. This is not a headset ergonomics pass.
- git diff --check: passed.
- Original device recordings were not replayed on headset; no physical tracking, reach, clinical-transfer or retention outcome is claimed.

## Required clinical review

Confirm the intended selectable boundaries on anterior/posterior isthmus meshes, branch/remnant corrective feedback, and interpretation of this simplified cutaway. Choose a licensed unseen representation and its scoring rubric. Do not equate a second view of this mesh with clinical transfer or a correct practice response with durable mastery. No new coarctation etiology or hemodynamic explanation is claimed.

## Final automated results — 24 October 2026

All 13 named UI checks passed across the full regression and targeted reruns, including progression through all 16 lessons, review answer concealment and returning from in-context sources. The initial full run itself was not green: optional XCTest screenshot capture was unsupported, then the simulator could not foreground the app for four later cases. Those affected checks passed on bounded rerun. The final narration/recovery layout was tested separately after its correction. All 23 model validations and portable policy tests passed. See verification/remaining-tests.txt for per-test evidence. Device and clinical acceptance remain outstanding as specified in the handoff.

## 24 October — research-informed learning pilots (new brief)

- HV3-027/033/035: cushion fusion now has Observe, Predict, Reveal, Explain and Retrieve beats. Uses existing discrete states with explicit representation limits. Optional questions reveal rationale only after response or deliberate explanation reveal; comparison is unavailable before Reveal.
- HV3-023/024/025/029/031: coarctation starts with an open normal reference, then blind localisation, matched comparison, qualified explanation and another concealed practice attempt. Changing back into a recognition beat clears its prior target/reveal. Focus is disabled when a beat intentionally has no target.
- HV3-026/034: clinical consequences and plural developmental hypotheses carry expert-review notices. The final task explicitly remains same-model recognition. Unfamiliar clinically validated representation and efficacy evidence remain deferred.
- HV3-028: dismissible stage-specific investigation prompts in Free Exploration. No new anatomical assertions or forced assessments.
- HV3-032: optional prediction and recall records are local and separate from lesson visits; skipped questions never score correct. Existing delayed coarctation review is retained. Old saved step indices migrate to the updated pilot sequences without changing other lessons or completed status.
- Presentation: new file only, per user clarification. Original iCloud HEARTV0.pptx remains untouched. Verified baseline counts and research limitations are in RESEARCH_ITERATION.md. A formative study protocol is in FORMATIVE_EVALUATION.md.
- Verification: first five targeted pilot UI tests all passed; model validation passed all 23 assets. Final safeguard/repeated-reassembly checks and deck verification are recorded in Documentation/verification when complete. Device acceptance and expert approval remain outstanding; this entry does not close all original audit tickets.

Final research-pilot checks: all three final UI checks passed, covering coarctation's normal-first flow, prediction/recall and repeated separation/reassembly. Together with the initial run, six unique targeted checks passed. Final live validation passed all 23 assets and saved-progress migration. Portable tests passed. Presentation follow-up: user will supply videos; the separate revised deck contains editable footage spaces, with no embedded videos. Active deck untouched.

## 24 October — development-first school prototype

User explicitly superseded the clinical-review handoff requirement. The new direction is documented in DEVELOPMENT_REDESIGN.md; references in MODEL_REFERENCE_LIST.md.

- HV3-025/028/031: linked normal developmental processes to anomaly exploration in four stage contexts and corresponding guided lessons. Return preserves the developmental selection.
- HV3-026/034: integrated three downloaded 3D Heart Project specimen models as separate later-anatomy references with attribution and representation labels. These are not embryonic morph targets or a validated transfer assessment.
- HV3-027: added a real continuous tube-looping mesh illustration, reversible scrub/play/open-wall/reset. Full timeline still outstanding; do not mark closed.
- HV3-014/023/033: repaired speech callback compilation defect, paused label, UTF-16 caption ranges, background speech lifecycle and concealed-check narration.
- Verification pending below; headset ergonomics and realistic visual acceptance still require inspection.

Verification for this increment: simulator build succeeded. Four final UI tests passed (stage return, all three downloaded model loads/switching, looping scrub/open/reset, existing recognition concealment). Concealed-check narration passed in the initial run. The initial run's three failures were corrected: stale stage-label assertion, absent accessible loading-state marker, and the wall toggle's accessibility role. Portable policy checks passed, including 9,797 intermediate looping centres. No headset performance pass or full-timeline completion is claimed. See verification/development-connected-final-tests.txt and development-connected-policy.txt.

### Looping controls follow-up

HV3-008/009/019/027: reduced morph framing after screenshot inspection found heading overlap; added a dedicated 44-point slider control surface, clearer backing, and suspended morph rendering/playback behind exploration popups. The affected simulator scrub/open-wall/reset test passed (35.309 seconds) after a previous drag failure. Added the same scrubbable transition to the guided D-looping lesson, with a return action that preserves lesson position. Guided-path verification is recorded separately in verification/guided-looping-test.txt.

Final guided-looping test passed. Both revised exploration controls and guided return path are verified in the simulator. This does not close the full-timeline work.

### Continuous bottom timeline — HV3-027/035

Replaced integer-only timeline storage with bounded fractional positions on the implemented tube→loop interval. Bottom scrubbing drives mesh geometry directly and removes the duplicate local slider for that interval. Remaining intervals retain explicit stage snapshots. Added policy checks for invalid values, boundaries, stage lookup and morph mapping; added UI regression for scrubbing and popup return, plus existing full stage/anomaly navigation.

The bottom-timeline and full stage/anomaly navigation UI checks passed (2 tests, 122.915 seconds). Follow-up HV3-021/027: corrected Previous/Next skipping an endpoint when rounding an intermediate position; corrected the looping title persisting into anomaly mode. Endpoint policy regressions pass. HV3-025/035: added the whole-heart entry on Home and revised entry descriptions to orient unfamiliar viewers around development and congenital differences. Final home/timeline/guided verification recorded in TESTING.md.

HV3-008/009: a new simulator screenshot still showed the procedural tube touching its description. Removed the extra converted-frame-centre offset, placed the model at the flexible RealityView's scene origin, and kept it behind the controls plane. This replaces the previous size-only adjustment. The guided regression now explicitly starts on phase 1 and asserts that phase on return, avoiding dependence on saved progress from earlier runs.

### Morph continuity and surface shading — HV3-008/027/035

- Confirmed endpoint defect: Free Exploration used the procedural mesh only strictly between stages 2 and 3, replacing it with static anatomy at either endpoint. The shared mesh now remains active through both endpoints. Detailed anatomy remains an explicit alternative at those stage stops.
- Playback now drives the same bottom timeline; manual scrubbing, popups, backgrounding and Reduce Motion stop playback. Animation uses elapsed time rather than assuming every frame arrives on schedule, with bounded catch-up after a stall.
- Surface lighting normals now come from deformed triangles, including taper. Duplicated rim vertices retain crisp cut faces; closed circumferential seams share normals. Cutaway edge winding corrected on the second edge.
- Added actual surface validation across 42 closed/cutaway states for stable connectivity, finite unit normals and noncollapsed triangles. This does not prove absence of all self-intersections or anatomical fidelity.
- Full eight-stage morphing is still incomplete; this increment improves the continuous tube-loop segment without substituting a crossfade for missing geometry.

### Paired-tube joining segment — 25 October, HV3-027/035

Extended the bottom timeline's continuous interval from stages 2–3 to stages 1–3. A new procedural surface shows two hollow tubes approaching, with buried wall arcs removed as the outer surfaces and inner channels join. This is a geometric teaching illustration, not a simulation of cellular fusion or embryonic body folding. The final centreline, radii and local cross-section frames match the start of the looping surface. Tiny decorative relief was removed from the latter to avoid a seam at the shared endpoint.

The same viewer, timeline and playback span joining and looping; detailed anatomy remains accessible at stage stops. Wall opening is available after joining; during joining the button is disabled with an explanation. Later developmental stages remain static. Surface and UI checks are recorded in TESTING.md.

### Shared animation access and UMCG anatomy — HV3-025/026/027/031/034

User verified the build and prioritised models/animations over UI polish. Joining+looping is now accessible from Guided Learning's paired-tube and primitive-tube lessons, while the D-looping lesson retains its focused looping range. Shared playback/scrubbing and return preserve lesson progress.

Downloaded and retained original UMCG neonatal, ASD and VSD USDZ assets. Added source-specific creator attribution. Atrial and ventricular developmental connections open their corresponding UMCG models from both learning modes; ASD/VSD/Fallot anomaly lessons also expose their detailed source examples. These remain explanatory views, not blind diagnostic scoring tasks. No active deck or slide-video work.

Added the UMCG four-chamber AVSD example as a later anatomical reference for the cushion lesson. Its entry is unavailable during initial observation/prediction and unanswered retrieval; the normal/altered reference does not silently reveal an assessment answer. The source mesh retains its source materials and CC BY-NC-SA attribution. Existing cushion before/after assets were inspected: they use different boolean-generated topology, so they are still discrete states, not claimed as a completed septation morph.

### Developmental reasoning inside the animation — HV3-023/027/032/035

Added an optional shared Predict → Observe → Explain activity to the joining/looping viewer in both learning modes. Joining asks learners to predict the shared channel; looping asks whether continuity changes when the tube bends. Explanations appear only after a response or explicit reveal. Returning preserves the exact animation position; opening the activity pauses and hides the underlying animation. Feedback directs a reversible observation and an explanation in the learner's own words; no clinical mastery score is awarded.

HV3-026/034: visual inspection caught the neonatal reference rendering white. Confirmed no textures in its downloaded USDZ. Added a uniform, explicitly labelled tissue-colour material in the runtime viewer to improve depth cues without inventing anatomical region boundaries. Source geometry/file unchanged; adaptation recorded under the source's CC BY-NC-SA licence. Other references retain their own materials.

### Reference-model materials — HV3-026/034

Inspected all UMCG materials in Blender. ASD has neutral white/grey materials without textures; four-chamber AVSD has a neutral grey, maximally rough material without textures. Extended labelled tissue shading to these two assets. Added reversible source-appearance switching for neonatal/ASD/AVSD without reloading or transforming geometry. Preserve VSD's texture maps and TGA's source colour differences. This is an appearance adaptation under the source CC BY-NC-SA licence, not recovered source tissue colour. Material evidence: HeartAssets/external/umcg/material-inspection.json.

HV3-008/009 follow-up: simulator visual inspection of the AVSD reference found its geometry above the viewport, touching the model selector. The reference viewer was adding a converted frame centre even though flexible RealityView already centres its origin. Removed that duplicate offset and placed the rotation-invariant model envelope behind the controls plane. This is a model-placement correction shared across imported references.

### Imported anatomy inspection — HV3-008/009/019/027/034

The shared reference viewer now offers a slow, user-started rotation (one revolution per 30 seconds) in both guided and exploration entry points. Manual dragging, Reset view, model switching, leaving the viewer, backgrounding and Reduce Motion stop automatic rotation. Switching source models restores the fitted scale and neutral orientation; source-appearance choice remains reversible. Elapsed-time motion caps stalled-frame catch-up. This is a viewing animation, not a developmental morph.

Reference framing and reversible material regression passed before the rotation addition: verification/reference-framing-tests.txt. Visual check in verification/avsd-framing-final.png confirms the AVSD model no longer overlaps the model selector. The source's initial orientation is retained; a useful anatomical view still requires rotation. Full later-stage developmental morphing remains unfinished.

Rotation follow-up: moved per-frame rotation state into the reference viewport after a simulator switch failed during playback. The containing selector/material controls remain stable while geometry rotates. Final affected regression passes (42.176 seconds); see verification/reference-viewport-rotation-tests.txt. Reset view uses its own reference.reset accessibility identifier to distinguish it from the underlying exploration toolbar.

### Shared model visual language — HV3-026/027/034/035

Confirmed code-level inconsistency: lesson anatomy used a shadow-casting key light, while imported references and procedural morphs used environment lighting only. Morph tissue used a brighter pink than both the imported tissue override and the baked lesson palette. Replaced those separate configurations with HeartModelStyle and HeartModelLighting.

All three live viewers now share the cached studio environment, fixed key light and nonmetal tissue finish. Texture-free tissue overrides and morphs use the baked lesson muscle colour. Scalar-only roughness is harmonized; authored texture maps, region colours, transparency, cut-face settings and unsupported shader types are preserved by the style helper. Existing lesson selection emission and transition colour legends remain intact. Both learning modes use these same viewers.

All eight developed-reference models now have reversible consistent/source material appearance. Only the three previously inspected, texture-free UMCG models receive uniform tissue colour; other specimens retain their colour distinctions. Source meshes and files are unchanged. Different specimens and atlas regions remain different anatomical representations, not a matched morph series. Existing raster thumbnails and home illustrations are outside this live-rendering change. Validation results will be recorded in TESTING.md.

User-directed follow-up: removed the original/source appearance switch and its explanatory row. The shared appearance is now applied once as each imported model loads, in both learning modes. Source attribution stays available; adaptation details live in MODEL_REFERENCE_LIST.md and MODEL_VISUAL_STYLE.md. Original USDZ files remain unchanged. This supersedes the earlier reversible-toggle UI description.

Visual follow-up: a screenshot of the typical-heart reference showed bright region colours still competing with the shared tissue palette. Added a hue-preserving cap on saturation (0.55) and brightness (0.72) for untextured non-neutral regional colours in the reference/lesson viewers. Texture maps and alpha remain intact; birth-transition colours are still set explicitly to match their legend. Added palette idempotence and preservation checks. Source meshes, original files and downloaded textures remain unchanged.

The typical-heart regional palette is baked into a source colour texture, so the untextured-only saturation adjustment did not affect its screenshot. Added bounded neutral texture modulation for developed references only (maximum tint RGB 0.65), keeping original texture pixels, UVs, alpha and map detail. This avoids flattening a textured specimen to a uniform colour and does not darken it again when styling is repeated. Existing baked lesson textures remain unchanged.

### Outflow morph and contextual anomaly branches — HV3-025/027/031/032/035

Added a continuous regional outflow cushion/partition illustration, using stable loft topology based on the existing build_batch04 geometry. The outer conduit stays fixed while opposing cushions expand into a partition. Both wall panels/cutaway and shared studio materials remain available. The quarter-turn is a geometric viewing convention, not a measured rotation or a simulation of the cause of TGA.

Free Exploration now scrubs continuously through the stage-5-to-6 outflow interval, with a detailed-anatomy alternative at its endpoints. Guided outflow has the same animation, a concealed prediction/observation check, and a route into related anatomy. Contextual connections now cover ASD, AVSD, VSD, Fallot, TGA, coarctation and PDA. Related branches can overlap in the timeline; birth shows ductal persistence and arch consequences, not an assertion that coarctation first forms at birth. Branch explanations include a process window and explicitly avoid exact onset dating. Guided branch prompts are hidden during unanswered knowledge checks.

AVSD's branch embeds the downloaded four-chamber specimen with the same material/lighting rules; its source attribution remains visible. Existing anomaly browsing remains available. Numeric validation passes 82 outflow states with stable connectivity/material slots, finite unit normals and noncollapsed triangles; interaction and visual verification recorded separately in TESTING.md.

Outflow follow-up: visual inspection prompted a neutral -45-degree yaw and slight pitch for the regional cutaway, exposing the internal gap; Reset morph restores that useful default. Rounded percentage labels avoid 59% at nominal 60%. Fallot/TGA explanations now offer replay of normal outflow division and return to the same anomaly explanation. Guided aortic/pulmonary lesson concepts mention the related developmental connection so the lesson narration can include it.

### User-selected regional palette — HV3-011/026/027/034/035

User chose direction B (muted anatomical region colours) from live reference screenshots. Added shared named-region palette and fixed per-face region assignments through looping; the morph legend follows the displayed process. Matched explicit segment/atlas part names to the same colours in the detailed viewer used by both learning modes. Retained normal/roughness detail and layer lightness differences. Unknown/unsegmented parts do not receive invented regional boundaries. The texture-free wall colour now matches the palette's coral ventricular family. See MODEL_VISUAL_STYLE.md for the adaptation contract and limitations.

### Regional palette catalogue coverage — HV3-011/026/027/034/035

Confirmed missed mappings: AtrialWall/AtriumWall, VentricleWall, abbreviated HDBR vent, suffixed oft, sinus_venosus and vena_cava names bypassed the initial palette lookup. Added explicit anatomical aliases without recolouring unidentified context or assigning regions from shape. Paired-tube detailed wall layers now share the morph's coral family, preserving layer lightness and normal/roughness detail. The tissue default derives from the palette to prevent a second independent colour constant drifting.

Updated live asset validation to check installed regional colours. Its old CS11 source-red assertion was superseded by the user's selected runtime adaptation; original files remain unchanged. Added catalogue-name and material-preservation regressions. Consolidated MODEL_VISUAL_STYLE.md so it no longer presents the superseded deep-rose appearance as current.

Morph presentation follow-up: corrected the outflow legend and increased default model fit while retaining placement behind controls. The two affected UI tests passed before the catalogue extension; final catalogue verification is recorded in TESTING.md.

Verification complete for this increment: GPU material/geometry/policy suite passed; two catalogue/guided UI checks passed; compiled scene validation passed all 16 lesson assets and seven atlas assets with per-model counts of tested palette materials. Screenshot evidence and remaining perceptual/headset limitations are recorded in TESTING.md. This closes the catalogue mapping defect, not the full morphing timeline or all visual-fidelity work.

### Morph deformation repair — HV3-008/027/035

User asked to fix morphing and defer headset verification. Confirmed two geometry defects by sampling the actual swept surface rather than its centreline alone:

- Rebuilding every cross-section from cross(tangent, world Z) caused an approximately 44 mm vertex jump near 40% looping for a 0.5% progress step. Replaced it with parallel-transported frames.
- Linear interpolation of centreline positions compressed intermediate segments and inverted inner-bend wall faces. Now interpolate segment rotations and lengths, preserve the centre trajectory, and smooth curvature changes at the source spline knots. The latest diagnostic's maximum sampled step is approximately 2.41 mm; the automated fine-step sweep rejects inward-facing outer wall normals and collapsed centreline segments.

Joining and looping now use the same transported endpoint frames. Region colours ease in during the initial looping interval instead of jumping from coral to six colours at the topology boundary. The legend follows that reveal. Text reserves the same number of lines so a process-caption change does not resize the model area. Reversing into joining clears an unavailable cutaway, preventing it from unexpectedly reopening on forward return.

Added HeartMorphMeshCache: one mutable GPU mesh per topology, updating positions/normals rather than creating a MeshResource every frame. Faces are grouped once by their existing material indices. The live validation checks resource identity, forward/reverse vertex-buffer contents and complete face grouping. This follows Apple's LowLevelMesh API (https://developer.apple.com/documentation/realitykit/lowlevelmesh); no measured headset frame-rate claim is made.

These repairs apply through the shared viewer in Guided Learning and Free Exploration. They repair the implemented intervals; they do not add missing full-timeline developmental geometry. Simulator/policy verification is recorded in TESTING.md. Headset verification is explicitly deferred, not an implementation gate.

### Realistic anatomy inside Guided Learning — 26 October, HV3-025/026/027/031/032/034

Confirmed flow limitation: imported whole-heart models were primarily optional sheet destinations, while guided lessons retained only the schematic/reconstruction workspace. Added a lesson-scoped Later anatomy workspace alongside Developmental view. All ten development lessons now have an appropriate later-anatomy context; ASD, VSD, Fallot, TGA, AVSD/cushions and coarctation expose their available imported examples. PDA retains its existing teaching model because no corresponding realistic PDA source is installed.

The final explanatory phase opens later anatomy automatically for ordinary lessons; cushion/coarctation use their Explain phase. Learners can return without advancing or losing the mounted developmental scene. Normal and altered specimens switch within the same workspace with rotation, bounded scale and reset, shared materials and source attribution. Fitted specimens are explicitly not matched dimensional comparisons or embryonic morph targets.

Contextual Observe → Connect to development prompts and narration replace schematic-only manipulation instructions while the realistic specimen is active. Compatible lessons can replay their existing morph directly from this workspace; developmental anomaly branches remain available. The lesson's progress/completion and recognition scoring are unchanged. Viewing a specimen does not record a correct response.

Specimen access is hidden during unanswered knowledge/recognition checks, and throughout the cushion/coarctation opening observation/reference steps. Returning to retrieval removes the later-anatomy workspace. These gates have portable and simulator regression coverage, recorded in TESTING.md. No clinical-review handoff, slides or videos were created; headset verification stays deferred.

Guided integration follow-up: simulator accessibility inspection showed opacity alone left schematic controls exposed beneath the specimen workspace. Added content suspension within HeartModelView, retaining controls and the installed scene. Restoring the developmental view reattaches that scene rather than installing a duplicate model. Removed an inherited parent accessibility identifier that masked model loading/reset controls.

### Shared anatomy subsections and presentation credits — 26 October, HV3-019/021/026/034

User requested consistent models across modes, removal of the standalone whole-heart entry, Heart anatomy subsections within both modes, and removal of visible CC attributions. Removed the Home whole-heart button and the exploration Whole heart sheet entry. Both mode selectors now include Heart anatomy, embedding the same HeartProjectView with the same default typical-heart model. Existing lesson-scoped specimens and developmental/anomaly branches remain available.

The embedded collection shares HeartProjectViewport/HeartProjectScene with lesson specimens: identical source files, material harmonisation, texture preservation, lighting, fit/zoom, rotation and reset. Morphing still uses the same HeartLoopingMorphView and mutable geometry pipeline in both modes. This establishes mode parity for each model; it does not manufacture region segmentation or matching topology in unrelated source assets.

Removed visible CC/creator rows from reference, embedded specimen and atlas displays, and the CC-specific entries in the in-app reference page. Source metadata, downloaded originals, licence records and adaptation notes remain in Documentation/MODEL_REFERENCE_LIST.md and the asset folders for the user's separate credits. This supersedes earlier notes promising visible creator/licence rows.

Simulator screenshot inspection caught a presentation regression from moving the free-exploration viewer out of a sheet: its controls inherited no glass background. Added the existing rounded glass surface around the embedded subsection so labels remain readable against the room. Guided Learning already supplies its catalogue glass surface. Three navigation/style regressions and the full live asset validation passed; final surface verification is recorded in TESTING.md.

### Reversible model inspection and fidelity limits — 26 October, HV3-003/004/005/012/022/034

Confirmed gap: HeartProjectScene offered only whole-object rotation/zoom; imported specimens had no section, group separation or part movement. Added shared controls through HeartProjectViewport. Explicit source-parent mappings keep material/vertex export fragments together. Added reversible, three-axis geometric sectioning to imported, lesson and atlas viewers, retaining original resource identity on restoration and preserving source texture coordinates/material slots. Guided developmental part movement is now available outside recognition tasks. Interrupted separation/reassembly starts from displayed positions and cancels stale transitions; source-position tethers retain spatial context.

Introduced HeartSectionGeometry, HeartSectionCache and HeartSpecimenParts. Source models are unchanged. MODEL_CAPABILITIES.md distinguishes available source groups and section surfaces from missing anatomical segmentation, tissue layers and developmental correspondences. In particular, the unsegmented Fallot stays one source group; no arbitrary mesh-fragment explosion or fabricated tissue layers is presented as anatomy. Portable section/UV/normal/movement tests passed; live/UI verification follows in TESTING.md.

Visual follow-up: the initial depth envelope pushed specimens unnecessarily far back; fit now places the nearest original-surface bound just behind the controls and follows animated offsets. Section clipping does not change that envelope. Nested blood-pool/shell centres could also yield nearly identical radial separation directions. Distinct bounded inspection slots replace centroid-derived directions, with a regression requiring distinct directions for all multi-group specimens. These are inspection positions, not anatomical motion paths. Section preparation is cancellable and runs off the UI thread; reset prevents late results from changing the view.

Further visual diagnosis confirmed a coordinate-space defect: diameter was measured in the spin container while part offsets/rest positions used the scaled imported root. Some source roots therefore reduced the visible separation by their import scale. Rest positions, movement, separation and tethers now share spin coordinates. The live regression requires each group's displacement to equal 15% of the visible source diameter in its assigned direction; a merely nonzero movement is insufficient.

Final verification: all 31 static assets passed the strengthened live audit (specimen-inspection-final-assets.json), including exact visible separation distances and reset cancellation. Both-mode UI checks and final portable section/material/geometry policies passed. The corrected sectioned/separated typical-heart screenshot was inspected. Full-timeline morphing, unsegmented Fallot anatomy, missing histological layers and anatomical accuracy beyond preservation of the supplied sources remain explicitly incomplete in MODEL_CAPABILITIES.md. Headset verification remains deferred.

## Specimen transitions and morph manipulation — 26 October

Related issues: HV3-001/002 (bounded manipulation and control proximity), HV3-007 (scene ownership), HV3-014/027 (animation versus lesson progression), HV3-022 (view recovery without losing progress), HV3-034 (representation fidelity). This continues these issues; it does not close their headset or full-timeline acceptance criteria.

Confirmed in code: realistic-model selection recreated the entire viewer via `.id(model.id)`, discarding the displayed source before the replacement finished loading. The morph viewer allowed horizontal rotation but lacked the shared zoom range and vertical rotation. Cancelling specimen section preparation did not clear its pending indicator.

Implemented: one stable specimen presentation root retains the previous source while loading, names it in the loading/failure message, and performs a short fade-out/swap/fade-in. A request token rejects superseded loads; failed loads preserve the installed source and offer retry. Only one specimen root is installed. Reduced motion skips fades. Both anatomy subsections, guided specimens and reference previews use this lifecycle. Section cancellation clears pending feedback.

Morph viewers now have bounded pinch/slider resizing (0.4–2.5×), vertical and horizontal rotation, and Reset view independent of Reset morph. Manipulation pauses playback. Reset view preserves developmental position and open-wall state; Reset morph resets those explicitly. Placement uses the current cached surface envelope at the active rotation and zoom to keep geometry behind its controls. This retains existing source geometry, materials and morph topology.

Validation results are recorded in TESTING.md. These transitions do not interpolate unrelated specimen vertices or establish a biological trajectory between them. Compatible full-timeline geometry and missing source segmentation/tissue layers remain outstanding in MODEL_CAPABILITIES.md.

Transition verification: final three simulator interaction tests passed (174.080 seconds), portable policies passed, and live RealityKit validation passed all transition/failure/cancellation checks plus 22 morph-envelope frames and 198 control-plane placements. Evidence: verification/model-transition-final-ui.txt, model-transition-policy.txt, model-transition-assets.json. Headset verification remains deferred.

Visual follow-up: the first capture exposed a compressed morph viewport. Consolidated the title/prediction row and explanatory text, with a minimum geometry height of 220 points. Three affected morph navigation/manipulation tests passed after that correction. Load-failure feedback and retry now sit outside the 3D viewport’s ignored accessibility children, so assistive interaction can reach them; failed and loading states have distinct accessibility labels.

Final recovery check: the dedicated specimen failure/retry simulator test passed (verification/specimen-retry-ui.txt), including accessible error/retry, disabled inspection during failure, and restored controls after loading.

## Progressive wall inspection and shared resizing — 26 October

Related issues: HV3-001/002 (bounded spatial manipulation), HV3-004/022 (predictable recovery), HV3-014/027 (visible transformation versus lesson progression), HV3-034 (representation fidelity).

Confirmed causes: morph wall opening was a Boolean topology swap; there were no intermediate inspection frames. Anomaly reference previews fixed zoom at 1 and pitch at 0. Realistic specimen viewers lacked pinch resizing. Clearing the morph pinch baseline on Reset view allowed subsequent samples from the still-active gesture to resize the just-reset model.

Implemented: a cancellable 320 ms opening/closing transition, independent of developmental progress, shared by both morph-learning modes. Looping reveals the lumen along an increasing inspection wedge while preserving centreline/radius/thickness. Outflow progressively removes the anterior inspection panel while keeping the posterior wall and both cushions fixed. Partial cuts update existing GPU buffers; endpoint topology changes reuse cached resources. Reduce Motion applies the endpoint immediately. Wall inspection pauses developmental playback.

Numerical correction: close to full outflow opening, Float angle rounding collapsed 33 panel samples to only two distinct angular positions. The final 0.01% of the opening now uses the fully open endpoint, and the GPU topology key uses the same canonical value as the geometry. This prevents zero-area slivers and endpoint capacity mismatches.

All specimen contexts and procedural morphs now use one bounded pinch handler. It suppresses stale gesture samples after reset/suspension until the gesture ends, then starts from the visible scale. Anomaly reference previews gain two-axis rotation, bounded size controls and reset; opening the larger specimen and returning retains the preview size. Hidden embedded specimens disable their actual RealityKit root and interaction while retaining their viewing state. Source anatomy and materials remain unchanged.

Tests and visual checks are recorded in TESTING.md. These are inspection transitions; they do not add a biological process, tissue layer, or a new developmental morph interval. Headset checks remain deferred.

Verification complete for this software pass: final portable geometry/gesture suite passed; four integration UI tests passed, followed by a final dedicated wall test after the endpoint correction. The live report passes 22 wall frames, interrupted reversal/reduced motion, 22 developmental-envelope frames, 198 control-plane placements and specimen lifecycle checks. Evidence: verification/morph-inspection-final-policy.txt, morph-inspection-ui.txt, morph-inspection-final-ui.txt, morph-inspection-assets.json. Full-timeline correspondence, source segmentation and missing tissue-layer content remain listed in MODEL_CAPABILITIES.md.

## Independent specimen recovery — 26 October

Related issues: HV3-003/004/022 (spatial context and distinct recovery actions). Confirmed defects: the shared specimen viewport called scene.restore whenever its viewing-reset revision changed, so Reset view also removed sections and reassembled parts. Return part removed only manual offsets, leaving that component in its separated position.

Reset view now resets viewing size/rotation only. Reassemble returns all parts while preserving the selected section and viewing pose. A separate Restore model action closes the section and restores assembled component positions without changing viewing pose or lesson progress. Accessibility hints state these effects in every specimen context.

Return part now restores only the selected component to its assembled position, including when Separate is active; other separated components remain in place. Returning every component clears separation state, and Separate can start again. Reassembly and Restore model clear individual-return exceptions. Interrupted recovery continues to use the current displayed positions. Regression evidence follows in TESTING.md.

Recovery verification passed: final two-mode UI regression (119.189 seconds), verification/specimen-recovery-final-ui.txt; live source-position and recovery validation for typical heart and VSD, verification/specimen-recovery-assets.json. The existing morph and lifecycle checks passed in the same live run. These are simulator/software results; headset acceptance remains deferred.

## Tissue layers through joining and looping — 26 October

Related issues: HV3-003 (recoverable separation), HV3-014/027 (meaningful continuous change), HV3-034 (source fidelity). Confirmed gap: static early-tube assets name three tissue components while the procedural morph used one undifferentiated wall.

Implemented three nested, independently generated early-tube shells using the existing build_batch02 teaching proportions: myocardium, cardiac jelly and endocardium. All follow the same joining/looping deformation. Layer identity and regional colours remain attached while scrubbing forward/backward. The shared style supplies the same lightness differences as the named static layers. Progressive wall opening reveals the nested shells in looping. Separate/Reassemble layers translates them apart and back with interruptible easing; no layer is stretched to create inspection separation. Reset view preserves layer arrangement; Reset morph reassembles it. Both learning modes use the same renderer, controls and explanation.

The joining/looping tube uses the layered wall consistently; there is no alternate appearance toggle. Layer inspection controls are not offered on the outflow illustration. Visible text labels thickness/separation as illustrative; the information popover explains layer order and omitted regional remodelling. No unsupported layers have been assigned to imported specimens. Scientific/provenance references are in TUBE_LAYER_REFERENCES.md.

Layer verification: portable suite passed; final two-mode UI tests passed (146.027 seconds); live rendering audit passed 21 layered frames plus the prior scene/morph checks. Evidence: verification/tube-layers-policy.txt, tube-layers-final-ui.txt, tube-layers-assets.json. Headset performance/perception remains deferred.

Final layered preview inspection completed: assembled and separated cutaway screenshots saved under verification/tube-layers-assembled.png and tube-layers-separated.png. No medical completeness or headset acceptance is claimed.

## Morph context, observation flow and individual layers — 26 October

Issues: HV3-003/007/022 (spatial context/recovery), HV3-014/023/025/027/032 (progression, premature explanation and retrieval). Confirmed causes: morph state lived inside temporary views/sheets; answering the prediction immediately revealed its explanation; the three animated shells had only global separation.

Implemented workspace-owned morph sessions for guided lessons, free exploration (separate tube/outflow sessions), and process replays from anomaly branches. Progress, viewing pose, wall state and layer arrangement survive returning within that workspace; playback and gesture samples remain transient, so reopening does not auto-play. Sessions do not persist across app launches or claim completed learning.

Morph practice now separates Predict → Observe → Explain → feedback. A prediction does not reveal correctness. Comparing a span of timeline positions enables the explanation question; tiny accumulated jitter cannot qualify. This is an interaction prerequisite, explicitly not evidence of attention or understanding. Learners can deliberately reveal without completing practice; no answer or mastery is inferred from that choice. Practise again clears answers. Practice state is per process and survives morph dismissal. Questions concern visible continuity, layer inspection and the distinction between outflow division and ventricular attachment; no new defect mechanism is asserted.

The named early-tube layers can now be selected and moved within a bounded inspection envelope. Movement preserves shape/material identity and follows the active viewing axes. It animates from its current displayed offset, including reversal; Reset layer move restores that layer’s inspection slot, Reassemble layers clears every layer move and separation, and Reset view preserves the arrangement. Offsets remain attached during joining/looping and mode-subsection returns. GPU drawing bounds include the maximum moved envelope.

Performance follow-up: translating or reassembling layers was regenerating the tube frames and normals for all three shells on each inspection-animation frame. The renderer now caches the current deformation and applies only rigid offsets until development or wall opening changes. A live assertion checks that reassembly does not increment the deformation-build count, while retaining the same GPU resource.

Verification passed: the combined three-test UI run, final two-mode movement regression after optimisation, portable geometry/practice policies, and live GPU/scene validation. Evidence and timing are in TESTING.md; final live report is verification/morph-continuity-assets.json. The final separated-layer screenshot was inspected. These fixes do not close the outstanding full-timeline correspondence, later tissue-layer content, fine texture matching or headset acceptance work.

## Layer isolation and shared morph behaviour — 26 October

Issues: HV3-003/004/007 (independent visibility, arrangement and recovery), HV3-005 (selected-layer feedback), HV3-014/027/034 (traceable development and consistent representation).

Confirmed gaps: animated layers could separate/move but could not be isolated. Scrubbing into joining cleared the saved wall-opening choice. Individual-layer animation counted frames while other inspection transitions used elapsed time. The morph also recreated unchanged tissue materials during every rotation, inspection or later-looping update.

Implemented Isolate layer and Show all layers through the shared morph renderer. Only draw-part visibility changes: source vertices, normals, material indices, offsets, progress and the whole arrangement's placement remain intact. Choosing another layer while isolated switches the inspected layer. Reset view and Reassemble retain isolation; Show all layers changes visibility only; Reset morph restores all layers. Isolation survives temporary representation changes in both modes. No new anatomy is inferred.

The wall-opening preference now survives reverse scrubs into joining and returns during looping. Joining still has no open-wall geometry; its control remains unavailable while that process is displayed. Per-layer movement now uses the existing cancellable elapsed-time separation driver, including immediate reduced-motion changes. HeartMorphAppearance centralises the unchanged layered/outflow material rules and retains materials until the existing early-looping palette reveal actually changes. Visibility-only updates reuse existing GPU buffers, and stable visibility no longer reinstalls draw parts each frame.

The initial two-mode isolation/context tests passed. Final shared-animation, backward-timeline, outflow and live rendering results are recorded in TESTING.md when complete.

## Outflow component inspection — 26 October

Issues: HV3-003/004 (preserved whole/part relationships and independent recovery), HV3-014/027 (observation of developmental change). Confirmed coverage gap: the outflow illustration already contained a wall and two individually generated cushions, but its controls offered only wall opening and whole-model manipulation.

Added shared Separate components / Reassemble components controls to the outflow morph in free, guided and branch-replay views. The existing cushion shapes move rigidly to either side while the wall stays fixed. Developmental progress, wall opening, viewing pose and material identities are unchanged by separation. The arrangement survives temporary view dismissal and Reset view; Reset morph restores the default arrangement. Placement uses the separated surface envelope, and reassembly reuses the current deformation/GPU mesh. No tissue layer, named lineage or new anatomical segmentation is invented.

When separated, the visible reminder asks learners to reassemble before judging cushion contact. The observation practice repeats that instruction when relevant. This prevents the inspection arrangement from being read as failed biological joining. Independent cushion grabbing/isolation is not yet provided; this pass adds the shared separation/reassembly operation only.

Verification: the final three-test consistency run, two-mode outflow inspection test, portable geometry/session suite and installed live GPU audit all passed. The final audit checks 63 isolated-layer frames, 144 shared-style material comparisons and nine outflow inspection frames in addition to earlier regression coverage. See TESTING.md and verification/model-inspection-final-assets.json. No new full-timeline morph interval or late-stage tissue layer is claimed.

## Morph phase-boundary continuity — 26 October

Issues: HV3-014/027 (readable developmental transitions), HV3-034 (representation fidelity). Confirmed code cause: joining used linear convergence all the way to its endpoint, while looping began its bend with nonzero velocity. Their shared tube pose was continuous in position but the motion direction changed abruptly. Each animated wall layer also recomputed the same reference path and transported frames independently.

Added a shared cubic presentation-time mapping with zero endpoint velocity to joining and looping; outflow uses the same helper for its existing cubic timing. The mapping is monotonic and reversible. Authored endpoint shapes, topology, radii, tissue ordering and regional assignments remain unchanged. Percentages still represent illustrative playback progress, not measured growth rates or a diagnostic onset time. This improves the existing morph intervals; it does not add correspondence between unsupported timeline stages.

The reference straight/looped centreline paths are cached, and the three wall shells share one set of transported frames per development update. Each shell still generates normals from its own deformed surface. The same code serves both learning modes, including open walls, isolated layers and separated arrangements. Geometry, simulator and live rendering results are recorded in TESTING.md when complete.

Verification complete: endpoint/continuity geometry policies passed, both simulator traversal/lesson-return tests passed, and the installed live GPU regression passed. Evidence: verification/morph-phase-continuity-policy.txt, morph-phase-continuity-ui.txt and morph-phase-continuity-assets.json. Full-timeline correspondence and headset performance remain outstanding.

## HeartV0 core learning route after headset recording — 27 October

Evidence: `RETEST_2026-10-27.md`, recording 0:30–0:50 (transparent animation workspace), 1:20–1:40 (isolated anomaly phases), 1:50/2:30–3:00 (later specimens separated from process), 2:00–2:20 (static early lessons). Original issues HV3-007/022, HV3-008–016 and HV3-023/025/027/031/032/034 remain partially addressed, not blanket-closed.

Confirmed causes: the morph was an optional guided sheet, developmental branches were sheets, and branch previews used schematic assets even where bundled realistic references existed. The home literal still said HeartV3 and the app had no display-name override. The morph/lesson reading surfaces had low opacity over a bright environment. No crash or missed gesture is inferred from the new recording.

Implemented HeartV0 installed/home display name; animation-first entry for supported guided lessons and free exploration; a guided joining → looping → outflow route with independent session state per topic; inline related-anatomy branches that preserve the free timeline and guided context. The joining lesson stops at the joined tube rather than replaying the next lesson. Primitive-tube entry begins at the straight joined pose. The physical asset behind the bent-looking static primitive-tube view has not been replaced on a visual guess.

Branches use available realistic specimens, offer a typical-anatomy comparison, and withhold the structural explanation until requested. They state the developmental window and reuse existing sourced process/consequence content. Fallot and TGA can replay the related normal outflow process in the same workspace; this is not a morph that simulates the cause of either defect. Coarctation's recognition/normal-primer gates remain protected. Timeline changes close stale branches. No navigation action records mastery.

The primary reading surface is now dark and largely opaque; secondary phase controls are hidden during animation so they do not compete with playback. Existing static inspection tools, catalogue, detailed notes, reset policies and source files remain available. Tests and visual checks are recorded in TESTING.md.

### Recording follow-up: visible observation and explanation

Original issues HV3-011/014/025/027/034. Simulator inspection at the ordinary 1100×780 window confirmed the explanation button was below the visible sidebar and the TGA reference appeared small and pale. The branch now keeps Explain the connection above the scroll area and opens the newly revealed text at the top. Embedded references start at 1.3×, within the existing bounded range; Reset view returns to that same framing.

The TGA source material inspection confirms three texture-free source materials. It now shares the same coral tissue adaptation as the other unsegmented UMCG examples across both modes. No regional anatomy is inferred from POGING source-object names, and original geometry/material files remain unchanged. This does not make that specimen a complete, labelled developmental model.

Joining, looping and outflow now show progress-linked observation prompts in their shared renderer. The prompts describe the currently visible change and reverse with the scrubber. Scope statements remain visible, especially the distinction between outflow division and ventricular alignment. This adds guidance within the animation rather than a new detached lesson screen.

### Default-window control clipping

Original issues HV3-002/006/008/011. A final free-exploration screenshot (`retest-oct27/timeline-observation-updated.png`, before the fit fix) reproduced clipped Home/header and bottom timeline controls in the simulator. The shared morph viewport's 220-point minimum plus fixed surrounding rows exceeded the parent window's height. The viewport now flexes down to 120 points with tighter spacing/padding, keeping the navigation and playback controls within the parent. This addresses a confirmed layout constraint; it does not establish physical headset reach or readability. Added a UI regression checking full button bounds and hit-testing in joining and outflow views.

## Model prominence and applying animation practice — 27 October

Original issues HV3-002/004/008/011/014 (reachable controls and readable manipulation), HV3-025/027/031/032 (process, explanation and related anatomy). The previous window-fit change made navigation reachable but left a small model area. The always-visible size slider occupied a separate full row in the shared morph renderer.

Moved numerical sizing into a Model size popover on the playback bar. The current scale remains visible on its button, pinch-to-resize remains available on the model, and Reset view stays directly reachable. The same session, scale bounds and reset policy are used in both learning modes. Scope text and colour legend share a row only when their intrinsic widths fit; otherwise they stack. Neither source geometry nor anatomical claims changed.

Outflow practice feedback now offers Apply this to related anatomy. It dismisses the practice panel before opening the existing developmental branch in the same workspace. Returning retains the animation position and feedback state. The branch explanation remains concealed until requested. Skipped practice remains identified as skipped, and this navigation records no mastery or lesson completion. Joining and looping do not gain unsupported anomaly links.

Regression coverage includes viewport/control containment, size adjustment and view reset in both modes, and prediction → observation → explanation → related anatomy → return in both modes. See TESTING.md for results and screenshots.

## Spoken-feedback fixes and older layer behaviour — 27 October

Evidence: SPOKEN_FEEDBACK_2026-10-27.md. Original issues HV3-001/002/003/004/005/008/011/014/027/034. Read the V1/V2 placeholder projects and the real-part interaction code in commit 19ba238. Retained the established rest-position and bounded-offset principles rather than restoring old absolute scaling or model-attached UI.

Home and both modes now share a 1100×780 minimum. Reference anatomy has a direct Cross-section / Close section control and visible cut-direction choices, replacing its hidden section menu. Existing surface-only cuts preserve source geometry; no tissue is invented to fill missing surfaces. The known typical-heart blood pool remains centred while its enclosing myocardial shell is lifted locally; unidentified sources retain their generic grouping.

The live tube layers now retain the endocardial reference at the model origin, with nearby depth offsets for enclosing layers. Confirmed geometry issue: the procedural opening was centred around the tube's side. Its angular seam is now arranged so the inspection opening faces the default viewer, while the back-wall midpoint stays fixed. Surface radii, layer interfaces and developmental shape paths are unchanged.

Shared lighting uses less ambient illumination and a subtle rim light. Palette/source maps remain unchanged. A selection-first layer drag is being verified alongside existing directional controls; it must move only the chosen layer, retain progress and remain bounded. Testing and screenshots below determine acceptance; feature presence alone is not closure of the interaction issues.

## Emergency visibility recovery and anomaly routing — 27 October, evening

Issues HV3-002/006/008/014/034; evidence: Screen Recording Apple Vision Pro 27-10-2026 at 7.40.04 PM, 0:10–0:15 (large black rectangle), 0:35 (old VSD in Anomalies), 0:47 (shortcut), 1:05 (guided model). The experimental morph input target was a viewport-sized ModelEntity with a clear UnlitMaterial but no explicit transparent blending. It rendered as the black rectangle in front of the model. Removed the entire rendered target and unverified direct-layer drag option. Existing directional layer controls, bounded offsets, isolation and reassembly remain. This regression was introduced during the earlier input experiment and was not adequately caught by compilation/geometry checks.

Removed Follow development in 3D from the guided catalogue as requested. Individual guided lessons and their developmental animations remain accessible. Free Anomalies now routes VSD, ASD, Fallot, TGA and coarctation through the same imported-model renderer used in Heart anatomy. Guided ASD/VSD open the altered realistic specimen at entry; Fallot/TGA retain their realistic inline branches. Coarctation retains its normal-primer/recognition gates; its realistic representation remains available after explanation. PDA has no replacement specimen in the current bundle and retains its teaching model with the common tissue style.

The main workspace and separate guided window use a white backing and light colour scheme. Removed the opaque morph/branch panels; dark local controls and reading panels are light. A first attempt to place the white backing deep behind the scene was clipped in the simulator and was replaced with a normal window backing. Screenshot morph-white.png confirms both the white backing and visible anatomy. The black obstruction was the rendered input target; the earlier suggestion that all window-plane backgrounds necessarily occlude these RealityViews was not confirmed.

Surface finish work from the prior pass is retained: complete UV coordinates on joining, looping and outflow meshes; subtle repeatable grain and roughness maps using the older V0 authoring approach, independent of palette identity. The new maps are visual finish, not histology. Actual test outcomes are recorded in TESTING.md; no blanket completion or headset pass is claimed.

### Authored PDA pair and birth-context integration — 27 October, evening

User explicitly requested original models when a specimen is unavailable. **HV3-008/010/011/022/025–030/032/034**: added `PDA_Patent.usdz` and `PDA_Closed.usdz`, generated reproducibly by `HeartAssets/tools/build_pda_reference.py`. These reauthor the existing V0 regional vessel arrangement as smooth, tapered hollow networks; they do not modify an unrelated patient's heart to invent PDA. Aorta/arch branches, pulmonary arteries and duct/ligament are separately movable. Both meshes have real wall thickness; the patent state has bored mouths in both parent vessels, while the closed state restores their walls and has a solid remnant. Geometry validation checks manifold surfaces, positive volumes and a through-duct ray (clear when patent, blocked by both arteries when closed).

Uses the same muted arterial/teal/coral palette family and grain/roughness source as the morph. The first visual check exposed an almost-matte material (raw roughness map without the shared multiplier) and a frontal view that hid the duct. Corrected the exported roughness and shared oblique initial pose before acceptance. New anatomy remains a regional teaching reconstruction, not a scanned specimen, complete heart, histological segmentation or flow simulation.

Free PDA, guided PDA and the birth-transition related-anomaly branch use the same pair and controls. The birth lesson's later-anatomy comparison now connects normal fetal patency to closure after birth and persistent patency. Matched comparisons retain the view angle and cut plane. Open/closed source replacement fades; this is not claimed as a continuous developmental morph. Explanation remains hidden until requested. Source/reconstruction details are retained in documentation; no new attribution panel was added.

**HV3-010/020**: specimen movement tethers changed to dark grey for the requested white background. Texture-free VSD surfaces now receive the common tissue tint instead of remaining white against the workspace; textured source surfaces retain their maps.

Final visual follow-up found white-on-white native segmented labels despite the light colour scheme. Reused `SpatialChoicePicker` for embedded anatomy comparison, guided representation, PDA state and section direction. The current state and alternatives are now explicit text buttons on a light backing (**HV3-009/010/012**).

## Recorded contrast and control repairs — 28 October

**HV3-008/009/010/012/013/014/019/020/021**, new review issues 1–6, 8 and 11: inspected the 22:48 recording and traced white-on-white panels to glass foreground vibrancy applied over light backplates. Replaced nested glass on reading/control regions with shared solid surfaces, added contrast-tested tokens and four reusable control styles, and raised caption text to system secondary/footnote styles. Slice uses a vertical icon/one-line caption instead of a standard Menu label in a narrow cell. The specimen “blank bar” controls zoom; all specimen viewers now show Size and its multiplier. Ten truncated model tabs become a full-label grid chooser, with current title and a Model info popover. Guided cards wrap titles and grow with content.

Moved morph scope/region/layer notes into the existing information panel, with larger key dots and a two-column legend, leaving a taller padded model stage. Kept exact recovery behaviour and the two learning modes. The timeline/header share the eight existing stage anchors rather than a repeated interval string. No new scientific timing claims, oxygenation colours, product rename, external publication or commits were made. See `UIUX_RETEST_2026-10-28.md` for confirmed causes, scope and deferred proposals.

### Continued viewport alignment repair — 28 October

HV3-001/002/006/008/019 and new critique issue 3. Runtime measurement plus a temporary view border confirmed that an inherited 540-point viewport depth shifted the rendered stage relative to its caption. Explicit zero-depth SwiftUI layout and measured positive-depth mesh placement now keep the model visible in front of the opaque white backing. Teaching, specimen and morph renderers share this policy; the physical depth envelope is limited to 0.50 m. Previous comments asserting that negative local z guaranteed containment were incorrect once the inherited layout depth and opaque backing were considered.

Guided phase count and phase buttons share one compact row, giving anatomy more height. Phase selection, recognition concealment and saved progress are retained. No geometry, palette or scientific content changed. See UIUX_RETEST_2026-10-28.md and TESTING.md for evidence and remaining acceptance limits.

### Build 2 visual consistency follow-up — 28 October

HV3-009/010/012/013/014/020/021; Build 2 audit 1–4, 6, 7.2, 9–10: eliminated remaining native tinted bordered buttons in favour of the shared four-style system. Primary actions use white labels; information/navigation peers use neutral fills. Persistent tab/phase selection is now an inset white segment with an accent underline, distinct from tool selection. Removed redundant header/morph/caption wrappers, made home cards explicit, clarified the cranial orientation abbreviation, and gave popovers opaque white presentation surfaces. Disabled states retain readable neutral labels instead of fading to 40% opacity. Anatomical palette and teaching content are unchanged.

HV3-001/002/008/019 remain open for maximum-zoom projection. The experimental rendering portal was withdrawn because direct input could not be validated; its coordinate-tap diagnostic also failed on the baseline. It is not included in the production interaction path. See BUILD2_RETEST_2026-10-28.md for scope, evidence and remaining work.

Build 2 continuation, HV3-005/009/010/012/014/019: introduced a shared native `HeartSlider` for size, separation and developmental progression. A thin track and explicit resting position marker reduce visual dominance while retaining a 60-point control area, existing ranges and native assistive adjustment. Touch cancellation and accessibility increments preserve editing-start/end callbacks, so scrubbing pauses playback and does not strand its active state. Animation information now scrolls beneath a fixed Done header. Guided and free headers both omit redundant title backplates. See Build 2 test logs for the stale-test repairs and final verification outcomes.

### Model-only animation/coherence pass — 28 October

HV3-005/007/010/020 and the current model-smoothness request: reduced per-frame allocation and repeated circular/ring calculations in joining, looping and outflow generators. Exact sampled geometry/material/UV signatures are unchanged (189 frames). Mutable GPU meshes no longer trigger redundant component replacement. Specimen reveal and part layout use elapsed-time easing with cancellation, retaining their intended duration and recovery state. Morph material caching now restores the shared tissue appearance after entity/component recreation instead of leaving an empty material array. No app UI, navigation, lesson wording, anatomy palette, source assets or geometry resolution changed.

The additional flow-diagram request was handled as an audit. FLOW_DIAGRAM_CHECK_2026-10-28.md distinguishes present routes from incomplete morph coverage, selected-part explanations and missing correction content. Model-motion evidence and verification limits are in MODEL_MOTION_CHECK_2026-10-28.md; no headset-smoothness guarantee is implied.
