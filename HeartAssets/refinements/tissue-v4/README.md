# Tissue geometry and spatial interaction revision

This revision builds on the existing sixteen teaching assets. It preserves every catalog part ID and the named developmental/anomaly alternatives. These remain original anatomical illustrations, not specimen-derived reconstructions.

## Model changes

- Stage 1: a coherent curved cardiogenic field, keeping the crescent and adjacent tissues aligned in depth.
- Stages 2–4: rounded exposed tissue margins while retaining the hollow lumens and independent layers.
- Stages 5–14: softened dissection margins on applicable walls, septa and valve tissues.
- Stages 7 and 11: six curved branching ventricular ridges with ends embedded in the chamber wall, replacing oval nodules. The arrangement is illustrative; it does not reproduce a particular specimen's trabecular network.
- All stages: less exaggerated colour mottling, directional fine tissue grain and broader surface highlights. Colour, roughness and tangent normals are baked into three embedded 2048² maps per asset.

The early cardiogenic field is naturally sheet-like. It must not be replaced with an adult-looking heart at that age. Later chamber topology is still simplified, and this revision does not claim to complete a photorealistic reconstruction.

The developmental basis for ventricular ridges is described in [A pictorial account of the human embryonic heart between 3.5 and 8 weeks](https://pmc.ncbi.nlm.nih.gov/articles/PMC8917235/) and [Cardiac development demystified by use of the HDBR atlas](https://pmc.ncbi.nlm.nih.gov/articles/PMC11424819/).

## App changes

- The overview uses a larger spatial presentation instead of the former 6 cm depth cap. It requests expanded front/back window clipping margins; the close-up remains a separate volume.
- Free exploration has a Move parts tool. Dragging a tissue moves that tissue in model coordinates. Individual offsets are bounded, travel with the camera rotation and survive opening a close-up.
- Return part clears the selected tissue's manual offset. Reassemble clears all offsets and the exploded-view amount. Changing anatomical alternatives also reassembles the model.
- The camera frames the assembled anatomy while a tissue is moved, so the remaining parts do not shrink or recenter. Selecting a tissue reserves the same label space before and after selection.
- Close-up includes Move parts, Return selected part and Reassemble controls. Like the existing close-up, it opens with a snapshot; edits in that separate window do not synchronize back to the overview.
- Guided lessons have directly selectable named phases, visible even when the lesson text is hidden. Next phase previews the destination title. Phase changes retain viewing angle and size while restoring the appropriate anatomy and focus. Explicit Restore step still resets the view.
- A directional key light casts tissue-to-tissue shadows in addition to the studio environment reflections.
- The selection tint is subdued pink so it does not wash out tissue shading.

See Apple's [window clipping margin API](https://developer.apple.com/documentation/swiftui/view/preferredwindowclippingmargins(_:_:)) for the expanded overview presentation.

## Reproducibility and checkpoints

`before/<asset>/` contains the immutable pre-revision Blender scene, USDZ, manifest and renders. `progress.json` records each exported stage. `logs/` contains sequential build and topology/diagnostic-opening validation results.

Run `HeartAssets/tools/run_tissue_v4_batch.py` with explicit stage numbers to regenerate sequentially. It stops on the first failure. `validate_tissue_v4.py` checks all sixteen exports, their part IDs and all embedded maps. `tissue_v4_contact_sheets.py` generates before/after sheets from real renders.

Runtime checks include all named parts and states, independent displacement without moving other tissues, stable framing, reassembly, close-up state encoding, backward-compatible saved windows, retained phase viewpoints, original lesson actions, labels, zoom and separation. Simulator checks cannot establish headset hand-tracking ergonomics or medical accuracy.
