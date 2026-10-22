# Perinatal context-lung refinement

22 October 2026. Scoped to Heart_10_CirculatoryTransition.

Replaced oval lung silhouettes with wider basal contours and rounded apices, a left anteromedial indentation, bilateral oblique fissure grooves and a right horizontal fissure groove. The original two lung objects, UVs, textures, transforms and part IDs are retained. The other 21 meshes have identical vertex coordinates to the backed-up source.

These remain illustrative perinatal orientation shapes, laterally displaced for teaching. They are not scan-derived lung reconstructions. Grooves indicate fissures; lobes are not independently separable. Inflation, pulmonary venous return and intrapulmonary vascular detail are not added. Heart and vessel geometry is unchanged in this pass.

Reference: [NIH/NCI SEER — Bronchi, Bronchial Tree, & Lungs](https://training.seer.cancer.gov/anatomy/respiratory/passages/bronchi.html), consulted for gross left/right asymmetry, lobation and cardiac notch. No adult dimensions were used as fetal measurements.

## Validation

- Both changed meshes are closed and manifold with positive volume.
- All 23 part IDs are retained; unchanged mesh coordinates checked exactly.
- Installed export validation passed: 23 meshes, 90,282 triangles, 3 embedded textures; metre units and Y-up orientation.
- Stage-specific aperture checks passed for the fetal foramen, apposed transition flap and patent but narrowed transition ductus.
- Blender previews reviewed in both states. The app applies its teaching colour key separately from the source Blender materials.
- Build and `testTransitionClarityAndLearningProgress` passed on visionOS 27 Simulator with zero failures. Verified the revised silhouette in the test screenshot (`app-preview.png`); surrounding parts are faded because the aorta is selected. The screenshot is cropped by XCTest.

Candidate source, previews, validation report and original backups are in this directory. App test result is recorded in ui-test.log.
