# Anatomy review — 18 October 2026

## Verdict

I reviewed the installed catalogue, all 16 teaching-model previews, their construction scripts and limitations, the HDBR-derived stage catalogue, and published developmental anatomy. The current teaching assets are **regional diagrams with some correct anatomical relationships**, not realistic, stage-accurate whole embryonic hearts. Adding surface texture cannot fix their missing structures, generic chamber geometry or mixed developmental snapshots.

The seven HDBR assets are a stronger basis for stage-specific regional shape. Their unchanged source vertices demonstrate faithful conversion, not a new independent validation of the source segmentation. They do not supply complete tissue walls. The app must not present coloured region surfaces, display separation directions or conversion scale as measured anatomical boundaries, movement or dimensions.

This is my evidence-based review, not a claim that a clinician examined these assets. I have not performed histological registration, measured wall thickness against sections, or verified every lumen by volumetric sampling in this pass. Construction-code findings below are distinguished from measured mesh findings. No new geometry is marked anatomically validated.

## Model-by-model assessment

| Asset | What the installed model supports | Finding and disposition |
|---|---|---|
| 01 Cardiogenic region | A crescent and paired vascular precursors in schematic embryo context | The thick isolated crescent and two cords are diagrammatic, not a reconstructed tissue field. No measured early vascular network or adjacent tissue interfaces. **Keep as a diagram; rebuild for realistic early-stage anatomy.** |
| 02 Paired tubes | Endocardium, jelly and myocardium can be inspected separately | The two regular, widely separated tubes omit folding context and vascular connections. The construction does not establish their wall thickness or precise stage. **Useful layer diagram, not a complete embryonic configuration.** |
| 03 Primitive tube | Inflow-to-outflow regional ordering and nested layers | Its stacked, straight segment map is explicitly unfolded. Missing dorsal/vascular context and asynchronously developing regions prevent assigning the entire object one exact embryonic age. **Keep as a regional map; not a realistic stage replacement.** |
| 04 Looping | Broad looping concept and named regions | The installed elongated outflow and rounded swellings differ from the compact HDBR CS11 reference; source manifest also disclaims continuous vascular reconstruction. The prior lining-patch draft does not solve global shape. **Highest-priority geometric replacement; do not treat repaired local junctions as an accurate heart.** |
| 05 Atrial septation | Primary opening, secondary opening and overlapping flap/rim concepts | Builder uses separate thin ellipsoids with Boolean openings. No dedicated mesenchymal cap or dorsal mesenchymal protrusion; later rim is a separate plate rather than reconstructed wall infolding. **Incomplete mechanism and shape.** Lesson now names the omitted contributors and distinguishes later arrangement from early septation. [A], [B] |
| 06 AV cushions | Opposing major cushions, lateral cushions, one versus two AV openings | Rounded masses in an isolated ring are a cross-sectional diagram. No full atrial/ventricular junction context. The lesson incorrectly attributed muscular crest formation to cushions; corrected to distinguish myocardium from mesenchymal septal contributions. **Retain the canal-division concept; rebuild the junction in context.** [B], [C] |
| 07 Ventricular septation | Persistent superior communication versus closed comparison | Symmetric shell/partition construction and an enlarged closure patch do not demonstrate true ventricular morphology or the remodeling of the communication. **Concept illustration only; membrane size, outlet alignment and stage require reconstruction.** [C] |
| 08 Outflow septation | Opposed cushions and separate channels | Builder imposes a fixed quarter-turn on a lofted tube and adds rounded cusp primordia. It explicitly says the angle is schematic. This cannot establish actual torsion, truncal/conal remodeling or valve-root anatomy. **Rebuild from stage-specific geometry; do not teach a literal twisting partition mechanism.** [D] |
| 09 Valve refinement | Early cushions versus a later leaflet/chordal reference | Isolated valve stations are not an in-situ embryonic heart. The later state appropriately distinguishes mature-looking layers and papillary apparatus from early cushions. **Conceptually useful with existing labels; layer thickness and attachment geometry are not histological measurements.** Human valve tension apparatus develops through tissue remodeling, not a material swap. [E] |
| 10 Birth transition | Flap apposition and a still-narrow ductal lumen | The model can illustrate two structural changes but omits complete circulation and does not model pressure. Lesson wording implied inevitable later fusion; corrected to allow persistent PFO. **Retain as a transition diagram, not a flow model or instantaneous anatomical closure.** [F], [G] |
| 11 Perimembranous VSD | A real opening and nearby aortic/tricuspid landmarks | The upper opening is situated as an intended perimembranous example. The generic septal shell and limited valve apparatus do not establish the detailed fibrous borders of that subtype. **Subtype is intended, not independently confirmed from complete border morphology.** [C] |
| 12 Secundum ASD | Actual tissue deficiency in a fossa-floor disk; separate intact state | This differs appropriately from a PFO flap. Surrounding chamber walls, venous context and rim proportions remain generic; the central round hole cannot represent all ASDs. **Accept for the limited tissue-deficiency concept, not subtype variation or measured anatomy.** [A] |
| 13 Fallot | Outlet opening, overriding aortic origin, narrowed RV outflow and thickened RV wall | Builder makes a narrow tube plus thickened half-shell; it does not explicitly construct the displaced outlet septum or realistic septoparietal trabeculations. **The four-feature checklist is present, but the anatomical mechanism is missing.** Corrected lesson to disclose that omission and distinguish pressure-related hypertrophy from the initiating defect. [H] |
| 14 TGA | Builder places aortic origin in the right-sided cavity and pulmonary origin in the left, with atrial connections and an illustrative mixing opening | This supports the intended connection mismatch. However, the ventricles are halves of a shared ellipsoid and do not independently demonstrate morphologic RV/LV identity. **Connection diagram passes a limited code review; full segmental-anatomy validation does not.** Parallel exterior vessels alone are insufficient. [I] |
| 15 Coarctation | Eccentric lumen narrowing after the left subclavian branch, near a ductal remnant | Code changes the inner radius rather than painting a constriction. Arch shape, narrowing dimensions and wall layers are illustrative; no diffuse hypoplastic arch or collateral network. **Accept as one regional narrowing example, not an age-specific or severity model.** |
| 16 PDA | Hollow duct connects pulmonary and aortic regions; closed state restores vessel walls and uses a solid remnant | Appropriate patent-versus-closed structural contrast. Patent fetal duct is normal; postnatal persistence is the abnormality. **Accept the limited comparison, not a closure animation or a universal timeline.** [G] |

