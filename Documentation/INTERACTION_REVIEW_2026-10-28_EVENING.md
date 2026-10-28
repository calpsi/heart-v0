# Interaction review — 28 October evening recordings

## Scope and evidence

User request: retain the current UI, review the two new recordings, recover reliable interactions, and make gestures consistent across stages, pages and lessons. The user confirmed there is no spoken feedback. Audio analysis was stopped; no transcript is used.

- A: `ScreenRecording_10-28-2026 17-51-38_1.MP4`, duration 120.10 seconds.
- B: `ScreenRecording_10-28-2026 17-53-58_1.MP4`, duration 260.56 seconds.
- Older reference supplied by the user: `Pitch Media/HeartV3-demo-backup.mp4`, duration 40.37 seconds. The clip shows an older, dark/translucent interface and navigation between free exploration, guided learning and home. Its sampled frames do not establish reliable two-handed manipulation or reveal gesture input, so it is a visual/navigation reference, not proof of gesture correctness. Do not infer its recording date from the filename.
- Timestamped frames sampled at five-second intervals across A/B, two-second intervals across the older reference: `verification/retest-1751/`. These are visual observations, not telemetry of gaze or gesture recognition.
- Available Git comparison: `19ba238` (22 October, “hv0”). Only this and the initial commit exist locally; no claim of a recovered 10 October source revision. V1/V2 were not used.

## Prioritised changes

| ID / original issue | Priority | Evidence | Finding and cause confidence | Required change / acceptance |
|---|---|---|---|---|
| E01 / HV3-005, 020 | P0 | B 00:35–01:05, 01:50–02:05, 02:50–03:00 | Gesture handling differs in source: stage models use targeted quaternion rotation at 0.005 radians/point; morph/specimen wrappers used generic rectangle drags at 0.008 with a pitch clamp. Hand activity alone cannot identify every missed input. | One targeted gesture handler, equal gain, screen-axis rotation without pitch snap, shared pinch ownership and cancellation. Test actual transform changes, not just button labels. |
| E02 / HV3-002, 005, 020 | P0 | A 01:25–01:35 | Specimen geometry overlaps its Parts popover. Confirmed code omission: showingParts did not suspend the 3D root; outer generic gestures encompassed the control row. | Keep buttons outside the gesture surface; suspend interaction/geometry while its popover is active, consistently with stage viewers. Dismiss returns the same inspection pose. |
| E03 / HV3-007, 009 | P0 | A 00:35–00:45 | ASD/AVSD embedded comparison has controls and explanatory text but no usable visible anatomy area. Its content is vertically compressed. Layout collapse is a strong hypothesis; recording does not prove a load failure. | Guarantee usable viewport height in embedded comparison, test rendered bounds and inspect screenshot. Do not accept reference.ready alone. |
| E04 / HV3-001, 002 | P1 | A 01:10–01:15; B 00:40–00:50, 01:20–01:25 | Enlargement works in several recorded cases, but anatomy intrudes into the title/control space. A numeric zoom cap and a depth cap do not guarantee projected containment. | Keep requested zoom but verify a bounded viewing area and reachable controls across orientation/window size. Needs projected-geometry verification; not resolved solely by the shared-handler change. |
| E05 / HV3-004, 005 | P1 | A 01:25–01:45; B 00:45–01:05 | Selection, separation, isolation and sectioning visibly change anatomy. These are not all failed gestures. Specimens offer button-based component movement; stage models support direct part drag. | Preserve explicit movement mode; do not make ordinary rotation unexpectedly move a part. Direct component/layer movement parity remains additional work where source segmentation permits it. |
| E06 / HV3-007, 022 | P1 | B 01:50–02:20, 03:05–03:15, 03:40–04:00 | Guided route alternates among anomaly comparison, normal-process morph and detailed lesson. Header phase and morph progress represent different states; phase controls disappear inside morph mode. | Retain origin lesson/phase/pose and give deterministic return; audit ordinary entry, replay and repeated navigation separately from preview launch arguments. No educational-flow redesign in the gesture patch. |
| E07 / HV3-025, 026 | P1 | A 00:15–00:25, 00:50–00:55; B 00:25–00:35, 01:05–01:10 | Timeline switches between procedural animation and static specimens, with a substantial change in appearance/scale. Outflow is an isolated schematic tube rather than a whole-heart failure forming. | Extend developmental continuity and abnormal-process animations as a separate model/content task. Do not label these absent experiences as fixed by interaction tests. |
| E08 / HV3-005, 007 | P0 validation | Previous passing simulator suite versus A/B | Previous tests checked readiness, slider values, control labels and navigation. They did not prove rendered visibility, target alignment or two-hand input. | Add transform-observing drag tests, embedded viewport bounds checks and explicit device acceptance. Record failures instead of treating successful loading as interaction success. |

## Patch boundaries

Preserve current colours, controls, lesson copy and assets. Reuse the earlier stage viewer's screen-axis rotation convention across every renderer. Handle reset, popover, scene suspension and cancellation centrally. Keep individual-part dragging only in explicit Move parts mode; keep specimen and morph separation/return operations intact.

Implementation and verification results will be appended after the tests finish. A compile or automated policy pass is not a claim that the new headset behaviour is accepted.
