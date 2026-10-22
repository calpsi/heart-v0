# Layered tissue reconstruction

Updated 16 October 2026. This revision covers paired heart tubes (stage 2) and the primitive single heart tube (stage 3). It does not complete the realism pass for all stages.

## Video reference reviewed

The user supplied the local 51.78-second MP4 corresponding to https://www.facebook.com/share/r/1CzT4A9CPz/ . Twelve frames were sampled from 0.15 to 47.615 seconds. The earlier Facebook login obstruction is resolved by this attachment.

Visible targets: slender tapered paired tubes; substantial regional swellings; soft nonuniform highlights; mottled, finely irregular tissue; later looping and external vessel branches. Sampled frames primarily show external forms. The red/blue teaching colours and timeline labels were not copied into the app. No claim is made that the video is a specimen scan.

## This batch

Stage 2: rebuilt the paired tubes with tapered ends, undulating centre lines, varying diameters, independently shaped lining and muscle interfaces, thin lining and thick intervening jelly. Thinned the existing schematic endoderm context to read more like a sheet. Retains all 13 part IDs.

Stage 3: fuller atrial and ventricular regional swellings, shorter curved tube silhouette, thin inner lining, varying cardiac jelly and muscle thickness. Retains all 36 part IDs and six teaching regions. This is still the existing unfolded teaching layout, not the complete branched external form shown in the video.

Both: 120-degree removable anterior windows preserve more volume in cutaway views; intact and cut tissue have different material treatment; stronger fine surface relief and varied colour; three portable 2048px colour, roughness and normal maps. Existing free-exploration separation and guided references remain compatible.

## Anatomical references

- Hikspoors et al. (2022), https://www.nature.com/articles/s42003-022-03153-x — human embryonic reconstructions; CS9–10 descriptions distinguish endocardial conduit, cardiac jelly and surrounding myocardium.
- HDBR annotated sections: https://hdbratlas.org/organ-systems/cardiovascular-system/heart/heart-HE.html
- HDBR dissections: https://hdbratlas.org/organ-systems/cardiovascular-system/heart/dissections/embryonic.html

No external meshes or specimen images are embedded in the models. These are original parametric teaching reconstructions, not segmented imaging data. Layer thickness and region cuts are enlarged for learning. Surface relief is illustrative, not measured histology. Adult coronary fat and mature muscular architecture have not been added to early stages.

## Files and reproducibility

Editable Blender files, USDZs, manifests and three preview views are kept here. The app copies live in the established Blender, runtime asset and preview folders. Original pre-layered versions are preserved under `before/`.

Builders: `HeartAssets/tools/rebuild_layered_paired_tubes.py` and `rebuild_layered_tube.py`, with `bake_layered_tissue.py`. Each processes one stage at a time. The separated preview is a presentation only; saved source and runtime assets retain assembled rest positions.

Build, export and runtime results are recorded in the validation files alongside this README. Preview lighting is illustrative; headset appearance and manual gestures require separate visual checks.

## 18 October: anatomical accuracy requirement

The stage-4 candidate was generated and rendered, but is NOT installed in the app. It is held for a stage-specific anatomical review, particularly lumen continuity and vessel junctions. See `HeartAssets/anatomy-review/README.md`. Stage 2 and 3 runtime checks passed before this review; that is a software result, not anatomical validation.
