# HeartV3 second-pass implementation plan — 23 October 2026

Follow-up implementation: the 15:33 recording and subsequent user request supersede the separate close-up design below. Remove that scene; support 0.4–2.5× in-place zoom, crop inside the model viewport, keep anatomy behind essential controls, consolidate the left toolbar, and stabilize labels/transcripts. See the dated follow-up in FIX_LOG.md.

Source: the four review documents in this directory, found in `~/Downloads/HeartV3_Codex_Review_Package.zip`. Screenshots are evidence of observed symptoms, not proof of code causes. The original two source recordings have not been reproduced on hardware in this run.

## Repository-backed architecture

- SwiftUI / RealityKit, visionOS. Plain application and guided-lesson windows (`heart_v3App.swift`); the separate volumetric close-up was removed after the follow-up recording. There is no app-owned immersive-space scene or custom raw hand tracking. Environment and world window placement are controlled by visionOS.
- `HeartModelScene` in `HeartModelView.swift`: holder → spin → imported model → tissue entities. Holder supplies fitted scale, spin supplies rotation/centering, per-part offsets are model-local. `apply` restores authored positions before applying state, cutaway, isolation and offsets. Collider targets are individual tissues.
- `HeartModelControls`: serializable viewing state. `transition` intentionally preserves orientation and zoom within an asset; `restore` resets a lesson step. `.id(asset.id)` in guided/free/reference viewers scopes scene state to each asset. Display preferences persist within that viewer, not globally.
- Both viewers use targeted DragGesture exclusive with SpatialTapGesture, plus simultaneous MagnifyGesture. Magnification is cumulative from gesture start, not multiplicatively accumulated each event. No evidence of the commonly suspected exponential accumulation bug.
- `HeartSeparationPresentation` owns cancellable separation animation. SwiftUI `.task(id:)` cancels changing requests. SpeechManager handles narration, not developmental animation.
- `GuidedTopicDetailView` owns lesson position and model action requests. `HeartLessonProgress` stores visits/completion in AppStorage; no prior challenge scoring engine was found. `HeartLessonStep` supplies preselected anatomy, including the coarctation answer.
- Asset JSON, manifests and provenance describe simplified illustrations and source reconstructions. Do not infer source-specimen anatomy or clinical claims from the meshes.

## Incremental order

1. Spatial patch: stop automatic window creation on pinch; clamp size and rendered extents including detached parts; keep whole-model pivot during zoom; bound discontinuities; clear gesture baselines on cancellation/inactivity; keep close-up dock below geometry. Test resize policy and build before expanding scope.
2. Recovery patch: owner-scoped close-up dismissal, full model reset preserving anatomical state and lesson progress, one-step undo for drag/pinch/separate/reset, selected-part origin tether. Preserve camera-only Reset view and step-specific Restore step.
3. Clarity patch: larger tool captions, manipulation status, precise recovery descriptions, source-class badge and named step counters. Retain existing visual identity, presets, orientation cue and inspection tools.
4. Recognition patch: coarctation's first step conceals preselection, labels, comparison, details and answer narration; explicit commit/confidence/hint/reveal; record outcomes independently from viewed progress. Reuse current model content only; no new disease-mechanism claims.
5. Deferred clinical work: educator-approved mechanisms, licensed unseen representation, validated interpretation/feedback, scheduled retrieval and measured transfer outcomes. Remains a content/research dependency, not something to fabricate.

## Verification

Portable Swift tests exercise resize invariants and assessment state. Existing live-RealityKit validation is extended for safe fitting and idempotent full reset. UI tests cover recovery and answer concealment. Use the full existing regression suite to catch scene/navigation regressions; record actual results in FIX_LOG.md.

Device acceptance remains required: B 00:24–00:36 and A 03:00–03:20 (pinch/rotation, interrupted tracking, repeats); A 03:40–03:55 and 06:30–06:40 (leave/return with close-up); seated/standing, passthrough/immersive, near/far window placement, light/dark environments and larger text. A screenshot or simulator success is not a device acceptance pass.

## Current continuation — 26 October

The user has deferred headset checks and wider UI work. Current model work preserves the selected muted regional style and shares source-preserving inspection tools across both modes. Continue in incremental passes:

1. Stabilise realistic-specimen changes and match morph manipulation to static models; verify cancellation, failure recovery, bounds and progress preservation.
2. Inspect the installed visual result and record simulator versus headset evidence separately.
3. Extend true developmental morphs only where corresponding geometry and defensible anatomical content exist. Full-timeline morphing, unsegmented sources and absent tissue layers remain explicit asset limitations; do not fabricate them or prepare a clinical-review handoff.

Current model-inspection follow-up: progressive wall opening and shared pinch sessions are implemented and verified at the geometry, live GPU and simulator interaction levels. Specimen recovery now separates view reset, reassembly and full source restoration. The remaining substantive asset work is still compatible geometry for the unsupported timeline intervals, defensible segmentation of unsegmented sources, and missing layer content; inspection cuts and fades must not be described as completing those requirements.

Early-tube follow-up completed: nested teaching layers follow joining/looping, retain colour/shape during bounded individual movement, and reassemble without regenerating the developmental deformation. Workspace-owned sessions preserve inspection context across representation changes. Shared morph practice now separates prediction, observation, explanation and feedback; it does not score timeline movement as mastery. Final simulator/live evidence is in TESTING.md. Remaining morph work includes a corresponding surface-detail mapping, joining-wall inspection, and the unsupported developmental intervals; later specimens still require source-supported layer/region segmentation.

Shared inspection follow-up completed: early-tube isolation preserves arrangement and viewing placement; reverse scrubbing retains the chosen looping wall state; outflow wall/cushion components separate and reassemble without altering their source shapes. Material caching and the common elapsed-time transition keep inspection behaviour aligned across modes. Remaining outflow interaction work includes individual component selection/movement; it is not a segmented tissue-layer model. The final build, UI and live validation results are recorded in TESTING.md.
