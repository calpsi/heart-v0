# Heart partitioning — four editable 3D teaching stages

An original whole-heart cutaway series corresponding to the two lower drawings in the supplied development diagram, with two intermediate states to explain the process. All ages are approximate **post-fertilization developmental ages**, not obstetric gestational ages. Development overlaps; these are teaching snapshots rather than day-exact reconstructions.

## Why four models

Two models suffice for a before/after comparison. Four are more useful for showing how the common spaces become four chambers:

| Model | What changes | Openings that should remain |
|---|---|---|
| 01 · Around week 4 / beginning of week 5 | Septum primum descends from the atrial roof; muscular ventricular septum rises from the floor; AV cushions are still separate | Ostium primum beneath the atrial septum, superior interventricular communication, common AV passage |
| 02 · Weeks 5–6 | Superior/dorsal and inferior/ventral cushions meet centrally; the primum meets the cushion complex; an upper opening develops in primum; muscular ventricular septum grows | Ostium secundum in primum; superior interventricular communication; right and left AV passages |
| 03 · Around week 7 | Superior ventricular closure joins muscular septum to the cushion/outlet region; the secondary atrial septum overlaps primum | Fetal atrial communication through offset openings; two separate AV passages |
| 04 · Around week 8 | Four chamber arrangement with developing tricuspid and mitral leaflets and simplified supporting attachments | **Foramen ovale remains patent**; there is no intended residual interventricular opening |

The foramen ovale is not an unfinished mistake: fetal circulation needs an atrial route. Septum primum becomes its flap on the anatomical left side. Functional flap closure occurs after birth as pressures change; anatomical fusion is later and variable. Do not animate the fetal opening closing at week 8.

The division is not a single wall growing straight through the heart. Atrial septation, AV cushion fusion, muscular ventricular septation, and superior/outlet closure are coordinated processes. Valves remodel over a longer period; week-8 leaflets are not adult valves.

## Deliverables

- `blender/`: editable `.blend` files with separate named tissue meshes, packed image textures, camera and studio lights. Open in the intended cutaway state. Reveal objects with `role=removable_front` for the full wall.
- `glb/`: portable textured GLB files, each in Cutaway and Full variants. Full includes removable anterior atrial and ventricular panels and complementary anterior portions of the septa/cushions.
- `usdz/`: textured RealityKit/Apple imports.
- `previews/`: transparent PNG renders and a labeled overview.
- `textures/`: original 1024 × 1024 color, roughness and normal maps.
- `manifests/`: part names, coordinates, caveats and mesh checks.
- `tripo-inspection.json`: measured reference FBX material/mesh details.
- `tools/`: reproducible Blender generation, inspection and verification scripts.

Files are in a separate asset folder; the existing sixteen app models and application catalog are not replaced.

## Reference finish

The inspected Tripo FBX has one mesh, 964,516 vertices, 1,929,044 faces, one UV set and one Principled material. It connects 1024² base color, tangent normal, roughness and metallic images. The base color is sRGB; data maps are Non-Color. The roughness map averages 11.58/255 and the metallic map 2.80/255: a mostly nonmetallic, very glossy reference. The new cutaway interiors use a softer gloss so fine tissue remains legible. There are no camera/light settings in that file establishing the screenshot's exact viewport lighting.

These assets use the same general image-textured PBR approach: nonmetallic tissue, irregular color variation, fine normal detail, varying roughness and broad studio highlights. Their colors and textures are original, not transferred from the aorta UV map. Plum outer atrial tissue is a visual styling convention; embryonic tissues are not literally oxygenation-coded blue and red. Lighting is an approximation of the supplied visual reference.

## Import and interaction

Use the **Full** model for removable-wall interaction; use **Cutaway** for immediate interior display. Preserve the hierarchy and named meshes. In RealityKit, load as an `Entity`, not a flattened mesh. Anterior wall panels have names `AtrialWall_Anterior` and `VentricularWall_Anterior`; internal continuations end in `_AnteriorContinuation`. Hide all meshes with `role=removable_front` to reproduce the preview. Stable anatomical part names repeat across snapshots; objects absent at an earlier stage are introduced later.

The files are enlarged teaching models, approximately 20 cm tall, not embryo life size. Blender uses +X anatomical left, -Y anterior, +Z superior. GLB/USDZ use +X anatomical left, +Y superior, +Z anterior. Thus anatomical right is on the viewer's left in the front view. Rotate to inspect atrial septal openings edge-on versus obliquely.

Use a discrete stage switch or crossfade between separate entities. A raw vertex morph is not supported: perforation, cushion fusion and closure change topology. The models contain no heartbeat, growth simulation, blood-flow animation, or skeletal rig.

## Scope and educational limits

These are original illustrative meshes, not segmented specimens. The overall shape is held approximately constant to make septal changes easy to compare; it does not reproduce full chamber growth/rotation between weeks 4 and 8. Tissue thicknesses and openings are exaggerated for readability. Outflow vessels and complete conotruncal anatomy are omitted in this focused chamber cutaway; the superior closure component indicates their contribution without modeling their full development. Atrial/ventricular walls are grouped, with anterior panels cut artificially for teaching. Valve leaflets and subvalvar structures are simplified primordia. Expert anatomical review is still needed before assessed teaching use.

## Anatomy sources

- [UNSW: atrial septation animation and sequence](https://embryology.med.unsw.edu.au/embryology/index.php/Development_Animation_-_Heart_Atrial_Septation) — primum, ostium secundum and secundum.
- [UNSW: advanced cardiac septation](https://embryology.med.unsw.edu.au/embryology/index.php?title=Advanced_-_Cardiac_Septation_2) — muscular septum, superior closure, fetal flap.
- [UNSW: cardiovascular development](https://embryology.med.unsw.edu.au/embryology/index.php/Cardiovascular_System_-_Heart_Development) — overview and terminology.
- [Human cardiac development MRI/EFIC atlas](https://pmc.ncbi.nlm.nih.gov/articles/PMC3411176/) — chamber, septal and valve morphology. This paper uses estimated gestational ages; do not copy its week numbers directly into a post-fertilization timeline.
- [Development of the AV valve tension apparatus in the human heart](https://pubmed.ncbi.nlm.nih.gov/9764545/) — development and remodeling of valve support structures.

## Rebuild

Run from the project folder with Blender 5.2:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python HeartAssets/partitioning-v1/tools/build_partitioning.py -- --stage 1
```

Repeat with stages 2, 3 and 4. Blender may require execution outside the macOS sandbox to initialize its rendering libraries.

## Verified output

All four stages passed the saved mesh/container checks and local geometric probes. These checks confirm closed nonempty tissue meshes, positive volume, embedded GLB/USDZ textures, stable part names, Y-up/metre USD metadata, and the presence or absence of tissue at selected opening landmarks. They do not establish complete physiological connectivity, expert anatomical accuracy, or device performance.

| Stage | Separate pieces, full model | Cutaway triangles | Cutaway GLB |
|---|---:|---:|---:|
| 01_Week04_EarlyPartitioning | 33 | 162,782 | 15.8 MB |
| 02_Weeks05-06_CushionFusion | 38 | 246,608 | 20.2 MB |
| 03_Week07_VentricularClosure | 42 | 251,650 | 20.3 MB |
| 04_Week08_FourChambers | 52 | 262,790 | 20.6 MB |

Reports: `validation.json` and `anatomy-probes.json`. Transparent preview PNGs contain no labels; the two labeled endpoint JPGs and overview sheet are presentation aids.