“Accept” above means the stated narrow teaching concept is supported by this review. It does not certify the whole model.

## Stage-atlas assessment

CS11 N662, CS12 N288, CS14 N925, CS16 N1815, CS17 N1699, CS18 N1645 and CS20 N913 retain 57 source regions. Source hashes and per-object vertex checks support the conversion. The CS11 constant-colour shader required an equivalent conversion, verified in RealityKit. Their names and stage IDs must stay attached when used as references. [J]

I do **not** approve interpreting the atlas as seven complete tissue-layer reconstructions. Missing regions are not biological absence; apparent surface ridges may include segmentation characteristics. Stage groups in the app are navigation aids, not specimen-age measurements. Anatomical orientation labels remain withheld until the source axes are registered. Do not manufacture a wall by shelling a chamber-region surface and describe the resulting thickness as observed anatomy.

## Confirmed content corrections applied

- Atrial primary-opening closure now includes the mesenchymal cap, AV cushions and dorsal mesenchymal protrusion; the model's omission is explicit.
- The later atrial rim is described as wall infolding, not simply a second descending free plate.
- Removed the claim that AV cushions form the muscular ventricular septal crest.
- Birth lesson no longer promises anatomical fusion of every foramen ovale.
- Fallot lesson now identifies the omitted outlet-septal displacement and pressure-related nature of hypertrophy.
- Semilunar primordia are distinguished from mature valves.
- Atrial lesson timing now states early-to-later comparison instead of placing both snapshots inside Days 27–37.

