# Model inspection and anatomical fidelity — 26 October

## Scope and acceptance

User request: every model should have smooth transitions, a cross-section, separable/movable parts, realistic tissue layers, and retained anatomical accuracy. This is an ongoing asset-quality requirement, not a claim that the existing source files contain all these features.

The inventory in verification/model-capabilities.json covers 31 static models: 16 teaching illustrations, seven HDBR reconstructions, eight later-anatomy specimens. The procedural joining/looping/outflow intervals are separate generated illustrations.

## Implemented in this pass

- Geometric section controls on all static-model viewers: depth, width and height in the original assembled model's axes. These are not labelled as clinical anatomical planes because every source has not been independently oriented. Sections interpolate existing triangle positions, normals and UVs, retain material slots, and restore the original MeshResource on exit. No artificial cap fills a blood pool or hides a missing wall. Backfaces are visible during sectioning. The section stays attached to the source part when it moves.
- Later-anatomy specimens now expose source-group separation, bounded incremental movement, reassembly, return-part and an origin tether. These controls are shared by both mode subsections, embedded guided specimens and branch previews. Grouping follows source-object parents: material chunks and 65k-vertex export splits stay together. Separation is an inspection arrangement, not a biological movement.
- Source-labelled myocardial shell and blood-pool representation remain distinct in the typical heart. Generic components remain generically named. No unlabeled mesh is reclassified as myocardium, endocardium, cushion or valve.
- Animated specimen entrance and interruptible separation/reassembly; reduced-motion users receive immediate updates. Lesson/atlas models fade in after loading and keep their existing smooth separation. Guided developmental models now permit part movement outside recognition tasks.
- Sections in lesson/atlas scenes use the whole-model envelope for fitting, so cutting geometry does not recenter or enlarge the remaining half. Source files remain unchanged.

## Material fidelity

Shared HeartModelStyle continues to retain source texture/normal/roughness information and known layer distinctions. A tissue-like material is visual styling; it does not add a missing anatomical layer. The source-mesh section does not invent wall thickness, histological organization, fibre direction or a cavity.

## Remaining model work

- Fallot's imported source consists of material fragments within one unsegmented heart. It can be sectioned, rotated, scaled and moved as one source group. Independent anatomical separation remains unavailable until a defensible segmentation is authored; the Separate button is disabled for that source.
- Several UMCG groups have only generic source names. They can be moved as source components but need anatomical identification before they can function as named-structure learning targets.
- HDBR reconstructions describe regional anatomy, not complete tissue-layer stacks. Adding myocardium/endocardium/cardiac jelly to every reconstruction by offsetting shells would introduce ungrounded anatomy.
- Full-timeline morph correspondence remains missing outside the implemented joining/looping and outflow intervals. Smooth appearance/loading is not a validated developmental morph.
- Procedural morphs retain their supported inspection views. Early-tube wall layers now separate and move as described below; this does not segment the tube into independently manipulable anatomical regions. Joining still lacks the looping/outflow open-wall control.
- The current geometric sections are uncapped surface sections, not solid histological slices. Surface-only inputs cannot reveal interior anatomy absent from the source.

## Verification

Portable geometry/material/policy tests: verification/specimen-section-policy.txt. Live-scene and simulator results are recorded in TESTING.md when complete. These establish software invariants and preserve source geometry; they do not certify anatomical accuracy, medical completeness, learning efficacy or headset performance. No clinical-review handoff is being prepared.

Apple's MeshResource/Part APIs supply the source positions, normals, UVs and material indices used by sectioning: https://developer.apple.com/documentation/realitykit/meshresource/part and https://developer.apple.com/documentation/realitykit/meshresource .

Section preparation runs off the UI thread with progress feedback and cancellation. Each completed axis is cached within that scene. Reset or navigation cancels pending work so an old section cannot replace a newer view. Mesh-instance transforms and mirrored winding are retained when generating the section. Original source geometry stays visible during preparation.

Visual correction: separation and manual offsets use the common spin container's coordinates, matching the measured visible diameter. Imported root scales no longer shrink or magnify part displacement. Every multi-group specimen uses a distinct inspection direction and a 15%-of-diameter default offset; manual offsets are bounded to 30%. These offsets are for inspection and are not measurements of anatomical separation.

## Continuity update — 26 October

All realistic specimen viewers now keep their displayed source until its replacement is ready. Source changes fade out, swap, then fade in within one persistent scene root; failed loads preserve the prior source with an explicit label and retry. Rapid switches cannot install a superseded result. This is a presentation transition, not a developmental morph between unrelated specimens.

Joining, looping and outflow morphs share the static viewers’ 0.4–2.5× zoom range and support two-axis rotation. Reset view changes only the viewing pose, retaining progress and open-wall state. The current surface bounds determine depth at every frame, including reverse scrubs, topology switches and enlarged rotated views. No new tissue layers or anatomical correspondences were added in this update.

## Progressive wall inspection

Looping and outflow wall opening/closing now animate independently of development and can reverse from their displayed intermediate state. Opening reveals the existing illustrative lumen; it does not simulate tissue tearing or a developmental failure. Outflow cushions and posterior wall remain fixed during the inspection cut. The endpoints retain the previous whole/open geometries.

