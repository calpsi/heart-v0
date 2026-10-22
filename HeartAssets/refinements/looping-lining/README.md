# Junction lining draft

Four independent thin lining patches were added over the detected exposed bore-wall polygons from the repaired looping draft. They preserve the original 40 selectable objects and add four selectable collar objects (44 total). The original app asset is unchanged.

Blender complex solidification handles intersecting patch boundaries. All four new pieces pass manifold and positive-volume checks. The new linings obstruct none of the 3,400 local passage samples. USDZ export contains 44 meshes; see `lining-validation.json` for the file hash and coverage-face inventory.

These are local patches, not a reconstructed complete endothelial sheet. Their edges still require continuity review against the chamber and vessel lining. The 0.08 mm displayed thickness is an illustrative modelling choice, not a histological measurement. The full model remains stage-unvalidated and must not be promoted automatically.

The cutaway hides the original anterior wall pieces while keeping lining patches visible for inspection; small projecting rings are lining geometry, not valve leaflets. This preview behavior needs a coordinated dissection mask before app integration.

Further comparison now uses the HDBR Atlas CS11 specimen N662, whose public GLB was inspected separately in temporary storage. HDBR anatomy meshes have not been copied into this asset. Source: https://hdbratlas.org/interactive/heart.html. HDBR material is CC BY-NC-SA 4.0: https://hdbratlas.org/terms.html.
