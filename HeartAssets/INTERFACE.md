# Spatial interface revision

Both learning modes now place the 3D content directly in a transparent plain window. The large enclosing glass panel and scrollable stack of model, settings and lesson cards have been removed.

Free Exploration has a floating title, a centered model, a compact tool dock and a horizontal stepped slider with all eight day labels. Guided Learning places the model beside a separate lesson panel; narration, captions and previous/next actions remain together in that panel. Only the text area scrolls when needed. Lessons are browsed in a grid with Development and Anomalies categories.

Parts opens a searchable tissue list. Cutaway, Separate, Isolate and Reset are direct actions. View opens the detailed size/separation sliders and surrounding-tissue toggle. Existing selection, layer visibility, lesson-linked focus, retry, reassembly, rotation and narration are retained. A two-hand magnification gesture is also available on the model. Headset gesture ergonomics still need review.

## Model positioning

RealityView now owns centering through `.realityViewLayoutBehavior(.centered)`. The entity fitting code uses the available width/height for scale, but keeps the holder at the origin rather than also applying a converted SwiftUI layout center. The larger presentation fits against the model's longest dimension. This resolves the previously empty model area in the simulator. A regression check verifies that moving the SwiftUI bounds does not translate or rescale the centered entity.

## Reference and verification

The supplied CDN video was blocked by the browser site policy and was not downloaded or viewed. The reference basis was JigSpace's official [Vision Pro control guide](https://www.jig.com/help-center/viewing-on-apple-vision-pro) and [object list viewer guide](https://www.jig.com/help-center/object-list-viewer-in-apple-vision-pro). The design adopts a clear model area, nearby instructions, compact navigation, and optional object controls. It does not add a full immersive space or reproduce JigSpace's custom hand-tracking system.

- Xcode visionOS Simulator build passed.
- Both modes were visually inspected in Device Hub; models render visibly in their new layout.
- All four compiled assets passed loading, part identification, cutaway/context visibility, isolation, separation, reassembly, reset and positioning checks (`simulator-validation.json`).
- Simulator coordinate clicks were unavailable through the UI automation tool, so end-to-end button/gesture input and headset behaviour are not claimed as tested. Existing controller behaviour is covered by the runtime checks above.

Debug launch arguments `--preview-exploration` and `--preview-guided` open the relevant mode for visual review. `--validate-heart-assets` runs the runtime regression checks. These are inactive during a normal launch.

## Pink theme and UI artwork

