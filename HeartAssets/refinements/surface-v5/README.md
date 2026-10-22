# Installed surface update

This is a consistent material and preview update of the existing app models. It is not a stage-specific anatomy rebuild.

Each source is backed up before editing. Tangent-normal relief is reduced to 45% of its previous amplitude; roughness is increased by 0.06. The baked colour atlas and vertex coordinates are preserved. All part identities, developmental states and lesson mappings are preserved. The known-invalid looping geometry drafts are not promoted.

For each asset the pipeline validates part identities, three connected 2048px PBR maps and archive integrity before updating the runtime USDZ, Blender source, manifest, two previews and catalogue thumbnail. Vertex-coordinate hashes confirm that the material update did not alter mesh geometry. `before/` folders allow restoration.

Run `summarize_surface_update.py` after all 16 exports complete to verify the installed files against their hashes. Then rebuild the app and run its live RealityKit checks, including the isolated-part pivot checks across all 355 parts. Saved reports distinguish export validation from simulator validation.

Stage-specific anatomical review remains incomplete for every asset. See `../../anatomy-review/` for outstanding issues; improved rendering does not establish anatomical accuracy.
