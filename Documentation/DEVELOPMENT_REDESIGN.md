# Development-first school prototype — 24 October 2026

The user's revised brief supersedes clinical-review gates and the clinical handoff workflow in earlier documents. This is a school design project, not a clinical product. Keep anatomical explanations sourced and describe model limitations plainly; do not block implementation on expert review. The active presentation remains untouched; no slide videos are created.

## Intended experience

Start with a recognisable developed heart so non-medical viewers know what the early shapes are becoming. Connect normal developmental processes to resulting abnormal anatomy in the same learning context. Free exploration should ultimately have a continuous scrubbable developmental timeline, with optional anomaly branches and an easy return to the same developmental position.

## Implemented in this increment

- Added “Start with a whole heart” directly on Home, so a newcomer can establish what the embryonic structures will become before choosing a learning mode. Home descriptions now foreground development and congenital differences.
- Downloaded three actual USDZ models from 3D Heart Project through Sketchfab's authenticated download interface: typical teenage heart, coarctation and tetralogy of Fallot. Original source geometry/materials retained, including transparency. They appear in a whole-heart viewer accessible from Free Exploration. These are later specimen-derived anatomy, not embryonic stage models or a matched longitudinal series.
- Added normal process → developmental difference → consequence connections for atrial septation, ventricular septation, outlet formation and postnatal ductus closure. Stage links open the relevant anomaly and return without changing timeline selection; corresponding guided lessons include the same links.
- Fallot's developmental connection can open the downloaded patient-derived example.
- Added a continuous procedural tube-looping illustration at stages 2 and 3 with forward/backward scrubbing, open-wall view, play/pause and reset. This reuses the original project's teaching centreline, not a downloaded scan. It illustrates one segment only; it does not complete the requested full timeline or reproduce tissue growth.
- Repaired malformed speech delegate syntax found in the working file. Corrected UTF-16 caption offsets, paused-button wording, background narration stopping, and concealed-check narration/title handling.

## Remaining work

The full morphing timeline is not implemented. The eight existing stage assets and downloaded external embryology models have incompatible mesh topology. New compatible surfaces/rigging and checks for intersections, orientation and continuity are required across tube fusion, looping, septation and valve development. The new tube illustration is a functional first segment, not the final realistic model standard. Do not replace the detailed stage models with an unsupported generic heart morph.

The downloaded specimen models provide the intended visual reference, but their triangle counts and visual fidelity need headset inspection. The typical heart, coarctation and Fallot specimens differ in age, geometry and scale; viewer fitting is not an anatomical size comparison. No clinical efficacy or diagnostic scoring is claimed.

## Asset/source decisions

3D Heart Project is the user's preferred visual source. The separate reference list records individual licences. Keep mandatory creator attribution with any displayed/downloaded assets; presentation references remain the user's editorial choice.

Eight Blender embryology files were downloaded from daviyahiro/cardiac-embryological-models for inspection, with embedded scripts disabled. Each is a static mesh with different vertex counts and no shape keys. No explicit licence file was found in the listing. These files are retained outside the app bundle for evaluation, not installed into the app.

### Guided looping follow-up

The guided D-looping lesson now offers “Scrub the looping transition”, using the same continuous tube surface. Its sheet returns to the original lesson position. The exploration morph has a dedicated control surface and pauses/hides behind popups. The full eight-stage morph timeline remains future implementation; the new transition covers tube bending only.

### Bottom timeline integration

Free Exploration now holds a fractional timeline position and drives the continuous tube mesh directly between stops 2 and 3. The morph responds in both directions to the bottom timeline, and hides its duplicate local slider during this interval. Outside the implemented interval, positions snap to stage stops; no fictitious full-timeline morph is implied. The header distinguishes the teaching morph from specimen references at adjacent stops. Geometry and timeline policies have automated checks.

Previous/Next now visit the corresponding endpoint of an in-progress transition before leaving it. Switching to anomalies preserves the developmental position while showing the anomaly's own title.

### Persistent morph endpoints and playback

Stages 2 and 3 now default to the same procedural surface used between them, so reaching an endpoint does not exchange it for another model. “Inspect detailed anatomy” still opens the existing stage specimen; moving the timeline restores the continuous teaching view. Playback advances this same timeline and pauses when the learner scrubs or opens an overlay. The morph remains an illustrative tube-loop transition, not a continuous reconstruction of the complete embryonic sequence.

### Paired-tube joining — 25 October

