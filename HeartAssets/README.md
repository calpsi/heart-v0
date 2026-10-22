Current spatial interaction and tissue detail work: [tissue-v4](refinements/tissue-v4/README.md).

# HeartV3 — developmental heart assets

Current appearance work: [tissue-v3 revision](refinements/tissue-v3/README.md). This revision replaces the app exports and thumbnails in stage order, with backups and a restartable progress record. Use its generator when rebuilding revised assets.

## Integrated batches 01–08 • sixteen editable teaching prototypes

Built in Blender 5.2.1, with natural tissue colours, subtle image-based surface variation, and separate named meshes. These are original, simplified anatomical illustrations, not segmented human specimens or clinically validated anatomy. Microscopic layers are enlarged for learning. Timing follows the app's post-fertilization labels; developmental events overlap.

| Asset | Guided Learning | Free Exploration | Separate meshes |
|---|---|---|---|
| `Heart_01_CardiogenicRegion` | Cardiogenic region · Days 18–19 | Day 18 · Cardiogenic Field | Crescent, left/right angioblastic cords, endoderm context, neural plate context |
| `Heart_02_PairedHeartTubes` | Paired heart tubes · Days 20–21 | Day 21 · Paired Tubes | Left/right myocardial mantle, cardiac jelly, endocardium; each split into anterior/posterior panels; endoderm context |
| `Heart_03_PrimitiveHeartTube` | Primitive heart tube segments | Day 22 · Single Tube | Refined asymmetric tube: six regions, each with myocardium, jelly and endocardium split into removable panels (36 meshes) |
| `Heart_04_CardiacLooping` | Cardiac looping (D-looping) | Days 23–28 · Cardiac Looping | Sculpted chamber masses, six tissue regions with removable layered panels, and four branch landmarks (40 meshes) |
| `Heart_05_AtrialSeptation` | Atrial septation | Day 28 · Septation begins | Atrial/AV wall panels, cushion anchors, early primum, later primum/flap and secundum (9 meshes, two states) |
| `Heart_06_EndocardialCushions` | Endocardial cushion fusion | Day 35 · AV cushion fusion | Canal wall panels, two lateral cushions, superior/inferior cushions before and after fusion (8 meshes, two states) |
| `Heart_07_VentricularSeptation` | Ventricular septation | Day 35 · Developing septa, model chooser | Four removable wall panels, muscular septum states, AV/outlet contributions, closure patch, outlet panels and trabecular ridges (19 meshes) |
| `Heart_08_OutflowSeptation` | Outflow tract septation | Day 50 · Outflow septation | Wall panels, opposing/fused ridge states, outlet panels, six cusp primordia and four schematic neural-crest markers (20 meshes) |
| `Heart_09_ValvularRefinement` | Valvular refinement | Day 50 · Outflow and valves, model chooser | Four valve assemblies, 11 cushion/leaflet territories, 10 chordae, 5 papillary muscles, 3 separate aortic cusp layers and support panels (51 meshes across states) |
| `Heart_10_CirculatoryTransition` | Circulatory transition | Birth | Chamber walls, septa, open/apposed atrial flap, patent/constricting ductus, aorta, pulmonary vessels and optional lungs (23 meshes) |
| `Heart_11_VentricularSeptalDefect` | Ventricular Septal Defect (VSD) · 3 steps | Anomalies · VSD | 22 meshes: ventricular wall cuts, muscular/superior septal borders, intact comparison tissue, outlet panels, valve landmarks and trabecular ridges |
| `Heart_12_AtrialSeptalDefect` | Atrial Septal Defect (ASD) · 3 steps | Anomalies · ASD | 19 meshes: atrial wall cuts, oval fossa rim, deficient/intact floor, caval and AV mouths, pectinate ridges |
| `Heart_13_TetralogyOfFallot` | Tetralogy of Fallot · 4 steps | Anomalies · Tetralogy of Fallot | 28 meshes across Fallot/normal states: wall cuts, septum, overriding/LV aorta, narrowed/open RV outflow cuts, pulmonary branches and AV inlets |
| `Heart_14_TranspositionGreatArteries` | Transposition of the Great Arteries · 4 steps | Anomalies · d-TGA | 24 meshes: alternative arterial origins, ventricular walls/septum, shared atrial walls and AV links, open/intact atrial septum |
| `Heart_15_AorticCoarctation` | Coarctation of the Aorta · 4 steps | Anomalies · Coarctation | 17 meshes: arch/descending cutaways, three arch branch cutaways, narrow/open isthmus states, pulmonary arteries and ductal remnant |
| `Heart_16_PatentDuctusArteriosus` | Patent Ductus Arteriosus · 3 steps | Anomalies · PDA | 21 meshes: shared arch/branch/descending cutaways, patent/closed parent walls, open duct cutaways and solid ligament |

