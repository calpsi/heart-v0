# Early tube layer animation references

The animated tube now adapts the existing project’s named early-tube layers. These are teaching meshes, not segmented microscopy or a measured growth simulation.

## Implementation provenance

- `HeartAssets/tools/build_batch01.py`: paired-tube myocardium, cardiac jelly and endocardial lining.
- `HeartAssets/tools/build_batch02.py`: straight/looped teaching-tube layer radii: myocardium 0.78–1.0, cardiac jelly 0.61–0.78, endocardium 0.54–0.61 of outer radius. The animation uses this one set throughout joining and looping to avoid a thickness jump. These proportions are exaggerated teaching choices, not measurements.
- `HeartModelStyle` and `HeartAnatomyRegion`: existing muted regional palette; the named layer lightness differences are shared by the static assets and animated layers. No additional cellular or fibre texture was invented.

## Scientific context consulted, 26 October 2026

- Del Monte-Nieto et al., *Control of cardiac jelly dynamics by NOTCH1 and NRG1 defines the building plan for trabeculation*, Nature (2018). Primary experimental research; https://www.nature.com/articles/s41586-018-0110-6 . Supports the importance of changing endocardium–myocardium/ECM relationships and the need not to generalise concentric early-tube layers to later chamber walls. This implementation does not model those signalling mechanisms or trabeculation.
- *Development of the human heart* (2020), https://pmc.ncbi.nlm.nih.gov/articles/PMC7078965/ . Context reference for the early myocardial/endocardial organisation and later regional remodelling.
- Männer and Yelbuz, *Functional Morphology of the Cardiac Jelly in the Tubular Heart of Vertebrate Embryos* (2019), https://pmc.ncbi.nlm.nih.gov/articles/PMC6463132/ . Review context for the extracellular matrix between the two cell layers.

## Scope

The three shells illustrate layer order in the early tube. Circular cross-sections, wall thickness, convergence and separation are schematic. Separation is an inspection arrangement; it is not delamination, a congenital defect or growth. No epicardial shell is added to the early tube. No new layers are added to imported UMCG/3D Heart Project specimens or HDBR reconstructions. This pass does not simulate regional cardiac-jelly remodelling, trabeculation, chamber ballooning, cellular fusion or later tissue stacks.
