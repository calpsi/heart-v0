# Cardiac looping refinement, 5 October 2026

Reference reviewed in the browser: [Development of the Heart (3D), Hyeonjoo Kim](https://www.youtube.com/watch?v=a0qyagIgBPw), including the tube view around 0:10, established chamber view around 0:30, and front/side comparison later in the video. The reference is an educational animation, not a specimen reconstruction. Its chamber silhouette and spatial relationships guide this original rebuild; its region colours are not copied.

The first realism pass replaces the old uniformly swept U-shaped tube with a voxel-blended sculpture of ventricular and atrial masses, an anterior outflow, narrower AV region and four separately selectable branch landmarks. The original 36 tissue identifiers remain; the complete asset has 40 parts. Hollow myocardial, cardiac-jelly and endocardial walls remain separable and have removable anterior panels. Continuous surface normals reduce the artificial seams in the assembled view. Three tissue materials each use embedded 1024-pixel albedo, roughness and tangent normal maps; no procedural-only shader is required by the app.

Editable source: ../../blender/Heart_04_CardiacLooping.blend. Generator: ../../tools/refine_looping_v2.py. Original source, USDZ, manifest and assembled preview are preserved in before/.

This remains an illustrative established embryonic loop. Teaching cuts are regional partitions, not exact boundaries of embryonic derivatives. The branch openings are hollow landmarks attached to the surface, not fully reconstructed continuous vascular junctions. Complete trabeculation, cushions, embryo context, growth deformation and contractions remain absent. This is a visual/anatomical shape improvement, not a validated anatomical specimen. The remaining fifteen assets have not yet received this refinement.

The new shape and material pipeline should be reviewed before extending it to the other stages. Later fetal/adult hearts require different chamber proportions, valves, coronary vessels and epicardial detail; early stages require embryo/mesoderm context and continuous tube morphology.

Final export: 40 meshes, 234,232 triangles, nine embedded texture images, 18,084,069 bytes. All sixteen assets passed the Blender/USDZ validator, and the visionOS Simulator Xcode build succeeded. Simulator runtime checks passed all sixteen assets and 51 guided steps, including the refined model's 40 selectable parts. The assembled model was visually inspected in Free Exploration. Runtime results are recorded in ../../simulator-validation.json.