Each `.blend` in `blender/` contains editable geometry and a preview camera/light setup. Batch 03 opens in its initial teaching state; alternate-state objects are hidden in the viewport and can be revealed from the Outliner. `previews/` contains assembled and separated/cutaway renders. For batch 03, `_assembled` shows the early state and `_layers` the later state; the atrial wall is cut away in both. Exported `.usdz` files are already in the existing Xcode RealityKitContent package at:

`Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets/`

The USDZ files contain embedded albedo textures and independent tissue meshes. They exclude preview cameras/lights. All sixteen are connected to Guided Learning and Free Exploration through `HeartModelView.swift` and the bundled `Resources/HeartModels.json` catalog. Every developmental and anomaly lesson now has a static model. The app's original lesson text and narration remain; supported lessons display instructions for the implemented model controls.

The viewer supports drag rotation, tap/menu selection with other tissues dimmed, isolation, removable anterior panels, surrounding-tissue visibility, separation/reassembly, size and reset controls. Guided cards automatically select a relevant part as the learner advances. Each stage has its own loading lifecycle and retry state. Continuous developmental animations, contractions and flow are not implemented.

The approved interface refinement now consolidates model controls, exposes guided actions, restores each lesson step consistently, and places shared-stage choices beside the familiar slider. See [interface notes](INTERFACE.md) for the 27 September 2026 changes and visual checks.

## Verification

The first realism refinements rebuild cardiac looping and the primitive tube with continuous surface shading and embedded colour, roughness and normal textures. The other fourteen models retain their original prototype geometry. See also [primitive tube notes](refinements/tube-v2/README.md). See [refinement notes](refinements/looping-v2/README.md) for reference details and anatomical limitations.

- Final USDZ files passed hierarchy, material binding, embedded texture, closed-mesh topology, positive-volume, Y-up and metre-unit checks. Detailed counts are in `validation.json`.
- All sixteen models passed the compiled-app simulator checks, including both states for each batch-03/04/05/06/07/08 model; the saved result is `simulator-validation.json`. The final visionOS Simulator build also passed.
- Cardiogenic region: 5 meshes, 15,332 triangles, 0.96 MB USDZ. Paired tubes: 13 meshes, 35,248 triangles, 1.89 MB USDZ.
- The visionOS Simulator build succeeded in Xcode 27 after explicitly restoring the existing local RealityKitContent package reference in `project.pbxproj`.
- Assembled and cutaway Blender renders were visually inspected. The simulator regression runner loads the compiled RealityKit assets and checks named parts, cutaway/context visibility, isolation, separation, exact reassembly, reset and fitting. Run a Debug app with `--validate-heart-assets`; it writes `Documents/heart-asset-validation.json`. Hands-on gesture feel, final in-headset layout and educational accuracy still need review.

## Part and scale contract

- Names in `manifests/*.json` are the stable entity identifiers; use them for selection, highlighting, hiding or moving parts. Do not join the meshes.
- Each asset has one named root under `/HeartAsset`. `Tube_L` and `Tube_R` group each tube's six panels so the complete tube can move as a unit. Context is under `EmbryonicContext`.
- Blender is Z-up; USDZ is Y-up with metres as its unit. These are approximately 20–25 cm wide teaching models, **not life-size embryos**. In USD, cranial is +Y and the presentation viewing side is +Z. The stage-01 context uses a dorsal-style schematic orientation; L/R labels follow that convention.
- All layers are opaque to avoid transparency sorting problems. Hide the anterior myocardium and jelly panels to inspect the lining. Hide the lining's anterior panel too to open the lumen.
- Store each entity's starting transform before implementing an exploded view; restore that exact transform when reassembling.
- The two halves are removable teaching cuts, not natural anatomical divisions. Their coincident cut boundaries are intentional.

## Xcode / RealityKit use