The shared accent is rose pink (#F59BB5), applied to timeline controls, lesson progress, selection states and actions. Free Exploration uses a native stepped slider, with the current date/name above and day labels aligned below.

Original Blender-rendered artwork replaces the home sphere and generic mode symbols: a rose heart emblem, an orbiting heart for exploration and a heart over an open book for learning. The visionOS app icon has separate heart, orbit and opaque background layers. The first four lesson cards show renders of their actual models; lessons without a model use decorative book artwork and retain their “Lesson only” status. These illustrations do not imply anatomical accuracy or complete pending models. The formerly empty References screen now links the existing model sources.

Editable artwork: `ui/HeartUI.blend`; repeatable generation: `tools/build_ui_icons.py`. The images are bundled in the app asset catalog. Functional navigation and manipulation controls retain familiar system symbols.

This revision passed the visionOS Simulator build, all image catalog references were verified, and the home screen was visually checked in Device Hub. Further screen capture failed with ScreenCaptureKit error -3811, so the revised slider and lesson thumbnails were not visually verified in this run.

Batch 03 adds a developmental-state switch above the model dock for the two septation models. These models have their own default angles and cutaway settings. The restored day slider and both new models were subsequently visually inspected in the simulator; this resolves the earlier screen-capture limitation for Free Exploration.

Batch 04 adds a model menu to Free Exploration when more than one asset shares a timeline stop. At Day 35, choose cushion fusion or ventricular septation; Day 50 opens outflow septation. The slider still has eight stops. Lesson thumbnails now have an optional explicit image name so shared timeline positions never select the wrong artwork. `--preview-guided --preview-lesson 6` opens ventricular septation for Debug visual review.

Batch 05 completes model coverage for all ten developmental lessons and all eight timeline stops. Day 50 offers outflow septation and valve refinement; Birth opens circulatory transition. Both new models have comparison-state controls, actual-model lesson thumbnails and a short presentation note explaining the spaced valve assemblies or gradual birth transition. Valve refinement was visually inspected in Guided Learning and Birth in Free Exploration. The final build and all ten compiled-asset runtime checks passed; headset input remains untested.

Batch 06 adds a compact Development/Anomalies selector to Free Exploration. Development retains the day slider; Anomalies presents the VSD/ASD model thumbnails. Both new lessons use the existing part dock and defect/intact state switch. Guided Learning adds three cards per anomaly with linked part selection, and the lesson grid uses rendered VSD/ASD thumbnails. Debug preview: `--preview-guided --preview-anomaly 0` for VSD or `3` for ASD; Free Exploration uses `--preview-exploration --preview-anomaly 0` for VSD or `1` for ASD (indices within the available model list).

Batch-06 visual review confirmed the VSD guided panel and ASD Free Exploration layout. The final build and twelve-model runtime checks passed. UI automation returned `noWindowsAvailable` for a coordinate click, so direct button/gesture input remains unverified.

Batch 07 adds Fallot and d-TGA to both modes, with four guided cards and two structural states per model. The anomaly chooser now uses compact labels and a horizontal scroll container, accommodating four rendered thumbnails without squeezing long lesson titles. Full titles remain in the header and accessibility labels. The developmental day slider is unchanged. Debug preview: Guided Learning anomaly indices `1` (Fallot) and `2` (TGA); Free Exploration available-model indices `2` (Fallot) and `3` (TGA).

Batch-07 review confirmed visible Fallot geometry and four-step panel in Guided Learning, plus TGA and all four anomaly thumbnails in Free Exploration. The final build and fourteen-model runtime checks passed. Direct coordinate-click automation remains unavailable (`noWindowsAvailable`), and headset gesture ergonomics are untested.

Batch 08 fills the final two anomaly lessons with coarctation and PDA, including four and three guided cards respectively. Free Exploration now has six anomaly thumbnails; a scroll reader brings the current selection into view and the horizontal scroll indicator is enabled. The existing day slider remains unchanged. Debug previews use indices `4` (coarctation) and `5` (PDA) in either learning mode.

Batch-08 review confirmed the coarctation model and four-step panel in Guided Learning, plus PDA in Free Exploration with its selected thumbnail visible at the end of the scrolled chooser. The final build and sixteen-model runtime checks passed. Controller checks cover both structural states and part operations; direct button input and headset gestures remain untested because simulator coordinate-click automation is unavailable.

## Approved interface batch 1 — 27 September 2026

The model viewer now places anatomical comparison controls above the model and combines selection feedback and model actions in one glass dock. Model notes and gesture help are available in Model Info. Separate becomes Reassemble while parts are displaced. View → Reset view restores rotation and scale without changing anatomical state, cutaway, selection or separation. Guided Learning also exposes Restore step, which restores that step's anatomical state, focus, cutaway, default asset angle, size and assembled geometry.

Each of the 51 guided cards now displays a pinned Try this action. The first twelve actions were rewritten to use the existing model controls instead of promising unavailable animations or signal markers. Explicit step definitions include state for shared parts, preventing a prior comparison state from leaking into the next card. Changing cards also resets the explanatory scroll position. Hide lesson removes the side panel and places narration and compact step navigation in the header, preserving model height. Show lesson restores the panel without recreating the model.

Free Exploration retains the pink eight-stop native slider. Day 35 and Day 50 show their two model choices directly above the slider. Anomalies now has previous/next buttons, a position count, and an All anomalies sheet containing all six rendered thumbnails. A modal overview or Model Info sheet temporarily suppresses the underlying 3D geometry, preserving its controls and loaded scene; otherwise deep RealityView content can render in front of the sheet in a plain window.

Validation: the final visionOS Simulator build passed. All sixteen compiled assets passed the existing runtime checks, plus 51 step restoration checks covering visible focus, correct state, reassembly, view restoration and camera-only reset preserving inspection choices. See simulator-validation.json. Visually inspected the open comparison step in Guided Learning, the final collapsed header, Day 35's slider/model choices, and the six-anomaly sheet after correcting model occlusion. Simulator coordinate clicks still fail with noWindowsAvailable; launch previews verified presentation states, not end-to-end button input. Headset gesture and accessibility ergonomics remain untested.

Additional Debug preview flags: --preview-step N (zero-based), --preview-hide-lesson, and --preview-all-anomalies. Existing preview mode, stage and anomaly flags still apply.

Scope remains the approved first batch. A persistent grouped anatomy inspector, completion/resume flow, narration preferences and a volumetric presentation are deferred for subsequent approval.

## Screen recording review — first implementation batch, 7 October 2026

The shared model viewer now makes imported tissue materials opaque while preserving their existing colours and textures. Selection adds a warm gold highlight without fading surrounding anatomy. View offers explicit Transparent tissues and Model backdrop toggles; those display choices survive guided-step restoration. The subdued backdrop starts enabled.

Fitting now measures visible anatomy after state changes, rotation, separation and isolation. Width, height and depth constrain scale, with additional clearance for perspective. The model is recentered locally and lifted just in front of its backdrop. RealityView uses flexible layout so initial automatic centering cannot retain an offset from an earlier anatomical envelope. Converted SwiftUI frame offsets are not reapplied to the local entity origin. Apple's [layout documentation](https://developer.apple.com/documentation/realitykit/controlling-the-layout-behavior-of-a-realityview) explains that automatic centering is evaluated after initial loading, rather than after subsequent updates.

A Focus action beside the selected name isolates and enlarges that tissue; Show all returns to surrounding anatomy. Selecting a posterior teaching panel enables cutaway so its structure can be inspected. Reset is directly available in both modes and restores the viewing angle and size; Restore step remains available in Guided Learning. View includes Front, Back and Top presets. Rotating is less sensitive, a drag takes precedence over selection, and two-hand resizing temporarily suppresses selection and rotation.

Debug visual previews now support --preview-separated and --preview-focus. Runtime verification covers opaque materials across all sixteen models, optional transparency, focused versus whole-model fitting, rotated separated geometry at maximum zoom, backdrop depth, display preferences, and the existing fifty-one guided restoration checks. Results are saved in interaction-review-validation.json. Visual review covered cushion fusion in Guided Learning, separated outflow anatomy in Free Exploration, and focused valve anatomy in Guided Learning. Simulator visual previews and controller checks do not establish headset gesture ergonomics.

Remaining review items include labels attached to anatomy, anatomical orientation markers and a regional locator, contextual lesson actions and transition animations, and further simplification of the lesson/timeline layout.

## Screen recording review — second implementation batch, 7 October 2026

Selected tissues now have a native RealityView label, a gold target marker and a leader line. The attachment follows the selected tissue's bounds after fitting, rotation and separation; it stays upright independently of model rotation. Labels are hidden when selection is cleared, their target is hidden, the label preference is off, or a modal covers the viewer. Label size does not affect model fitting.

Guided Learning's pinned Try this area now includes Focus and Show layers actions, plus Compare states for assets with multiple anatomical states. Focus restores the current card's target/state and isolates it. Show layers restores that card, separates tissues and uses cutaway when available, selecting the matching posterior panel where necessary. Compare cycles available states while retaining viewing angles and clears stale selection/isolation. Repeated requests have independent identities so pressing the same action twice works. Normal step restoration preserves label, orientation, backdrop and transparency preferences.

A compact orientation cue in the model control dock rotates with the anatomy. Its axes come from the asset manifests: L is anatomical left, Cr is cranial, and A is anterior. The first three developmental schematics instead show Cr and V (their documented viewing side). View's presets use matching terminology. The cue and selected label can be turned off in View; detailed controls now scroll within a bounded popover.

Validation now attaches each test model to a live RealityView scene under an invisible host. This supersedes earlier geometry-fitting checks performed outside a live scene: RealityKit can return empty visual bounds for inactive, off-scene entities. The updated checks require active, non-empty geometry and exercise all sixteen models and all fifty-one guided steps, including annotation attachment/hiding, target rotation, Focus, Show layers, Compare, restored preferences, material opacity, fitting and backdrop clearance. Results are recorded separately in interaction-review-batch02-validation.json. --validate-heart-assets opens a viewer when no other preview mode is specified; --preview-layers is available for visual review.

Headset gaze/pinch ergonomics and end-to-end physical interaction still require device testing. A registered whole-heart locator, developmental transition animations and further timeline/lesson layout simplification remain outstanding.

## Screen recording review — third implementation batch, 8 October 2026

Free Exploration now places its stage/anomaly navigation above the viewer. Development retains the eight-stop pink slider, adds comfortably sized previous/next controls, and shows the current day and stage together. Stages opens a scrollable list for direct selection. Models sharing a stage still have a segmented selector. The previous strip of small date labels has been replaced by the labelled stage list. Anatomy is suppressed while either overview sheet is open.

Location is available in the shared viewer for all sixteen current assets. Early-stage guides use the stage artwork and explanation; later guides highlight atrial, atrioventricular, ventricular, outflow or great-vessel regions in a labelled chamber schematic. Valve guides mark both junction and outflow regions and explain the deliberately spaced assemblies. The guide explicitly states that its positions/proportions are schematic. It provides conceptual context, not mesh registration or a claim that separately authored regional assets share whole-heart coordinates.

Separation and reassembly now interpolate over 0.32 seconds. New requests cancel the previous transition and start from its current position, enabling smooth reversal. The viewer refits visible geometry and updates its annotation at every presented value. Changing anatomical state or initially presenting an asset sets the separation directly; discrete developmental snapshots are not morphed. Reduce Motion makes separation immediate, including when enabled during a transition. The SwiftUI task is cancelled when its viewer disappears.

Guided Learning's pinned inspection actions are now a single neutral row (Focus, Layers, Compare when available), with the current instruction still directly above them. This reduces repeated pink emphasis and returns space to the scrollable lesson text. Narration and caption controls share the lesson header rather than taking a separate footer row. The underlying lesson actions are unchanged.

The visionOS simulator build succeeded. Live regression checks passed for sixteen models and fifty-one guided steps, plus 140 intermediate separation/fitting cases across the available states. Transition checks cover intermediate motion, cancellation, reversal, and immediate presentation for reduced motion. Results are saved in interaction-review-batch03-validation.json. Visual previews covered the development navigation, the valve location sheet, and the compact guided lesson action row. Native click automation in Device Hub returned noWindowsAvailable, so preview modes were used for visual QA; this does not establish end-to-end headset interaction.

New Debug preview flag: --preview-location opens the current model's guide. Physical gaze/pinch reachability remains a headset check. A geometrically registered whole-heart locator and continuous developmental morphing require additional coordinated anatomy assets; neither is implied by the schematic guide or inspection animation.

## Expanded close-up inspection and Reset view — 8 October 2026

The shared viewer now offers Close-up above the model and in View controls. Enlarging beyond the normal overview range with a two-hand pinch opens the same close-up presentation once per gesture. It copies the current anatomy state, selected tissue, cutaway, separation, isolation, viewing angle and display preferences into a dedicated 1.1 × 0.85 × 0.9 metre volumetric window. Its model-size slider and pinch gesture share a 0.4×–4× range. Native window movement brings this 3D volume toward the user; rotation and tap selection remain available. Focus/Show all, Cutaway and anatomical-state comparison are available in its control bar.

The regular lesson/exploration canvas keeps its overview limit to protect adjacent controls. Simply enlarging its deeply protruding geometry caused clipping and obscured recovery controls during visual testing. Apple documents the depth limits of ordinary windows in its [window guidance](https://developer.apple.com/design/human-interface-guidelines/windows) and the fixed physical scale of [volumetric windows](https://developer.apple.com/documentation/swiftui/windowstyle/volumetric). Larger inspection therefore takes place in the dedicated volume. At high zoom, the volume bounds can crop anatomy intentionally for close-up inspection.

The close-up bar is an ornament anchored above the volume at its front edge. Maximum-size anatomy cannot cover the Reset view control. The main dock's existing Reset is now explicitly labelled Reset view, with the same command also in View controls and the close-up bar. Reset restores size to 1× and the asset's default angle, clears gesture starting values, and briefly suppresses accidental selection. It preserves anatomy state, tissue selection, cutaway and isolation. The close-up bar also has a close button to return to the original lesson or exploration window.

Fitting distinguishes a flat canvas's backdrop depth lift from a volume's centre. At increasing close-up zoom, the selected tissue becomes the centre of inspection; at 4× it is centred in all three volume axes. Returning to 1× restores the normal model centre. Gesture/slider/renderer share zoom bounds so the renderer cannot silently retain the former 1.25× ceiling in the close-up.

The simulator build succeeded. Live checks pass for all sixteen assets and fifty-one guided steps, including 84 close-up zoom cases, volumetric centring, returning to normal centre, copied-setting serialization, maximum-size camera resets and preserved anatomy choices. Results are saved in zoom-close-up-validation.json. Visual QA checked the ordinary viewer's labelled Reset view button and maximum-size valve anatomy with an unobscured front control bar. Native click automation did not establish a successful end-to-end reset tap; numerical reset behavior is covered by live regression checks. Headset gaze, two-hand gestures and physically moving the volume still require device testing.

Debug previews: --preview-close-up opens the inspection volume once the current viewer has loaded; --preview-zoom N sets its initial size when combined with that flag. Without the close-up flag, preview zoom remains within the overview range.

## User-requested toolbar positions — 8 October 2026

Free Exploration's developmental stage bar now sits below the model viewer; the anomaly chooser uses the same bottom position. The shared model viewer's former horizontal bottom dock is now a vertical toolbar on the left. Parts, Cutaway, Separate/Reassemble, Isolate/Show all, View and guided-step restoration retain their actions and panels. Selection information and Focus move with that toolbar. Reset view and the orientation cue are pinned to its bottom, outside the scrollable tools, so recovery remains visible at smaller sizes. Close-up, Location, Model info and the page heading remain above the viewer.

The model canvas occupies the space to the right of the toolbar and continues to refit anatomy when its available size changes. Normal-view sizing also respects a six-centimetre depth budget throughout its overview zoom range. The simulator build succeeded, and visual QA checked the paired-tubes stage from the supplied screenshot. Live model regression checks passed; results are saved in toolbar-layout-validation.json. The separate volumetric close-up control bar and its zoom range are unchanged by this request.


## Right-side detail popups and readable exploration selector — 8 October 2026

Close-up, Location and Model info now form a vertical group on the right of the model canvas. The comparison picker remains above models that offer multiple anatomy states. Location and Model info use popovers anchored outside the right edge; opening these no longer disables the model or its annotations. Their Done controls dismiss the popup. Model info is scrollable within a bounded panel. Close-up continues to open its separate movable 3D volume with the larger zoom range.

The Development/Anomalies selector now uses explicit high-contrast labels: white on a dark backing for the unselected option, black on pink for the selected option. The selected option exposes its accessibility selection trait. Switching categories retains the existing asset reset behavior.

The simulator build succeeded. Visual previews checked Location and Model info beside the visible paired-tubes model. The right-side button group and bottom stage navigation remain visible. Native simulator input did not establish a successful dismiss tap; previews and the existing state bindings were used for verification.


## Guided bottom actions and unobstructed tissue labels — 8 October 2026

Guided Learning places Close-up, Location and Model info in a horizontal row inside the bottom of the model panel, as indicated in the annotated screenshot. Free Exploration keeps its right-side group. Guided detail popovers anchor below the action row; the enlarged close-up remains a separate movable volume.

The shared normal viewer now reserves a text strip above its RealityView for the selected tissue's label. The model refits within the remaining viewport rather than allowing the label to float over anatomy. Long labels wrap vertically. The Labels preference still hides or shows this strip, and selection highlighting remains on the tissue. The former floating label and leader are removed from the normal viewer; the separate close-up annotation behavior is unchanged. Focus in the left toolbar now fits on one line. Loading, error recovery and the optional backdrop are retained.

The simulator build succeeded. Visual QA checked the paired-tubes guided lesson with its selection label above the model, the three actions along the bottom, and the lesson panel alongside. At maximum normal-view size (1.25×), the label remained separate from anatomy and the Model info popup opened below the panel without covering the model.


## Flow review — 8 October 2026

The review found inconsistent low-contrast segmented selectors outside Free Exploration, repeated selection labels in the normal viewer, floating labels still obstructing enlarged close-ups, automatic narration on every lesson step, and loss of position when returning to a lesson. Development and Anomalies also shared one model-selection value, so changing categories discarded the selected model.

A shared readable choice picker now serves category switches, development model choices and anatomy comparisons in both view types. Selected text is black on pink; other options are white on a dark backing. Long option sets stack rather than truncate. Pink model actions, Focus, Hide/Show lesson and narration controls have darker labels. The normal viewer shows one larger tissue label above anatomy. In the close-up, the selected tissue is named in the ornament above the volume and the floating label/leader is removed. Parts and View popovers anchor outside the left tool column. Unmatched tissue searches offer Clear search.

Lesson progress is saved locally by lesson name, independently of other lessons. Reopening resumes at the saved step, bounded to the current number of cards. Finish marks the lesson completed and review starts from its first step. Catalogue cards indicate Continue or Completed/Review. Narration begins only after Play is selected; once enabled it continues across steps, and pausing prevents automatic playback on the next step. Closing the lesson stops speech. Development and Anomalies retain separate model choices while switching categories within exploration. Switching comparison state in the close-up also reassembles the tissues, matching the main viewer.

The simulator build and live checks passed for all sixteen assets. The regression report includes independent lesson resume, serialization, completion, and a changed lesson length, in addition to existing anatomy/view checks; see flow-review-validation.json. Reopening the paired-tubes lesson without a preview-step argument visibly resumed at step 2/3 with narration idle. Visual QA also checked the catalogue’s Continue indicator and the exploration category/model/comparison selectors at the Outflow and valves stage. Native simulator input returned noWindowsAvailable, so navigation was inspected through preview states rather than confirmed gaze/pinch input. The 4× paired-tubes close-up preview kept the tissue title and Reset view above the enlarged anatomy without a floating label across it. Physical headset interaction remains unverified.
