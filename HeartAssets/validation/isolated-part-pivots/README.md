# Isolated-part rotation — 18 October 2026

Implemented in the shared HeartModelScene used by the main viewer and close-up views.

- Restore the assembled model translation before applying visibility and part offsets.
- When a valid part is isolated, measure its visible bounds in the unrotated spin coordinate space and translate its center to the spin origin.
- Keep a rotation-invariant framing envelope around the isolated tissue. This avoids apparent orbiting or zoom changes caused by repeatedly fitting a rotated, asymmetric bounding box.
- Return to the saved assembled translation when isolation ends; recentering does not accumulate.
- Include separation and manual part movement when choosing the isolated pivot.

Validation: Xcode visionOS simulator build passed. A fresh live RealityKit validation report passed all 16 installed assets and 355 selectable parts. Every part was tested with separation and a manual offset at three rotations. Checks cover zero pivot displacement and unchanged fit scale, alongside the existing import, materials, lighting, lesson, zoom and movement tests.

The old assertion that isolation always increases scale was removed: an envelope with room for a full rotation can need more margin than a single assembled pose. The actual fit and rotation stability checks remain.

`runtime-validation.json` is the simulator evidence. No physical-headset gesture test was performed.