Load the hierarchy as an `Entity`, rather than flattening it into a single `ModelEntity`. Xcode compiles the assets into the package's `.reality` resource; use the scene name without the USDZ extension, following [Apple's Entity loading API](https://developer.apple.com/documentation/realitykit/entity/init(named:in:)). In a RealityView's asynchronous content closure:

```swift
import RealityKit
import RealityKitContent

let heart = try await Entity(
    named: "HeartAssets/Heart_02_PairedHeartTubes",
    in: realityKitContentBundle
)
content.add(heart)

// Reveal the interior of the left tube.
heart.findEntity(named: "Myocardium_L_Anterior")?.isEnabled = false
heart.findEntity(named: "CardiacJelly_L_Anterior")?.isEnabled = false
heart.findEntity(named: "Endocardium_L_Anterior")?.isEnabled = false

// Context can be removed without disturbing the cardiac tissues.
heart.findEntity(named: "EmbryonicContext")?.isEnabled = false
```

For interactions, add collision shapes and `InputTargetComponent` only to the selectable tissue entities; context should not intercept tissue taps. Keep highlights in the app so anatomical base colours stay intact. The JSON manifests are documentation, not bundled runtime resources.

## Current lesson interaction readiness

| Card | Available now | Still needed |
|---|---|---|
| Cardiogenic C-Shape | Select, dim surroundings and isolate crescent | Development animation |
| Field Signals | Inspect and separate tissue/context meshes | Signal markers and signaling animation |
| Pre-Vascular Cords | Select and isolate independent left/right solid cords | Cell-cluster detail and lumen-formation sequence |
| Lateral Folding | Rotate, inspect and separate paired tissues | Folding tissue deformation and guided movement |
| Approaching Fusion | Working cutaway of mantle, jelly and lining panels | True fusion topology; translating tubes alone does not simulate fusion |
| Cranial-Caudal Inflow | Inspect open cranial/caudal tube ends | Detailed vitelline/umbilical and arterial connections, landmarks and flow |

Batch 01 establishes the part/export pipeline. It does not yet reproduce every visual or animation requested by the six learning cards. In particular, the embryonic disc and neural plate are orientation aids; they are not complete embryonic reconstructions. The paired layers are schematic, with exaggerated wall thickness and no claim of exact human dimensions.

## Full app coverage, in small future batches

Batches 01–08 now have static models and app controls; batches 03–05 have discrete developmental states and batches 06–08 have anomaly/comparison states. All ten developmental lessons and all six anomaly lessons have static models. Continuous animations, more complete anatomy and expert validation remain outstanding. The following backlog covers all 10 developmental lessons and all 6 anomalies currently present in the app; the animation and finer anatomy work listed for these batches remains outstanding. Before using these models for assessed teaching, review geometry, timing and labels with a domain expert.

| Batch | Guided lesson / anomaly | Required separable anatomy and states |
|---|---|---|
| 01 follow-up | Cardiogenic region; Paired heart tubes | Cell/cord lumen states, signaling landmarks, vessel connections and actual folding/fusion sequence |
| 02 | Primitive heart tube segments | Sinus venosus, primitive atrium, AV canal, primitive ventricle, bulbus cordis, truncus; removable mantle/jelly/lining; contraction sequence |
| 02 | Cardiac looping (D-looping) | Same segment IDs across straight/early/late loop states; atrial translocation, AV canal and early cushions |
| 03 | Atrial septation | Atrial walls, septum primum and secundum, cushion anchor; ostium primum/secundum and foramen ovale as true openings; movable flap |
| 03 | Endocardial cushion fusion | Superior/inferior cushions, common AV canal, left/right AV openings; separate unfused/fused states |
| 04 | Ventricular septation | Ventricular shells, muscular and membranous septa, interventricular opening and closure states, separate outflow channels |
| 04 | Outflow tract septation | Truncus/conus shell, paired spiraling ridges, neural-crest markers, aorta, pulmonary trunk, six semilunar cusp primordia |
| 05 | Valvular refinement | Individual mitral/tricuspid and semilunar leaflets, chordae, papillary muscles; simplified valve-layer cutaway |
| 05 | Circulatory transition + shared normal reference | Removable chamber walls, atrial flap, patent/constricted ductus, aorta and pulmonary tree, lungs as optional context; fetal and neonatal states |
| 06 | Ventricular Septal Defect (VSD) | Interchangeable normal and perimembranous-defect septum with genuine opening, flow path through defect |
| 06 | Atrial Septal Defect (ASD) | Explicit secundum-type defect variant; normal reference septum; separately editable right chambers for volume comparison |
| 07 | Tetralogy of Fallot | VSD, overriding aorta, narrowed RV outflow, thickened RV wall; compare against shared normal heart |
| 07 | Transposition of the Great Arteries (TGA) | Aorta connected to RV and pulmonary trunk to LV; separate flow circuits and clearly identified mixing pathways |
| 08 | Coarctation of the Aorta | Normal/narrowed aortic isthmus near ductal insertion; removable vessel wall and lumen; pressure overlay anchors |
| 08 | Patent Ductus Arteriosus (PDA) | Patent ductal lumen connecting pulmonary artery/aorta versus closed ductal remnant; transition states |

### Free Exploration mapping

| Existing slider stop | Planned assets |
|---|---|
| Day 18 · Cardiogenic Field | 01 |
| Day 21 · Paired Tubes | 02 |
| Day 22 · Single Tube | Primitive heart tube segments |
| Days 23–28 · Cardiac Looping | Illustrative D-looping state; the original single-day label was broadened to avoid implying exact Day 24 anatomy |
| Day 28 · Septation Begins | Early atrial, cushion and ventricular septation states |
| Day 35 · AV cushion fusion | Focused AV-junction model, before/after cushion fusion; ventricular walls and septation remain batch 04 |
| Day 50 · Outflow Septation | Later outflow and valve states |
| Birth · Circulatory Transition | Fetal-to-neonatal transition |

The slider has fewer stops than Guided Learning. Reuse the relevant states rather than creating unrelated copies. Day 35 now has a model chooser for cushion fusion and ventricular septation. The fixed-angle outflow lesson has been replaced with a description of progressive partitioning; exact timing and model anatomy still require content review.

## Reference basis

- [UNSW Embryology — Heart Development](https://embryology.med.unsw.edu.au/embryology/index.php/Cardiovascular_System_-_Heart_Development): early paired tubes within the developing pericardial region and relocation with embryonic folding.
- [UNSW Embryology — Cardiovascular System Development](https://embryology.med.unsw.edu.au/embryology/index.php/Cardiovascular_System_Development): cardiogenic region in splanchnic mesoderm and third-week tube fusion.
- [Development, Proliferation, and Growth of the Mammalian Heart](https://pmc.ncbi.nlm.nih.gov/articles/PMC6037201/): endocardial lining, myocardial layer and intervening cardiac jelly. Cross-species review; not a source of exact human model dimensions.
- [UNSW — Embryonic Heart Divisions](https://embryology.med.unsw.edu.au/embryology/index.php/Basic_-_Embryonic_Heart_Divisions) and [UNSW early vascular development lecture](https://embryology.med.unsw.edu.au/embryology/images/5/57/ANAT2341_Lecture_7_-_2014_Early_Vascular_Development.pdf): primitive tube regions and spatial changes with looping.

These references informed the structural concept. No reference images, scans or meshes were copied. Future anomalies require their own anatomical reference review before modelling.

## Rebuild one asset at a time

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python HeartAssets/tools/build_batch01.py -- --stage 1
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python HeartAssets/tools/build_batch01.py -- --stage 2
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python HeartAssets/tools/build_batch02.py -- --stage 3
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python HeartAssets/tools/build_batch02.py -- --stage 4
```

Rebuilding overwrites that stage's generated `.blend`, `.usdz`, manifest and previews. Save manual Blender edits under a different name before rebuilding.

## Batch 02 anatomical scope

The sinus venosus, primitive atrium, AV canal, primitive ventricle, bulbus cordis and truncus arteriosus have matching identifiers in both new assets. Each has a continuous hollow lumen through the regional boundaries; walls end in annular teaching seams, not plugs. The loop puts the inflow region dorsocranially, with the ventricular and bulbar regions curving ventrally. The proportions and shape are illustrative, not an exact Carnegie-stage reconstruction. No venous tributaries, cushions, trabeculations or dorsal mesocardium are included. The anterior/posterior cuts follow cross-sections around the tube; they are removable teaching panels.

The next small modelling batch is atrial septation and endocardial cushion fusion. Batch 02 still needs a true straight-to-loop transition and peristaltic motion before the corresponding gesture activities can be implemented.

## Batch 03: atrial septation and AV cushions

Two focused regional models are integrated in Guided Learning and the Day 28/35 Free Exploration stops. A pink segmented control switches between discrete states. Guided steps select the corresponding state and tissue. Reset restores each model’s initial state, presentation angle and wall visibility. The four earlier models retain their controls.

- **Atrial septation:** true inferior ostium primum in the early primum, a superior ostium secundum in the later primum, a lower primum flap deflected toward the anatomical left atrium, and a thicker incomplete secundum to its anatomical right. Remove/separate the overlapping tissues to inspect both openings. Nine meshes include shared atrial/AV wall panels and cushion anchors.
- **Endocardial cushions:** superior/dorsal and inferior/ventral cushions are separate meshes in both states. In the fused state their surfaces meet along a shared midline plane, forming a continuous central partition while leaving right and left AV openings. The lateral cushions remain separate. Eight meshes in total. The common canal is a focused, simplified junction; ventricular walls, valves and outflow are not present.
- Tissue thickness, surface detail and flap deflection are illustrative. No continuous growth, fluid dynamics, flap animation, signal markers or full venous attachments are claimed. These remain educational prototypes, not clinical anatomy.

### State/export contract

All variants are contained in each USDZ. When loading outside HeartV3, explicitly enable shared parts plus parts whose `state` matches the chosen state; otherwise incompatible variants overlap. `states`, `defaultState`, `defaultCutaway` and per-part `state` are in the manifests and runtime catalog. `separationOffset` is an authored USD-space displacement in metres, applied relative to each part’s stored rest position. USD +X is anatomical left, +Y cranial and +Z anterior for these models.

Rebuild one at a time with Blender using `tools/build_batch03.py -- --stage 5` or `--stage 6`. `tools/validate_batch01.py` validates all six assets and now also checks geometric clearance at the septal apertures and both AV orifices.

### Anatomical references

- [University of Minnesota — Differentiation and Septation](https://www.vhlab.umn.edu/atlas/congenital-defects-tutorial/normal-cardiac-development/differentiation-and-septation.shtml): cushion fusion dividing the AV canal, sequential primum/secundum development and overlapping fetal atrial communication.
- [UNSW — Intermediate Atrial/Ventricular Septation](https://embryology.med.unsw.edu.au/embryology/index.php/Intermediate_-_Atrial_Ventricular_Septation): atrial septation and lateral AV cushions. Search text was accessible; direct retrieval returned 403.

No reference meshes or images were copied. Batch 04 below completes the next two regional models.

Final batch-03 verification: all six USDZs passed mesh/material/unit checks; geometric aperture checks passed. The final app build and six-model runtime checks passed, including both new states, visibility, isolation, separation and exact reassembly. Both new models were visually inspected in Free Exploration in the simulator. UI automation could not click the state switch (`noWindowsAvailable`); state filtering is covered by the compiled-app runtime checks, while hands-on headset input remains untested.

## Batch 04: ventricular and outflow septation

Two more original Blender models are integrated into Guided Learning and Free Exploration. The Day 35 model chooser retains cushion fusion and adds ventricular septation. Day 50 opens outflow septation. Birth still has no asset; it is not incorrectly mapped to the eighth generated model. Thumbnail identity is now independent of timeline position.

**Ventricular model:** 19 separable meshes, 52,632 triangles. The open state preserves a superior interventricular communication between the muscular crest and the surrounding AV/outlet contributions. A separately selectable patch closes it in the later state; separate subaortic/subpulmonary outlet panels appear. Four outer wall panels and six enlarged trabecular ridges make chamber inspection possible. The rounded ventricular envelope and terminal outlet alignment are schematic; this does not reconstruct the entire process of ventricular outlet remodeling.

**Outflow model:** 20 separable meshes, 75,632 triangles. Opposing ridges leave a common passage; fused ridge halves divide it into two channels. Later-state aortic/pulmonary outlet panels each contain three individually selectable rounded cusp primordia. Four small context markers indicate neural-crest contribution and can be hidden. Their positions are illustrative, not cell tracking. The twisted wall cut follows the local tube frame; anterior/posterior panel names describe teaching cuts rather than exact embryonic surfaces.

Both models use the existing tissue palette and texture variation. The anatomy remains a simplified regional teaching prototype: no continuous growth, blood-flow simulation, mature leaflet motion, full arch branches or whole-heart vascular registration. The outflow twist is a schematic quarter-turn for inspection, not a measured developmental angle.

### References and lesson adjustment

[3D Anatomy of the Developing Heart: Understanding Ventricular Septation — Mohun and Anderson (2020)](https://cshperspectives.cshlp.org/content/12/11/a037465.full.pdf) describes 3D imaging of mouse development and the roles of outflow cushions and ventricular communication. It informed the distinction between distal/proximal partitioning and simple rigid rotation. It is not a source of exact human-day geometry. The app’s “180-Degree Spiral” card is now “Separating Outflow Channels”; its instructions refer to available state/part controls.

[UNSW — Advanced Outflow Tract](https://embryology.med.unsw.edu.au/embryology/index.php?title=Advanced_-_Outflow_Tract) supplies complementary embryology context. No source meshes or images were copied.

Rebuild one at a time: `tools/build_batch04.py -- --stage 7` or `--stage 8`. The existing validator now checks the ventricular communication/closure, clear outlet lumens, an open early outflow passage, a continuous later partition at five levels, both divided channels and all six cusp primordia. Shared parts and active-state parts must be enabled as described in the state contract above.

Batch 05 below adds valvular refinement and circulatory transition. The next small batch is ventricular and atrial septal defects.

Batch-04 verification: the final visionOS Simulator build passed. All eight exported assets passed hierarchy, embedded material/texture, manifold topology, positive volume and unit checks; the added aperture/channel checks passed. All eight compiled assets passed runtime loading, active-state filtering, part identification, cutaway/context visibility, isolation, separation, reassembly and fitting checks. Both new models were visually inspected in the simulator (ventricular in Guided Learning, outflow in Free Exploration). Headset gestures and the Day 35 chooser’s end-to-end input were not exercised by automation.

## Batch 05: valve refinement and birth transition

**Valvular refinement:** two static states compare thicker cushion-like leaflets with a thinner, tethered arrangement. The mitral has two leaflet territories, tricuspid three, and each semilunar valve three. Ten independent chordae appear in the refined state and attach to five papillary-muscle teaching meshes. One aortic cusp is split into ventricularis, spongiosa and fibrosa pieces with exaggerated thickness. All four assemblies are spaced apart for inspection; they do not represent a registered valve plane or a complete histological reconstruction. Support myocardium and papillary shapes are shared context across states, not an exact developmental sequence.

**Circulatory transition:** the model uses simplified chamber cavities with removable anterior walls. The fetal state has an open atrial flap and a patent ductal lumen. The transitioning state apposes the flap and narrows the ductal lumen while retaining patency. It does not depict instantaneous ductal obliteration or a mature ligamentum arteriosum. Independent aortic/pulmonary meshes have a ductal bore cut through the adjacent walls. Lung meshes provide removable orientation context; no lung inflation or pressure/flow simulation is implemented. Pulmonary veins, caval returns, coronary vessels and arch branches remain absent, so this is not yet a complete normal-heart reference for all anomaly comparisons.

The two models retain natural tissue colours and image-based surface detail. Parts remain selectable and separable, with cutaway, isolation, reassembly and reset controls. Guided cards switch states/focus to relevant structures and describe actual available interactions. Day 50’s model chooser now includes valve refinement, and Birth has its own model. The small caption clarifies spaced valve assemblies or gradual transition.

Rebuild one model per invocation using `tools/build_batch05.py -- --stage 9` or `--stage 10`. As with batches 03–04, the USDZ contains all variants: enable shared parts plus the selected state. The Blender source opens in its initial state with the anterior teaching cuts removed; hidden alternate parts remain editable in the Outliner. `_assembled` preview means initial state, `_layers` means refined/transition state.

### Reference basis

- [University of Minnesota — Valve Nomenclature](https://www.vhlab.umn.edu/atlas/anatomy-tutorial/cardiac-valve-nomenclature.shtml) and [Differentiation and Septation](https://www.vhlab.umn.edu/atlas/congenital-defects-tutorial/normal-cardiac-development/differentiation-and-septation.shtml): valve identities, chordal/papillary support and developmental context.
- [Merck Manual Professional — Perinatal Physiology](https://www.merckmanuals.com/professional/pediatrics/perinatal-physiology/perinatal-physiology): gradual physiological transition, atrial flap closure and ductal constriction.

Geometry is original and illustrative, not a scan or clinically validated reconstruction. No source images or meshes were copied.

The geometry validator checks valve-territory counts, chordal/papillary counts, three separate cusp layers, uncapped valve orifices, fetal versus apposed flap position, ductal narrowing with residual patency, and clearance at the pulmonary duct junction, in addition to all earlier topology/export checks.

Batch-05 verification: all ten exports passed mesh, hierarchy, material, texture, unit and geometric checks. The final visionOS Simulator build and all ten compiled-model runtime checks passed, including both states of each new model, part identification, visibility, isolation, separation, reassembly and fitting. Valve refinement was visually inspected in Guided Learning and circulatory transition in Free Exploration. Simulator input automation could not exercise button clicks; headset gestures remain untested.


## Batch 06: perimembranous VSD and secundum ASD

The new regional models use the established opaque tissue textures, individual named meshes, removable front panels, separation offsets and USDZ hierarchy. Each has `defect` and `intact` states; these compare anatomy, not progression or surgical repair. Editable Blender files open in the defect state. The `_assembled.png` previews show the defect; `_layers.png` shows the intact comparison, both with front walls removed.

- `Heart_11_VentricularSeptalDefect`: 22 meshes, 57,354 triangles, 2.80 MB USDZ. The opening crosses the upper ventricular partition near schematic aortic and tricuspid landmarks. The intact comparison restores tissue at that location. The ventricular envelope derives from batch 04; stable inherited part IDs are retained even where labels now describe anomaly anatomy. The intact object is comparison tissue, not an implanted patch.
- `Heart_12_AtrialSeptalDefect`: 19 meshes, 49,058 triangles, 2.51 MB USDZ. A true central tissue deficiency in the oval fossa floor is independently selectable from the rim. The intact floor occupies the same region. This depicts a secundum ASD, not a PFO valve tunnel. Caval and AV mouths provide regional orientation; complete pulmonary venous connections and ventricles are omitted.

Free Exploration now offers Development and Anomalies categories. Development retains the same eight-stop day slider. Anomalies uses two model thumbnails and does not assign defects to a developmental day (`category: anomaly`, `stageIndex: -1`). Guided Learning has three focused cards for each anomaly with selection-linked anatomy and actual model artwork. The app's References screen links the two clinical reference pages below.

Both models are enlarged teaching illustrations with simplified chamber shape, exaggerated septal thickness and approximate valve/vessel relationships. They do not simulate shunt flow, pressure or chamber dilation, and do not include other VSD/ASD subtypes, conduction anatomy or complete valve apparatus. The earlier backlog's flow and chamber-volume comparisons remain pending. An anatomical expert should review them before assessed teaching use.

Reference basis (no source meshes or images copied):
- [Merck Manual — Ventricular Septal Defect](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/ventricular-septal-defect-vsd): perimembranous location near aortic/tricuspid structures.
- [Merck Manual — Atrial Septal Defect](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/atrial-septal-defect-asd): secundum defect in the oval fossa; subtype distinction.

Rebuild one asset at a time with Blender in background mode using `tools/build_batch06.py -- --stage 11` or `--stage 12`. The existing `tools/validate_batch01.py` validates all batches, including finite cross-septal ray checks: active defect parts must leave a passage, intact tissue must intercept it, and surrounding septal tissue must remain present. The common checks cover positive closed mesh volumes, exported part counts, embedded textures/materials and metre/Y-up orientation.

Next small batch: Tetralogy of Fallot and Transposition of the Great Arteries. Coarctation and PDA follow in batch 08.

Batch-06 verification: the final visionOS Simulator build passed. All twelve exported assets passed topology, hierarchy, materials, embedded textures and units; the new defect/intact aperture checks passed. All twelve compiled assets passed runtime loading, part mapping, state visibility, isolation, separation, exact reassembly and fitting. VSD was visually inspected in Guided Learning and ASD in Free Exploration, including its selected anomaly thumbnail. Simulator coordinate input returned `noWindowsAvailable`, so end-to-end button clicks and headset gestures remain untested.


## Batch 07: Tetralogy of Fallot and d-TGA

Two further static regional models are integrated with editable Blender sources, named separable parts, cutaway panels and actual-model thumbnails. They use the existing tissue palette. Each anomaly has four guided cards with linked part selection. Free Exploration retains the developmental slider and now fits four anomaly thumbnails using short labels in a horizontally scrollable row; accessibility labels retain the full lesson names.

`Heart_13_TetralogyOfFallot` contains 28 meshes, 68,840 triangles and a 3.37 MB USDZ. Its `fallot` state shows an upper ventricular communication, an aortic mouth spanning the septal crest, a truly narrowed but patent RV outflow channel, and a thicker right ventricular wall. `normal_fallot` restores a continuous septum, left-ventricular aortic origin, wider outflow and thinner right wall. Both states use comparable outer ventricular envelopes. The pulmonary outflow is split into anterior/posterior teaching panels to expose the lumen.

`Heart_14_TranspositionGreatArteries` contains 24 meshes, 95,376 triangles and a 4.82 MB USDZ. The `tga` state has the aorta attached to the right ventricle and the pulmonary trunk to the left, with an anterior/right aortic proximal course. The `normal` state reverses those abnormal origins to the normal connections. Shared atrial walls and curved AV links provide orientation. The d-TGA state includes a true illustrative atrial communication; the normal comparison closes it. This particular example has an intact ventricular septum and no ductus.

These are anatomical comparison states, not a surgical or developmental sequence. The models remain schematic: chamber shape, wall thickness, vessel lengths and severity are illustrative, with no physiological scale or grading. They omit coronary arteries, arch branches, complete venous returns and valve leaflets. Fallot's detailed conal malalignment and valve-level stenosis are not separately reconstructed. TGA's complete parallel flow circuits are explained in the lesson but are not rendered as closed systemic/pulmonary loops. There is no animated flow, oxygen, pressure or contraction simulation. Expert anatomical review remains necessary before assessed teaching use.

Reference basis (original geometry; no source meshes/images copied):
- [Merck Manual — Tetralogy of Fallot](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/tetralogy-of-fallot): the four characteristic features and RV outflow obstruction.
- [Merck Manual — Transposition of the Great Arteries](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/transposition-of-the-great-arteries-tga): d-TGA ventricular origins, proximal artery relationships and mixing communications.

Rebuild one model per Blender invocation with `tools/build_batch07.py -- --stage 13` or `--stage 14`. `_assembled.png` shows the anomaly; `_layers.png` shows the normal comparison. Blender sources open in the anomaly state with anterior panels hidden; alternate-state meshes remain editable through the Outliner. Exported USDZs include both states and the app filters them through catalog metadata.

Geometry validation checks both sides of the overriding aortic mouth, the Fallot VSD opening versus normal septum, narrower versus patent outflow, right-wall thickening, independent expected TGA artery origins and open proximal lumens, and the atrial mixing opening versus intact comparison. All fourteen exports also pass the common topology, volume, hierarchy, materials, embedded textures and unit checks.

Next small batch: Coarctation of the Aorta and Patent Ductus Arteriosus (PDA), the remaining two anomaly lessons. Continuous animations and refinement of anatomical detail remain separate follow-up work.

Batch-07 verification: all fourteen exported assets passed geometry, topology, volume, hierarchy, embedded texture/material and unit checks. The final visionOS Simulator build passed. All fourteen compiled models passed runtime loading, part identification, state filtering, visibility, isolation, separation, exact reassembly and fitting checks. Both Blender comparison renders were inspected and reframed to include the complete arch. Fallot was visually inspected in Guided Learning and TGA in Free Exploration; all four anomaly thumbnails fit the chooser. A simulator coordinate-click attempt returned `noWindowsAvailable`; direct button input and headset gestures remain unverified. The temporary approval-review usage-limit failure was resolved on retry.


## Batch 08: coarctation and PDA

This batch completes static model coverage of the app's ten developmental lessons and six anomaly lessons. The new assets are regional great-vessel illustrations, with editable Blender sources, individually named mesh parts, embedded tissue textures and removable wall panels. The established developmental slider is unchanged. Free Exploration has six anomaly thumbnails, with automatic scrolling to keep the selected model in view.

`Heart_15_AorticCoarctation` has 17 separable meshes. The `coarctation` state uses an eccentric posterior-biased shelf to narrow the actual aortic lumen; the `normal` comparison retains the outer envelope with a wider channel. The isthmus is independently selectable from the arch and descending aorta. Three named arch branches and a closed ligamentum arteriosum provide orientation. This is one localized narrowing near the ductal region, not a reconstruction of every coarctation subtype.

`Heart_16_PatentDuctusArteriosus` has 21 separable meshes. The `patent` state contains a true hollow duct between the pulmonary and aortic lumens, with both parent-vessel openings cut into the geometry. The duct's anterior and posterior wall sections can be separated. The `closed` comparison replaces it with a solid ligamentum and restores the parent-vessel walls so no residual communication remains. It represents an anatomical endpoint rather than immediate birth closure, a repair procedure or a timed animation.

The four coarctation cards cover the narrowing, open comparison, ductal landmark and upstream left subclavian branch. The three PDA cards cover the patent lumen, pulmonary junction and closed remnant. Parts are selected as the learner advances. Both lesson thumbnails are renders of the actual models; both reference pages are linked in the app.

Limitations: simplified vessel geometry and enlarged wall thickness; no chamber context, coronary anatomy, full distal branching, diffuse arch hypoplasia or collateral circulation. Severity, pressure gradients, blood flow, oxygenation and closure dynamics are not simulated. The closed ductal endpoint should not be interpreted as occurring instantly at birth. Expert review remains necessary before assessed teaching use.

Reference basis (original geometry; no reference images/meshes copied):
- [Merck Manual — Coarctation of the Aorta](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/coarctation-of-the-aorta): typical location beyond the left subclavian branch near the ductal attachment.
- [Merck Manual — Patent Ductus Arteriosus](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/patent-ductus-arteriosus-pda): persistent communication between the pulmonary artery and aorta.

Rebuild one at a time with `tools/build_batch08.py -- --stage 15` or `--stage 16`. Blender opens the initial anomaly state with anterior panels hidden. `_assembled.png` shows the anomaly and `_layers.png` the comparison. Both states remain in the USDZ; catalog metadata controls runtime visibility.

The remaining backlog is refinement rather than missing lesson models: anatomical review, richer chamber/valve anatomy, developmental transitions, contraction/flow animations and headset interaction testing. Continue in small focused batches.

Batch-08 verification: coarctation contains 63,208 triangles in a 3.51 MB USDZ; PDA contains 75,004 triangles in a 3.96 MB USDZ. All sixteen exports passed topology, positive-volume, hierarchy, material, embedded-texture and unit checks. Geometric checks confirmed the coarctation shelf and remaining channel, the patent duct's continuous connection, and restoration of both parent-vessel walls in the closed comparison. The final visionOS Simulator build and all sixteen compiled-model runtime checks passed, including both new states, part mapping, visibility, isolation, separation, exact reassembly and fitting. Final Blender renders were inspected in both states. Coarctation was visually checked in Guided Learning and PDA in Free Exploration; the selected PDA thumbnail scrolled into view. Direct simulator button input and headset gestures remain unverified because coordinate-click automation is unavailable (`noWindowsAvailable`).
