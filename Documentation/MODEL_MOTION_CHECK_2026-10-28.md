# Model and animation consistency pass — 28 October

Scope: the user's request to check smooth animation and coherent model rendering, with no unrelated changes. The additional app-flow diagram is audited separately in FLOW_DIAGRAM_CHECK_2026-10-28.md; it does not trigger navigation/content edits.

## Changes

- Joining, looping and outflow generators retain exactly the same coordinates, resolution, normals, UVs, face ordering and material indices. Repeated ring trigonometry is calculated once per ring/sample, arrays reserve the required capacity, and small temporary face arrays are eliminated.
- The live morph retains its existing mutable GPU mesh. The renderer no longer reassigns the same mesh component every time its vertices change; topology changes still install the appropriate mesh.
- Specimen separation, reassembly and reveal now advance by elapsed time with eased endpoints. Their intended 0.24-second duration remains the same. Cancelling or reversing starts from the current positions/opacity rather than replaying a sequence of fixed frame steps.
- The morph appearance cache now checks its target entity and whether that entity has materials. A new/reinstalled ModelComponent receives the shared tissue palette and grain/roughness maps even if developmental progress has not changed. Unchanged styled models still reuse their materials.

No controls, navigation, lessons, dimensions, shape definitions, textures, palette values, assets or model defaults were redesigned. The changes in HeartLoopingMorphView and HeartProjectView are limited to rendering/motion methods. `verification/model-motion-oct28/changed-app-files.json` compares app source hashes captured at the start of this pass.

## Evidence

An optimized local CPU benchmark generates 21 frames each for joining, looping and outflow at closed/half-open/open wall settings: **189 sampled frames**. SHA-256 signatures cover explicitly packed positions/normals plus indices, material IDs and UVs. All nine before/after signatures match exactly. These are sampled equivalence checks, not a proof of all possible states.

Representative average geometry-generation times from this run:

| Sequence | Before | After |
|---|---:|---:|
| Joining, closed wall | 8.18 ms | 2.80 ms |
| Looping, closed wall | 3.92 ms | 1.62 ms |
| Looping, half-open wall | 3.99 ms | 1.69 ms |
| Outflow, half-open wall | 0.58 ms | 0.24 ms |

Timing excludes signature hashing. This is an optimized host CPU benchmark, not headset FPS or end-to-end rendering latency. Sampling noise and warm-up affect timing. Exact data: geometry-before.json, geometry-after.json and geometry-comparison.json. Benchmark source: Tests/MorphGeometryBenchmark/main.swift. Run with the six geometry/palette/timing Swift sources and `swiftc -O`; it has no UI dependency.

Portable geometry/palette/continuity policies and the simulator build pass. All four selected interaction tests pass with zero failures, covering forward/reverse timeline morphing, contextual anomaly return, outflow practice in both modes, and specimen sectioning/separation/reassembly in both modes. The final live audit also passes, including mutable GPU buffers, palette/finish reuse, restoration after renderer recreation, elapsed-animation completion/cancellation and model recovery. Full results are in TESTING.md and `verification/model-motion-oct28/`.

Final simulator screenshots (`free-outflow.png` and `guided-outflow.png`) were visually inspected. The shared initial outflow model has the same muted brown wall, gold internal structures and visible tissue grain in both modes. It is visible against the white workspace without a black occluding panel. Different available viewport heights produce different apparent sizes; the existing small default framing remains. These still images confirm representative appearance, not animation frame pacing or the appearance of every bundled model.

## Limits

Anatomical source models still differ in segmentation and source texture detail. These changes preserve their shared finish rather than inventing tissue layers or recolouring unknown anatomy. Real-device frame pacing, thermal performance, stereoscopic appearance and hand tracking remain unverified. Existing incomplete full-timeline morph coverage and maximum-zoom projection are not resolved or disguised by this performance pass.
