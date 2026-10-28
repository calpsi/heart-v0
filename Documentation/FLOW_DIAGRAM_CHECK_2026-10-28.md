# App flow comparison — 28 October 2026

Reference: the user's attached flow diagram (`codex-clipboard-a09c97dc-dc65-4faf-8f49-420551df1195.png`). This is a read-only flow audit alongside model/animation work. UI, navigation, lesson wording, scientific claims and source assets have not been changed in this pass.

## Free Exploration

| Diagram requirement | Current implementation | Assessment |
|---|---|---|
| Enter directly into a heart 3D model | ContentView → FreeExplorationView, normally paired-tube development with a live morph. | Present. |
| Slider through developmental stages | Shared bottom timeline, eight named anchors, previous/next stage and a stage chooser. | Present. |
| Animated transitions between stages | Continuous joining/looping at timeline 1–3 and outflow division at 5–6. Other intervals select static teaching/atlas models. Specimen changes fade between sources. | Partial: not one continuous morph across all eight stages. A source fade is not developmental deformation. |
| Brief description / narration | Morph title and observation sentence, stage heading, model/location info and optional investigation. Spoken explanation is provided in Guided Learning, not a consistent free-timeline narration track. | Brief text present; narration incomplete relative to the diagram. |
| Each portion selectable | Static models provide entity/Parts selection, isolation, separation and bounded movement. Specimens expose their source groups. Morphs offer selectable tissue layers through controls, not individually tappable anatomical regions. | Partial; available segmentation differs by representation. |
| Guide text for selected part at selected stage | Static selection updates a part label. Model/location information and guided phase descriptions supply context, but HeartAsset.Part has no per-stage explanatory-body field. | Gap: a selected label is not the contextual explanation shown in the diagram. |

## Guided Learning

| Diagram requirement | Current implementation | Assessment |
|---|---|---|
| Timeline tabs through normal development | Ordered developmental lesson catalogue, then local phase tabs, with next-process actions for the available morph sequences. | Partial: sequence exists, but there is no single global developmental timeline strip throughout Guided Learning. |
| Stage 3D model and detailed description | Shared static/specimen/morph viewers with guided observations, narration, interaction prompts and explanations. | Present. |
| Irregularity options attached to normal development | Process-specific branches in septation, cushion, outflow and birth-transition lessons. Free timeline also carries contextual branches. | Present for the authored connections. |
| Where malformation forms versus expected anatomy | Branch panel shows a developmental process window, normal-process text and typical/altered model comparison. Explanations are revealed on request. | Partial: process context and comparisons are present; these do not animate a failure forming within the embryonic geometry. Most comparisons are different specimens. |
| Effect on the child | Brief “Why does it matter?” text and existing guided explanations. | Present at a brief conceptual level, not the detailed consequence sequence depicted. |
| Explanation/video of correction | No treatment or correction sequence; existing anatomical comparisons explicitly do not represent surgery. | Missing. “Video?” in the diagram is a proposal, not an implemented feature or instruction to generate a video. |

## Flow safeguards already in code

- Returning from a branch retains the free timeline position; changing stages closes the branch.
- Guided and free modes use the same morph/viewer components, palette and tissue finish.
- Knowledge-check and branch explanations remain concealed until the appropriate learner action.
- Anomalies remain available separately as well as through contextual links.
- Normal-outflow replay returns to the same learning context rather than sending the learner into the other mode.

Relevant sources: ContentView.swift, FreeExplorationView.swift, GuidedLearningView.swift, DevelopmentConnectionView.swift, HeartDevelopmentConnections.swift, HeartModelView.swift and HeartLoopingMorphView.swift. Runtime tests for representative normal-process → anomaly → return paths are recorded in TESTING.md after this pass.

## Conclusion

The two main routes and their development-to-anomaly links match the intended direction. The diagram is not fully implemented: continuous morph coverage, contextual selected-part explanations, a global guided timeline, failure-formation animations and correction content remain gaps. No navigation or educational-content changes are made under the current model/animation-only instruction.

## Runtime confirmation in this pass

The updated model build passes the free timeline's forward/reverse morph and reset sequence, the process → typical/altered comparison → explanation → same-timeline return sequence, and the complete predict → observe → explain → related anatomy → return sequence in **both** free and guided modes. The latter checks that the anomaly explanation remains concealed until requested and that the learning response survives returning to the animation. These are representative tested routes, not proof that every node in the diagram is implemented. Logs: `verification/model-motion-oct28/ui.txt`.
