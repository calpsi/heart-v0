# HDBR stage reconstructions in Heart v3

Seven source-derived reconstructions, 57 regions: CS11 N662; CS12 N288; CS14 N925; CS16 N1815; CS17 N1699; CS18 N1645; CS20 N913.

## In the app

Free exploration offers the reconstructions first in the looping, septation and outflow groups. Use the model choices beneath the stage slider to switch specimens or return to the teaching illustration. Normal guided/teaching models expose **Stage reconstructions** to open the complete atlas. Select a region, isolate it, separate regions, or use Move parts. Close-up windows use the same region mapping and local rotation pivot.

Source geometry is preserved, uniformly enlarged and centered. These are regional segmentations, including chamber regions and vessel lumens, not a complete reconstruction of myocardial/endocardial layers. Source omissions and surface irregularities are retained. Semantic source colours are preserved; one CS11 constant-colour shader was simplified to an equivalent colour for USD/RealityKit compatibility. An anatomical orientation cue is withheld until each source coordinate frame is verified. Exploded offsets are display arrangements, not developmental motion.

## Reproducibility and licence

Original GLBs and SHA-256 records: ../anatomy-review/reference-study/.
Run tools/build_hdbr_reference_models.py in Blender with one stage at a time, then tools/install_hdbr_reference_models.py in Python to install the verified exports, previews, source records and attribution.
Each folder contains Blender source, USDZ, preview, catalogue and source-geometry validation. installed-validation.json verifies the seven exports. runtime-validation.json records the latest live RealityKit checks when available.

See LICENSE-AND-ATTRIBUTION.txt. Adapted HDBR assets are CC BY-NC-SA 4.0; app code and unrelated assets are not relicensed by this notice.

## Outstanding anatomy work

The 16 pre-existing teaching/anomaly models have not received a complete anatomical audit. Early-stage vascular networks, measured tissue-wall thicknesses, anomaly topology and lesson-state morphology remain separate work. Passing software checks does not establish anatomical completeness or clinical validity.
