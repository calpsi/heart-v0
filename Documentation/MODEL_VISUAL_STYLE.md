# Shared live anatomy style

25 October 2026. The user selected **B — muted colours distinguishing anatomical regions**. This is the current presentation contract for the school prototype. It supersedes the earlier uniform deep-rose direction and the removed original-appearance switch.

## Coverage

| Model family | Coverage | Shared viewer |
|---|---:|---|
| Educational illustrations | 16 models: 10 normal, 6 anomaly | HeartModelView |
| HDBR reconstructions | 7 Carnegie-stage models | HeartModelView |
| Developed-heart references | 8 UMCG / 3D Heart Project models | HeartProjectView |
| Continuous illustrations | Paired-tube joining, looping, regional outflow division | HeartLoopingMorphView |

Guided Learning and Free Exploration use the same viewers, material rules and lighting. A common finish does not make different specimens a matched developmental series.

## Regional palette

HeartAnatomyPalette.swift defines six teaching colours: blue-grey venous inflow, lavender atrial region, gold AV junction/cushions, coral ventricular region, sage bulbus region and terracotta arterial outflow. These identify regions, not oxygen levels or cell lineages. Outflow cushions use the gold tissue colour with an explicit **Outflow cushions** legend; this does not label them as AV cushions.

Looping face assignments remain fixed as the surface bends. Boundaries follow the existing segmented teaching illustration, not measured embryonic borders. Unsegmented paired-tube walls use coral without assigning them to a future ventricular region. Their detailed model and morph share that wall colour. Cardiac jelly and endocardial layers use lighter variations to preserve their distinction.

Detailed teaching models and HDBR reconstructions adopt the palette where explicit part names identify the anatomy. The lookup covers chamber-wall names and atlas export variants such as left_vent, right_atrium2, sinus_venosus, vena_cava and oft_sm_dec. It intentionally replaces the runtime base-colour texture/tint for mapped parts while preserving normal/roughness detail. Unknown, external-context and unsegmented source parts retain their harmonised source appearance. No anatomical boundaries are inferred from geometry or colour alone.

The four inspected, texture-free UMCG sources (neonatal, ASD, four-chamber AVSD, TGA) use coral tissue shading. Other developed-heart references retain their authored regional distinctions and colour textures. Their segmentation is not sufficient to promise the same six named regions everywhere. Their common finish and lighting reduce visual differences without inventing anatomical labels.

## Lighting and material rules

HeartModelStyle.swift owns the common rendering setup:

- Cached HeartTissueStudio environment, intensity exponent -0.6, with a low-intensity 300 rim light.
- Fixed shadow-casting TissueKeyLight, intensity 1100, outside the rotating anatomy. Reinstalling does not stack lights.
- Roughness 0.48 and metallic 0 for new tissue and imported scalar-only channels. Authored roughness/metallic maps and their multipliers remain intact.
- Unmapped, untextured regional colours preserve hue/alpha, with saturation capped at 0.55 and brightness at 0.72. Neutral greys and dark tones remain unchanged.
- Developed-reference colour textures receive bounded tint modulation (maximum RGB component 0.65). Source pixels, UVs and texture resources are unchanged; repeated styling does not progressively darken them.
- Unknown shaders pass through. Source alpha, blending, culling and surface-detail maps are retained by the style helper. The lesson viewer separately applies its existing opaque tissue/selection treatment. Morph cutaways render both wall sides.

Existing birth-transition keys remain yellow for the foramen flap, purple for the ductus, grey for lungs, orange for aorta and blue for pulmonary artery. Selection highlights and annotation guides remain distinguishable. These presentation keys are not oxygen-level coding.

## Source records and limits

There is one in-app appearance, with no original/source switch. Adaptation notes and creator credits are retained in MODEL_REFERENCE_LIST.md and the references. Downloaded files and source geometry are unchanged.

Live styling does not reshape specimens, equate their proportions, or create corresponding morph targets. Continuous geometry covers timeline intervals 1–3 and 5–6 (zero-based); other stages and connecting intervals remain discrete. Home illustrations and raster thumbnails are unchanged. Headset readability, perceived consistency across every specimen and the full eight-stage morph remain outstanding.

TESTING.md records actual verification. The catalogue regression checks installed live-scene colours as well as material preservation, selection, separation and reassembly. Numerical checks and screenshots are not evidence of anatomical fidelity or educational efficacy.

### Morph boundary continuity

After the unsegmented tubes join, the six teaching colours ease into view over the first 18% of looping; the legend swatches use the same interpolation. This avoids an instantaneous palette change at the shared endpoint. The colour reveal is a teaching overlay, not a depiction of tissue differentiation or lineage.

Guided integration: HeartGuidedSpecimenView embeds the same HeartProjectViewport used by the reference viewer. It inherits material treatment, fixed lighting, fitting and bounded zoom. There is no separate guided-only appearance. A lesson-scoped selector limits the examples to its normal and related anatomy instead of exposing unrelated models during a lesson.

### Mode parity and separate credits — 26 October

Heart anatomy is now a subsection of both Guided Learning and Free Exploration. Both embed the same collection, default model and rendering component; guided lesson specimens use that same viewport/scene. No mode-specific texture, colour, lighting or morph implementation is introduced. Different source models retain meaningful differences in geometry and unsegmented texture detail, but the same source is styled identically whichever mode opens it.

At the user's request, CC/creator rows are removed from the in-app model and atlas views. Source metadata and adaptation/licence records remain in MODEL_REFERENCE_LIST.md and the downloaded asset folders for separate presentation credits. This supersedes earlier statements about visible attribution rows.

### Section and separation presentation — 26 October

Geometric sections reuse each source's positions, normals, UVs and material indices. They are uncapped surface cuts; they do not add or recolour inferred tissue layers. Whole-model restoration reinstates the exact original mesh resource. Later-anatomy specimens use the same section cache and part controls in both modes. Separation is applied in a common coordinate space so different import scales do not change its visible amount; source groups receive distinct inspection positions and can be reassembled exactly. See MODEL_CAPABILITIES.md for segmentation and layer limits.

### Animated layer inspection

Early-tube isolation filters existing GPU draw parts rather than replacing the tissue with a highlight colour or transparent duplicate. The same regional hues and layer lightness remain visible during isolation, movement and reassembly in either mode. HeartMorphAppearance retains the material set until the early-looping colour reveal changes, avoiding repeated material construction during inspection. The live morphs now share repeatable grain and roughness maps, mapped along their own surfaces rather than using a static baked atlas. The restrained variation follows the older V0 tissue authoring approach; it is not measured histology. Surface coordinates follow bending and rigid layer movement. The static teaching assets still contain more authored detail.

### Evening visibility recovery

The viewport-sized rendered input proxy was removed after the user recording showed it as an opaque black rectangle. The app now uses a white workspace with light panels. Direct layer dragging is withdrawn until independently verified; directional movement remains. Both anomaly browsers use the same imported specimens where available. PDA remains an existing teaching illustration, and coarctation recognition retains its protected schematic task.

Authored PDA pair: muted warm aortic wall, teal pulmonary wall and coral duct; subdued fibrous remnant. Uses the morph's grain source and its 0.48 roughness multiplier, baked for USD portability. The default oblique view exposes the ductal relationship; each part remains independently movable. VSD's untextured neutral surfaces now take the common coral tissue tint; its source texture maps remain intact.