The same bounded pinch session is now used by morphs, realistic model collections, embedded guided specimens and anomaly reference previews. Reference previews also support pitch and a size slider. Reset during an active pinch suppresses remaining samples from that gesture. Physical-hand gesture feel remains a headset check.

## Specimen recovery controls

All realistic viewers share these independent operations: Reset view restores size/rotation; Reassemble restores component positions while retaining the section; Restore model restores whole source surfaces and assembled parts while keeping the viewing pose. None advances a lesson. Return part restores the selected component to its assembled position without disturbing other separated components. These controls do not create anatomical segmentation absent from the source.

## Early-tube layer extension

Joining and looping now include three named illustrative layers based on the existing teaching assets: outer myocardium, intervening cardiac jelly and endocardial lining. They deform together and can separate/reassemble for inspection. Looping’s progressive wall cut reveals the assembled nested layers. Their radii use the existing straight/looped teaching proportions consistently across both animation intervals; they are not histological measurements.

This replaces the earlier limitation that the procedural tube has no separate layer components. It does not provide arbitrary per-layer grabbing, regional layer remodelling or complete tissue stacks for every model. Outflow, HDBR and imported specimens retain their existing supported geometry. Full-timeline correspondence beyond the current intervals remains incomplete. See TUBE_LAYER_REFERENCES.md.

## Individual layer inspection and continuity

The three early-tube shells now support selection and bounded movement using controls in Move a layer. Their shape and layer/region identity remain unchanged while moved; Reset layer move restores the selected inspection slot and Reassemble layers restores every shell. This is controlled incremental movement, not direct hand-grabbing.

Guided morphs and free-exploration morph workspaces retain their inspection settings during representation changes; playback stays paused on return. Model practice now requires a prediction and comparison of positions before an explanation attempt, with an explicitly unscored reveal available. These features do not add later-stage morphology or validate clinical transfer.

Fine texture matching remains incomplete. The static teaching assets' normal and roughness atlases are baked for their own UV islands. The generated morph has no matching UV atlas, so copying those images would misalign surface detail. The current animation uses the shared regional palette, layer lightness, material roughness and lighting, with normals derived from the deformed geometry. No source texture has been stretched onto an unrelated mesh.

Early-tube layers can also be isolated individually. Show all layers restores visibility while keeping the cutaway, arrangement and viewing pose. Isolation does not recenter the selected layer or magnify it automatically; its place in the whole arrangement remains stable. Choosing a new layer while isolated switches the visible layer. These controls use the same session and renderer in guided/free learning.

Reverse scrubbing temporarily makes wall opening unavailable during joining but no longer discards the learner's saved choice for looping. This improves inspection continuity without adding a joining cutaway or changing the developmental geometry.

The outflow illustration now separates its existing wall/two-cushion components for inspection. Cushion offsets are rigid and bounded, and reassembly preserves progress, wall opening and viewing pose. The wall remains at the common origin. Guidance explicitly asks learners to reassemble before judging contact or partition formation. This works through the same renderer in both modes and branch replays; it is not an added biological process, full tissue-layer stack or direct per-cushion grabbing.

Joining and looping now ease to zero velocity at their shared tube pose and at their other endpoints. Outflow retains its cubic easing through the same presentation-time helper. Reversing the timeline follows exactly the same geometry path. This is playback timing, not an asserted developmental growth rate, and it does not fill the unsupported timeline intervals. The static source assets and authored start/end shapes remain unchanged.

## Core learning route — 27 October

Supported guided processes now open on the shared morph rather than requiring a secondary sheet. The joining lesson ends at the joined tube; primitive-tube entry begins there; looping and outflow remain the existing illustrations. A catalogue entry links the available animations into a guided route. No new developmental geometry or missing interval is implied by that navigation.

Related anomaly/typical specimens now appear in the developmental workspace. Free exploration retains the timeline; returning to the process retains progress/inspection context. Fallot/TGA replay the existing normal outflow process, with the existing distinction between division and alignment retained. These are different specimens, not simulated normal-to-defect morph targets. Structural explanations remain concealed until requested, and route navigation does not record mastery.

## 27 October evening routing and recovery

Imported specimens now open directly from Free Anomalies for VSD, ASD, Fallot, TGA and coarctation. Guided ASD/VSD start with their altered specimens; Fallot/TGA use their existing realistic branches. No downloaded PDA exists in the current bundle. Coarctation recognition remains on its answer-gated teaching model. The rendered morph gesture proxy and its unverified direct-layer drag option were removed after the black-rectangle regression. Directional layer movement remains bounded and retains progress.

### Authored ductal anatomy (supersedes the PDA gap above)

`PDA_Patent` and `PDA_Closed` are original, matched regional reconstructions, using the older V0 vessel relationships as an authoring base. Both modes and the birth-transition branch share these assets. Three named parts, actual hollow arterial walls, bored patent connections, closed-remnant comparison, all three geometric section axes, bounded component movement/reassembly and view reset are supported. Matched state changes preserve pose and section. This adds no scanned PDA specimen, microscopic layers, complete cardiac chambers, blood-flow simulation or continuous closure morph. Authoring validation and limitations are in `HeartAssets/authored/pda/validation.json`.
