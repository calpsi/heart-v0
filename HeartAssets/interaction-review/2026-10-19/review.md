# Interaction corrections — 19 October 2026

Reviewed the supplied 19.14-second recording. View controls remained open while the scene/camera changed; the recording alone does not establish every failed button event.

Changes:
- Parts and View now share a mutually exclusive nonmodal ornament instead of popovers, allowing access to the main tools while inspecting settings.
- Spatial tool labels include their complete padded hit area.
- Separate and Reassemble leave isolation; reassembly clears detached-part positions. Added regression assertions.
- Model detail actions moved above the viewport so forward-projecting anatomy cannot cover the previous bottom action row.
- Overview RealityView uses centered layout. An attempted explicit scene-center offset failed screenshot review and was reverted.

Validation scope: build and live RealityKit checks, plus screenshots. Device Hub computer-use capture failed with SCStreamError -3811/-3812; full pointer click-through and headset testing remain outstanding. Do not call the entire button flow verified based only on model regression tests.

Final build and fresh live regression passed: 23 assets, 418 part pivots. Separate/Reassemble state recovery assertions included. Final screenshot saved. Model still sits low in its viewport; do not call spatial framing fully resolved. Main detail actions are above the model and unobstructed. Overview depth lift removed; backdrop moved 20 cm behind window plane. Directional-light positional offset removed (orientation retained).
