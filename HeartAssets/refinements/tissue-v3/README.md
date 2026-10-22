# Tissue appearance revision — app assets

Work started 14 October 2026. `progress.json` records completed exports in stage order; `export-validation.json`, the main asset `validation.json`, and the simulator report record separate verification steps. An export is not a completed integration check.

The app's existing named parts, hierarchy, comparison states and USDZ filenames are retained. Editable sources are in `HeartAssets/blender`, and the exports replace the corresponding files in the RealityKit package. Stage/anomaly thumbnails are refreshed from the new renders.

## Changes

- Stages 1–2: deeper cardiogenic tissue, rounded irregular cords, more dimensional context, and higher-resolution paired tubular walls with three independently removable layers. The surrounding tissue is set behind the tubes to keep their lumens clear.
- Stages 3–4: retain the earlier reconstructed tube/loop forms and add subtle coherent surface relief.
- Stages 5–16: refine the existing contours while retaining anatomical topology, apertures and discrete comparison states. Atrial walls gain asymmetry, the primum gains shallow folds, cushion/canal volumes become less regular, lower ventricular contours taper towards an offset apex, and vessel curves gain subtle irregularity. These are contour refinements, **not** new specimen-derived whole-organ reconstructions.
- All stages: nonmetallic warm tissue colours, irregular mottling, variable moist roughness and fine normal detail. Three 2048² image maps per asset are baked from continuous 3D fields. No baked lighting, shadows or renderer-only subsurface effects are required in RealityKit.
- Runtime presentation: a bundled neutral studio environment provides image-based lighting in overview and close-up scenes. The first four assets start at a slight oblique angle to expose depth; reset uses the same angle.
- All original part IDs remain individually selectable, isolatable and separable. A shared texture atlas does not combine the mesh entities.

The early embryonic stages are tissue fields and tubes, not miniature adult hearts. Adult epicardial fat or a mature coronary tree is not added to those stages. Developmental context: [UNSW heart development](https://embryology.med.unsw.edu.au/embryology/index.php/Cardiovascular_System_-_Heart_Development).

This improves depth and surface finish. It is still an illustrative educational series, not specimen-derived photorealistic anatomy. The regional teaching models retain exaggerated wall thicknesses, simplified internal structures and artificial removable cut planes. Further work can add anatomically reviewed internal relief and replace schematic topology where needed.

## Rebuild one stage

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 --python HeartAssets/tools/refine_tissue_v3.py -- --stage 1
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 --python HeartAssets/tools/validate_batch01.py -- --stage 1
```

The generator always reads the immutable original in `before/<asset>/`. Rebuilding never accumulates deformation. Source files, manifests, exports and preview images were backed up before replacement. Later rendering and export scripts should use this revision generator rather than overwriting its results with the original batch generators.

`validate_tissue_v3.py` checks actual exported PBR map connections, embedded texture sizes and catalog IDs. Debug simulator validation additionally checks imported material textures on every mesh, alongside the established visibility, separation, reassembly and guided-lesson tests.

## Lighting implementation

`build_tissue_lighting.py` generates the neutral HDR source in `heart v3/Resources/HeartTissueStudio.skybox`. `HeartModelScene` loads it once asynchronously and assigns an image-based light receiver to each model. The light stays fixed relative to its presentation container while the anatomy rotates. This follows Apple’s [EnvironmentResource](https://developer.apple.com/documentation/realitykit/environmentresource) and image-based lighting APIs. It affects the anatomy only, without replacing the surrounding visionOS environment.
