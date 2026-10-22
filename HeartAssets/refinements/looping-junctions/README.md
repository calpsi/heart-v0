# Looping junction repair — development draft

This folder is not the app's asset directory. The installed looping asset is unchanged.

`repair_looping_junctions.py` starts from the withheld layered-tissue source. It opens the chamber-wall intersections and the mutually obstructing paired vessel walls. Boolean operations are restricted to intersecting bounding boxes, followed by microscopic degeneracy cleanup. Existing selectable part identities are retained.

Geometry validation checks all 40 tissue volumes for closed manifold boundaries and positive signed volume. Four local vascular paths each receive 850 occupancy probes, including small off-axis offsets. Occupancy uses majority parity from three ray directions to reduce grazing-edge false positives. These samples demonstrate local clearance, not complete vascular connectivity, fluid simulation, or anatomical validation.

`finish_looping_draft.py` reduces baked normal-map relief and increases roughness to reduce the earlier exaggerated mottled highlights. These are artistic changes, not tissue measurements. It exports Blender and portable USDZ files, renders assembled/cutaway views, and verifies the 40 exported parts and three embedded 2048px texture maps.

## Remaining release blockers

- Continuous endocardial coverage across the new junction collars is not established. Simply opening a passage exposes cut tissue and does not recreate the lining.
- Whole-heart chamber topology and axes still need comparison with a single specified Carnegie stage.
- Current thick walls, stylized silhouette and teaching cuts must not be mistaken for specimen-derived anatomy.

Use `junction-validation.json` for current results and the output USDZ hash. Keep this draft out of the application until the anatomical blockers are addressed.