The implemented interval now covers stages 1–3: paired tubes joining into one tube, followed by looping. Joining uses two hollow cross-sectional surfaces whose buried arcs disappear as their unions form. It is a simplified shape illustration: surrounding embryonic body folding, cellular fusion and three-layer tissue remodelling are not modelled. The joined endpoint shares the looping model's centreline, radius and local frames; no opacity crossfade is used. The open-wall control is intentionally available only after joining. Stages 0 and 4–7 still use snapshots, so the full eight-stage morph is not complete.

### Both learning modes and UMCG anatomy

Guided Learning now offers the same joining/looping illustration in paired-tube and primitive-tube lessons; the D-looping lesson retains its focused looping animation. UMCG neonatal, ASD, VSD and TGA educational models are available in the whole-heart viewer, with original materials and individual creator/licence links. Normal atrial/ventricular developmental branches open the corresponding UMCG examples; the related anomaly lessons expose detailed anatomy directly. Free Exploration chooses the matching detailed anomaly when available. These source models are explanatory references, not deformed embryonic stages or a scored unseen diagnostic test.

### Learning flow within the morph

The shared animation viewer now offers a process-specific prediction and an observation prompt. It distinguishes changes in shape from changes in connections, asks learners to replay in both directions, and invites explanation without relying on stage names. It is optional practice with explicit reveal, not a scored clinical task. The model and playback pause behind the question. This is intended to support the project's root-cause learning objective, but learning effectiveness has not been measured.

### Outflow division and process-linked anomaly windows

The continuous intervals now include stages 1–3 (joining/looping) and 5–6 (regional outflow partitioning). The latter keeps the outer conduit in place while two cushions expand towards a shared partition, preserving the mesh topology across progress. It does not simulate ventricular alignment, cellular fusion, valve formation or a disease-producing arrest. Those limits are visible in the viewer. Stage 0, stage 4 and the transitions connecting separate illustrated regions remain snapshots; no crossfade is presented as true morphing.

The shared outflow viewer is reachable from the guided outflow lesson and the exploration timeline. Both retain prediction → replay → explanation. Context branches associate ASD/AVSD with septation/AV junction development, VSD with ventricular partitioning, Fallot/TGA with outlet division and alignment, coarctation with arch development and ductal-transition consequences, and PDA with postnatal persistence. Multiple branches can share one process window. Markers indicate a developmental relationship rather than a known instant of onset. Opening a branch preserves the exploration timeline; AVSD uses the imported four-chamber specimen. Guided branches are suppressed while a knowledge-check answer is concealed.

All live anatomy now uses the shared visual style described in MODEL_VISUAL_STYLE.md. Earlier notes about original-material switches are superseded: there is one adapted presentation, without a user-facing source appearance toggle.

### Morph deformation and rendering repair

The existing joining/looping/outflow viewer now retains mutable mesh buffers per topology rather than rebuilding a render resource each frame. The looping path interpolates edge directions and lengths, with parallel-transported wall sections and smoothed curve knots. This corrects surface flips and locally inverted walls missed by earlier centreline-only tests. Region colours reveal continuously after joining; reversing through that boundary restores a closed wall predictably. Shared captions reserve stable space so model fit does not jump when the process name changes.

This repairs existing geometry, not the unimplemented links between separate regional studies. Headset testing is deferred at the user's request; development continues using numerical and simulator checks.

### Guided integration of realistic anatomy — 26 October

Later anatomy now appears in the guided workspace rather than requiring a departure into the full collection. The developmental view remains mounted beneath it and returns at the same lesson phase. Each supported lesson supplies an observation prompt and a connection back to the developmental process. In final/explanation phases, the realistic view becomes the default second representation; learners can select either representation earlier when it does not pre-empt a check.

All ten normal-development lessons have later-anatomy context. ASD/VSD/AVSD/Fallot/TGA/coarctation comparisons use installed source specimens, with source-specific attribution and the shared appearance. Paired tubes/looping use the neonatal external model as overall context, not a claim that external anatomy exposes all developmental changes. Valve and birth-transition prompts explicitly identify features/physiology the whole-heart source cannot show. PDA has no realistic counterpart installed and retains its existing teaching model.

Within this view, normal/related-anomaly selection resets fit/rotation, while switching back preserves the underlying developmental scene. Prediction and recognition gates suppress both the selector and specimen workspace before a response/reveal. Compatible normal-process animations and related developmental branches remain accessible alongside the specimen prompts.
