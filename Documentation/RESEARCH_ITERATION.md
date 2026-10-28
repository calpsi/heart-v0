> Current scope: the 24 October development-first school brief supersedes clinical-review requirements in this earlier document. See DEVELOPMENT_REDESIGN.md.

# Research-informed iteration — 24 October 2026

## Phase 0: baseline audit and inventory

SwiftUI / RealityKit visionOS app. Scene ownership and transform paths are documented in IMPLEMENTATION_PLAN.md. No architectural replacement is required. Blender sources and Python build/install scripts in HeartAssets/tools produce USDZ resources and JSON catalogues/manifests. HDBR specimen reconstructions are installed separately, with provenance. Instructional cards currently live in GuidedLearningView; new pilot content will be separated from the renderer.

Verified before this iteration: **52 guided cards**, ten developmental lessons, six anomaly lessons, eight exploration timeline stops. The deck's 51-card count is stale. HeartModels.json has 16 teaching assets and **372 part entries**; HeartReferenceModels.json has seven reconstructions and 57 region entries. These entries include alternate anatomical states and tissue panels, not 429 unique biological structures. Guided looping and outflow use two of those source reconstructions instead of their schematic counterparts. Do not advertise 355 distinct structures.

Implemented: in-place 0.4–2.5× zoom, bounded gesture changes, scene-scoped transforms, model/view reset and Undo, separation tether, stable comparison envelope, compact toolbar, bounded captions, local coarctation attempts and optional delayed review. Prior verification: 23 assets, 13 unique UI tests across runs and portable policy tests. Headset acceptance remains outstanding; simulator results do not establish hand-tracking comfort or spatial ergonomics.

Partial: coarctation recognition and comparison exist, but the normal reference does not precede the first task. Guided explanation is predominantly passive. Exploration lacks optional investigations. Clinical transfer using unfamiliar independently reviewed images is blocked by missing approved assets and rubric. No educational efficacy results exist.

## Ordered implementation

1. Preserve tested P0 controls; rerun policy/build and changed-flow tests. No new spatial failure is confirmed by this brief.
2. Pilot cushion fusion with Observe / Predict / Reveal / Explain / Retrieve, using existing discrete states, matched orientation and optional response controls. Store checks separately from viewing.
3. Reorder coarctation into normal reference / blind localisation / matched comparison / qualified consequence / recognition again. Keep labels, comparison and narration out of blind tasks. Distinguish same-model practice from clinical transfer.
4. Add optional exploration investigations and retain local delayed review. Do not turn skipped checks into successful assessments.
5. Edit a copy of the located iCloud HEARTV0.pptx; preserve every title, order and NUS identity, qualify research and distinguish implemented/planned. Use actual footage only.
6. Test changed flows, document headset tasks and expert dependencies. Prepare formative evaluation protocol; participant recruitment and clinical sign-off cannot be supplied by code.

## Issue links

Spatial safeguards: HV3-001–007. Progressive lesson content: HV3-017/018/027/033/035. Blind assessment and feedback: HV3-023/024/031. Comparison and clinical boundaries: HV3-025/026/029/034. Investigations: HV3-028. Separate local evidence and review: HV3-032.

## Research verification

Bachler & Kaur (2026), https://link.springer.com/article/10.1007/s40670-026-02743-2 : preliminary needs analysis n=67 at one US medical school, difficulty 6.4/10, additional-resource agreement 77.7%, quiz agreement 81%. Self-report needs, not proof of spatial learning efficacy.
Trumble et al. (2024), https://link.springer.com/article/10.1007/s10459-023-10274-3 : review of distributed/retrieval practice; does not establish optimal intervals for this app.
Reddit links supplied in brief were read as exploratory accounts, not representative statistics. Coarctation review: https://pmc.ncbi.nlm.nih.gov/articles/PMC10340190/ (publisher: https://www.mdpi.com/2075-4418/13/13/2189). Multiple proposed mechanisms; no universal causal animation is warranted.

## Implementation outcome

The two pilot sequences each have five beats: **55 total guided cards** after this iteration. Optional cushion prediction/recall and coarctation attempts remain independent of views. Comparison is withheld during initial observation/prediction; scene scale and orientation remain matched when later comparisons become available. Stage-specific exploration prompts are dismissible. Foundation content and assessment rules live in HeartLearningPilot.swift; the RealityKit renderer retains the existing architecture.

Verification: six unique targeted UI checks passed (eight passes across initial/final runs), 20,000 resize policy samples and assessment/scheduling checks passed, and final live validation passed all 16 teaching and seven reference assets, including the saved-step migration assertion. Evidence is in verification/research-pilot-*. No real-headset or clinical validation is claimed.

Remaining dependencies: headset posture/hand-tracking/voice acceptance; educator review of pilot content and answer rationales; an approved unfamiliar clinical representation and transfer rubric; recruitment and completion of the formative evaluation. Optional review intervals remain 1/3/7 days; the brief's 1/7/21 example is not an evidence-based requirement.

Presentation scope clarification: the user will make the videos. Deliver a new deck with editable footage spaces and overlay/narration guidance. Do not modify the active deck or deliver generated slide videos. Preserve the original empty reflection area on slide 9 and blank slide 10 rather than inventing personal experience or a new title.
