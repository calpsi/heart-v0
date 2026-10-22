# Primitive heart tube refinement — 6 October 2026

This batch refines only Heart_03_PrimitiveHeartTube, the stage before cardiac looping. The early tube view in [Development of the Heart (3D)](https://www.youtube.com/watch?v=a0qyagIgBPw), reviewed during the preceding batch, provides the visual reference. All geometry and texture pixels are original.

The model retains all 36 selectable tissue IDs across six teaching regions. Its elliptical cross-sections, subtle asymmetry, regional swellings and narrower AV region replace the previous rotationally uniform surface. Analytically calculated normals maintain continuous shading across removable panels and region boundaries. Three tissue layers surround an open lumen. Nine embedded 1024-pixel colour, roughness and normal maps use the same tissue palette as the refined looping model.

Editable source: ../../blender/Heart_03_PrimitiveHeartTube.blend. Generator: ../../tools/refine_tube_v2.py. Original source, USDZ, manifest and preview are preserved in before/.

This is an illustrative enlarged pre-loop tube, not a segmented specimen or validated anatomical reconstruction. Teaching region boundaries and layer thickness are exaggerated. Embryo context, vascular tributaries, contraction and growth deformation remain absent. Two of sixteen assets have now received the first refinement pass; the other fourteen retain their original prototype geometry.

Export: 36 meshes, 163,008 triangles, nine embedded textures, 11,736,444 bytes. All sixteen assets passed source topology and USDZ checks. The visionOS Simulator Xcode build succeeded.

Simulator runtime checks passed all sixteen assets and 51 guided steps. The refined tube was visually inspected in Free Exploration; cutaway, isolation, separation and lesson reset behaviour passed the runtime checks.
