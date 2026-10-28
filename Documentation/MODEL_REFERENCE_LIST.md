# Model and development reference list

## Downloaded and integrated — 3D Heart Project

Downloaded 24 October 2026 using the public model pages' Download buttons, after user sign-in. Source USDZ geometry and materials retained. HeartV3 adds framing and manipulation controls; these are different specimens, not matched stages.

- [Normal Teenage Heart — 3D Heart Project](https://sketchfab.com/3d-models/normal-teenage-heart-fc6eda3c7c994a31a6e30c9e117353f4). CC BY-NC 4.0: https://creativecommons.org/licenses/by-nc/4.0/. Bundle: Normal_Teenage_Heart.usdz.
- [Coarctation — 3D Heart Project](https://sketchfab.com/3d-models/coarctation-0c71994adc644ed8bd4ff5544d92f26b). Model page licence CC BY 4.0: https://creativecommons.org/licenses/by/4.0/. Bundle: Coarctation.usdz.
- [Tetralogy of Fallot — 3D Heart Project](https://sketchfab.com/3d-models/tetralogy-of-fallot-9a2cb93e8e754cd6b3329613d9e40944). Model page licence CC BY 4.0. Bundle: Tetralogy_of_Fallot.usdz.
- [Heart library](https://www.3dheartproject.com/heart-library) and [Hearts 101](https://www.3dheartproject.com/hearts-101): visual and instructional references. Distinguish myocardium/whole-heart models from blood-pool representations.

## Developmental explanation sources

- [Development of the human heart](https://pmc.ncbi.nlm.nih.gov/articles/PMC7078965/): chamber and septal development. Search-index abstract/text accessible; full PMC page returned a browser challenge during this session.
- [Cardiac Embryology and Molecular Mechanisms of Congenital Heart Disease — A Primer for Anesthesiologists](https://pmc.ncbi.nlm.nih.gov/articles/PMC4996372/): developmental overview and abnormal outlet connections. PubMed figure descriptions accessible: https://pubmed.ncbi.nlm.nih.gov/27541719/.
- [Partitioning the heart: mechanisms of cardiac septation and valve development](https://pmc.ncbi.nlm.nih.gov/articles/PMC3424040/): septation relationships; no single-mechanism claim for all CHD.
- Coarctation explanation retained from the existing pilot: https://doi.org/10.3390/diagnostics13132189.

## Additional user references / availability

- https://3dqlab.stanford.edu/ai-modeling-congenital-heart-disease/ — retrieval failed; not inspected as a downloadable asset.
- https://www.youtube.com/watch?v=RpZHiwkFUM4
- https://www.youtube.com/watch?v=5DIUk9IXUaI
- https://www.youtube.com/watch?v=t1WCX1-XD3o
  Video contents were not inspected in this increment; no video copied or generated.
- https://voka.io/3d-anatomy/systemic/circulatory-system/mitral-valve/ — visual reference; no model downloaded.
- https://sketchfab.com/3d-models/embryology-of-cardiovascular-system-annotated-b9bd80e1b157406caa3fa23bf1da5533 — browser inspection succeeded after the search tool returned 403. No Download control was offered on the model page; no model downloaded. The visible annotations contain unresolved author comments, so they were not copied into lesson content.
- https://www.innerbody.com/image/card01.html — introductory heart reference, not an asset download.
- https://sketchfab.com/eLearningUMCG/collections/congenital-heart-disease-2aeecf5115ab4d9abc49f0439c71db89 — alternative anatomical source; UMCG normal neonatal heart download is available after login, but priority moved to 3D Heart Project per user preference.
- https://github.com/daviyahiro/cardiac-embryological-models — eight static Blender files downloaded to HeartAssets/external/yahiro for geometry inspection. No shape keys; incompatible vertex counts. No explicit licence in repository listing; not bundled.

The supplied pink developmental montage is a visual reference. No pixels or meshes have been extracted from it. A search located a related published figure in “Virtual Imaging for Teaching Cardiac Embryology”, https://doi.org/10.1161/hc4901.099409; exact image provenance is not confirmed.

## UMCG collection recovered directly — 25 October 2026

Official collection: https://sketchfab.com/eLearningUMCG/collections/congenital-heart-disease-2aeecf5115ab4d9abc49f0439c71db89 . Downloaded the individual USDZ files through the signed-in download interface; no archive recovery was needed.

- Normal Neonatal Heart: https://sketchfab.com/3d-models/normal-neonatal-heart-9c0dcc64acd74f0aaa9847736a9a87af
- Atrial Septal Defect (ASD): https://sketchfab.com/3d-models/atrial-septal-defect-asd-3398e00958054779a07554eaffc8b329
- Ventricular Septal Defect: https://sketchfab.com/3d-models/ventricular-septal-defect-e4e0143741f64025af101658210c8c5d

All three individual download pages specify E-learning UMCG, CC BY-NC-SA 4.0. Source USDZ geometry/materials retained; viewer translation, fitting and lighting only. Download hashes and mesh inspection: HeartAssets/external/umcg. These educational anatomy models are not a matched embryonic series and are not used as morph targets.

Additional atlas sources checked:
- https://hdbratlas.org/hikspoors-pdf.html — live index for 12 downloadable interactive PDFs, CS9–CS23, attributed to Hikspoors and Lamers/Maastricht. Seven HDBR GLB reconstructions are already installed by the project's existing reference pipeline (CS11, 12, 14, 16, 17, 18, 20). PDF availability does not imply compatible morph topology.
- https://www.3dembryoatlas.com/blank — live stage/PDF catalogue, with an approximately 84 MB archive link. Page states CC BY-NC-ND 4.0. Retained as a reference source; no adapted meshes from this collection have been bundled. Archive retrieval has not been verified in this increment.

Also downloaded: Transposition of the great arteries, E-learning UMCG, CC BY-NC-SA 4.0: https://sketchfab.com/3d-models/transposition-of-the-great-arteries-ee41d9d7c8854a98aa67feeeaf430584 . Original USDZ retained and inspected with the other three UMCG assets. Linked from the TGA guided lesson and selected directly when opening whole-heart anatomy from the TGA exploration model.

Also downloaded: Atrioventricular septal defect, 4 chamber view, E-learning UMCG, CC BY-NC-SA 4.0: https://sketchfab.com/3d-models/atrioventricular-septal-defect-4-chamber-view-d899d6e674054c3bb265f9cd687fd967 . Original USDZ retained. Available in the model collection and from the cushion lesson after its initial prediction, with access hidden again during unanswered retrieval.

Neonatal appearance adaptation: simulator inspection found the neonatal USDZ rendered uniformly white. Its archive contains only scene.usdc and no texture images. The initial adaptation applied a uniform rose tissue material with moderate roughness to that model. It is added teaching colour, not original tissue coloration; the current shared treatment is described below. Geometry and downloaded source remain unchanged. The adapted display is credited to E-learning UMCG under CC BY-NC-SA 4.0. Other models retain source materials, including the VSD's packaged textures.

ASD and four-chamber AVSD appearance adaptations: material inspection confirmed neutral untextured materials. These use the same uniform rose teaching material as neonatal anatomy. The current shared treatment is always active, with adaptation details retained in these references rather than an original-appearance option. Source files/geometry remain unchanged. The adaptations retain E-learning UMCG attribution and CC BY-NC-SA 4.0. VSD and TGA retain their source materials. Material-inspection evidence is stored with the download manifest.

## Shared runtime appearance — 25 October 2026

The shared live model style now applies the same studio lighting and surface finish to the eight developed-heart references, alongside the lesson and morph viewers. Non-textured PBR roughness/metallic values are harmonised; original colour/normal/roughness maps, transparency and source colour distinctions are retained. Uniform rose recolouring remains limited to the inspected, texture-free neonatal, ASD and four-chamber AVSD models. This supersedes the earlier statements that other references receive no material adjustments: their source colours and maps are preserved, while eligible scalar surface properties change in the shared presentation.

Downloaded USDZ files and geometry remain unchanged. All eight references now use the shared appearance on load, with no in-app original/source appearance toggle. This follows the user's request for one consistent presentation; source records and creator/adaptation credits remain retained separately. These runtime display adaptations retain the individual creator attributions and licences listed above, including CC BY-NC-SA 4.0 for the UMCG adaptations; they do not replace or relicense the source assets. The full presentation contract and its limits are in [MODEL_VISUAL_STYLE.md](</Users/phillicia/Desktop/School/Spatial/heart v3/Documentation/MODEL_VISUAL_STYLE.md>).

Regional-colour follow-up: untextured non-neutral source colours keep their hue and alpha, with saturation capped at 0.55 and brightness at 0.72 to fit the shared palette. Texture colours remain untouched. This applies to eligible developed-heart and HDBR materials; the birth-transition legend colours remain unchanged. These are additional runtime presentation adaptations, without changes to source files or geometry.

Textured-reference follow-up: developed-heart colour textures use a runtime tint ceiling (maximum RGB 0.65, proportional tint ratios, original alpha) to reduce brightness relative to the tissue palette. Source texture pixels, UVs and other maps are unchanged. This grading is not applied to the already-baked lesson textures.

## Developmental branch and outflow animation references — 25 October

- Buijtendijk, Barnett & van den Hoff (2020), Development of the human heart: https://onlinelibrary.wiley.com/doi/full/10.1002/ajmg.c.31778 . Supports distinguishing outflow cushion fusion/remodelling from ventricular alignment and later septal formation. The new procedural loft reuses this project's original regional outflow illustration; it is not a patient-derived morph or a measured rotation angle.
- CDC, AVSD: https://www.cdc.gov/heart-defects/about/atrioventricular-septal-defect.html . Central junction and AV valve differences, rather than a single isolated wall opening.
- CDC, d-TGA: https://www.cdc.gov/heart-defects/about/d-tga.html . Ventriculoarterial connections and parallel circulation. The outflow morph does not purport to simulate the cause of TGA.
- CDC, coarctation: https://www.cdc.gov/heart-defects/about/coarctation-of-the-aorta.html . Narrowed aorta and uncertainty in cause. The app separates the developmental context from the possible emergence of circulatory effects around ductal closure.

Timeline branch markers associate overlapping developmental processes with later anatomy. They do not assign exact dates of defect onset or imply that all anomalies result from one arrested animation frame.

Selected regional palette (direction B): explicit named tube/atlas regions are adapted to the application's muted teaching palette, with slightly lighter cardiac-jelly and endocardial layers. For these identified parts, runtime base colour replaces the source colour map/tint while normal and roughness detail remain. Original downloaded/baked files are unchanged. Other source regions retain their harmonised appearance; no anatomical labels are inferred from unnamed meshes. This supersedes source-colour retention statements for explicitly mapped regions only.

Regional coverage follow-through: chamber-wall and atlas export-name variants now use the same named-region adaptation. The unsegmented paired-tube teaching model adopts the morph's coral wall colour with lighter jelly/endocardial layers, without assigning future chamber identity. Neutral UMCG tissue now uses this coral family rather than the superseded deep rose. Source mesh files and all creator/licence records remain intact.

Guided workspace integration (26 October): the installed sources are now used as a second representation inside related lessons. Normal neonatal anatomy provides overall context for early stages and birth; the typical-heart source supports later chamber/outlet orientation; ASD, VSD, four-chamber AVSD, TGA, Fallot and coarctation examples are paired with the relevant developmental or anomaly lessons. Their source ages, geometry and representations differ: display fitting is not dimensional matching, and none is used as a morph endpoint. No additional model files were downloaded or adapted in this integration.

Presentation change — 26 October: the user requested removing in-app CC attribution rows and will place credits elsewhere. Source URLs, creators, licence terms, download records and adaptation details remain recorded here and with the original assets; model geometry and source files have not been changed by this UI removal.

## Original PDA reconstruction — 27 October

- Authoring base: this project's `HeartAssets/tools/build_batch08.py` (HeartV0/V3), with reauthored smooth tapered vessel meshes, continuous lumens and matched closed walls. No external patient mesh was altered to create a diagnosis.
- Anatomical/lesson reference, consulted 27 October 2026: [Merck Manual Professional, Patent Ductus Arteriosus](https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/patent-ductus-arteriosus-pda). Used for persistence of the normal fetal aorta–pulmonary artery connection after birth; closing is a gradual transition, and effects depend on the circulation. Not a basis for patient-specific dimensions.
- `HeartAssets/tools/build_pda_reference.py` builds both `.usdz` files and retains editable `.blend` projects under `HeartAssets/authored/pda`. The material grain is illustrative surface variation, not a microscopic tissue map. The closed model depicts a later anatomical endpoint, not immediate functional closure or treatment.