## Rebuild order and acceptance criteria

1. **Looping:** establish source axes/landmarks first; replace global chamber and outflow arrangement before adding texture. Keep lumen-region and tissue-wall representations distinct.
2. **Atrial/AV junction:** construct continuous atrial wall, primary septum, mesenchymal cap, DMP and cushion interfaces at a selected stage; show the later wall fold in a separate, identified stage.
3. **Ventricular/outflow:** reconstruct chamber asymmetry and outlet connections, then septal borders and valve primordia. Replace arbitrary twisting lofts with evidence-based snapshots.
4. **Anomalies:** start from a credible formed-heart base. For Fallot explicitly model outlet malalignment; for TGA verify atrial, ventricular and arterial connections using morphology rather than position alone.
5. **Early stages and layers:** use histological sections for tissue boundaries. Label any exaggerated thickness and artificial dissection planes. Avoid adult epicardial fat, coronary anatomy or mature fibre patterns in early embryos.

For every replacement: review matched-stage external and sectional views; verify included/omitted structures; document source and coordinate frame; inspect lumen connectivity; then test USDZ import, isolation pivots and reassembly separately. Software checks cannot substitute for these anatomical checks.

## Sources and evidence scope

[A] [Jensen et al., Evolution and Development of the Atrial Septum](https://pmc.ncbi.nlm.nih.gov/articles/PMC6588001/) — review; indexed descriptions of cap/DMP fusion and later infolding.

[B] [Development of the myocardium of the AV canal and vestibular spine in the human heart](https://pubmed.ncbi.nlm.nih.gov/11230106/) — primary human embryonic tissue study; abstract reviewed.

[C] [Closure of the interventricular foramen and morphogenesis of the membranous septum](https://pubmed.ncbi.nlm.nih.gov/6721204/) — primary human developmental study; abstract reviewed.

[D] [Hikspoors et al., staged human heart reconstructions](https://pmc.ncbi.nlm.nih.gov/articles/PMC8917235/) — primary reconstruction study. Indexed text and earlier local comparison reviewed; direct full-page/PDF fetch was blocked in this pass. This study describes substantial staged remodeling, not an arbitrary fixed-angle partition.

[E] [Development of the AV valve tension apparatus in the human heart](https://pubmed.ncbi.nlm.nih.gov/9764545/) — primary human microscopy study; abstract reviewed.

[F] [Foramen Ovale Closure Is a Process of Endothelial-to-Mesenchymal Transition Leading to Fibrosis](https://pmc.ncbi.nlm.nih.gov/articles/PMC4162597/) — experimental study; introductory human persistence statement supports variable closure, not a species-transferred human timetable.

[G] [Ductus Arteriosus in Fetal and Perinatal Life](https://pmc.ncbi.nlm.nih.gov/articles/PMC11050351/) — review; distinguishes functional from later anatomical closure.

[H] [Tetralogy of Fallot](https://pmc.ncbi.nlm.nih.gov/articles/PMC2651859/) — anatomical/clinical review; outlet displacement, trabeculations and four cardinal features.

[I] [Transposition of the great arteries](https://pmc.ncbi.nlm.nih.gov/articles/PMC2577629/) — anatomical/clinical review; concordant AV and discordant ventriculoarterial connections. [Primary echocardiographic study of ventricular morphology](https://pubmed.ncbi.nlm.nih.gov/7278370/) supports identifying ventricles by morphology, not side alone.

[J] [HDBR Atlas heart resources](https://hdbratlas.org/organ-systems/cardiovascular-system/heart.html) and [interactive source models](https://hdbratlas.org/interactive/heart.html). Local converted specimens and source records inspected.

App evidence: HeartModels.json, HeartReferenceModels.json, GuidedLearningView.swift, installed preview contact sheet, individual asset manifests, build_batch03–08.py and earlier-stage refinement scripts/review notes. This report does not claim every current vertex was compared to a histological section.
