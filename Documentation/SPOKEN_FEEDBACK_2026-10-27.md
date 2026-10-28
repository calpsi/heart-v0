# HeartV0 — spoken feedback and older-version comparison

Recording: `/Users/phillicia/Downloads/RPReplay_Final1793038876.MP4`.
Audio duration: 202.112 seconds. Audio was decoded and transcribed locally with faster-whisper small.en; the recording was not uploaded. The initial automatic transcript merged long pauses, so shorter overlapping windows were transcribed again. These are automatic transcripts, not verbatim-certified quotations. Source evidence: `verification/retest-oct27/spoken-feedback-transcript.json` and `spoken-feedback-chunks.txt`.

## Clear requests and response

| Approximate elapsed time | Spoken request, paraphrased | Implementation / verification |
|---|---|---|
| 0:10–0:19; 0:23–0:48 | Minimum window size; scale evenly instead of moving UI around; elements are cut off | A common 1100×780 minimum is now applied to home and both modes. Playback controls are compacted; a containment regression covers joining, looping and outflow. Proportional physical window scaling and headset placement remain device checks. |
| 2:01–2:06 | The separation in this view is acceptable | Frame 2:00 shows the earlier cardiogenic teaching view, with parts kept around the same model. Preserved its established scene/part code and used its local-offset principle as a reference for the morph and known enclosing specimen shell. |
| 2:13–2:24 | Cutaway does not make the sections understandable | Frame 2:20 shows the detailed primitive-tube lesson. The animation-first route now starts from its straight tube. Separately confirmed that the procedural tube's opening faced sideways: moved that inspection opening towards the default viewer while keeping its posterior reference wall fixed. Labels still distinguish the three illustrative layers. The static-source shape is not silently replaced on this evidence alone. |
| 2:30–2:50 | Reference anatomy should use consistent controls and separation | The same specimen viewer serves both modes. The known typical-heart blood pool stays centred while its myocardial shell lifts locally. Unidentified source groups retain honest generic labels; no anatomy is inferred from source-object numbers. |
| 2:55–3:03 | Cross-section should be presented directly, not just in a dropdown | Added Cross-section / Close section buttons with visible Depth / Width / Height choices once open. The existing surface-preserving section engine is retained. |

Ambiguous phrases in the first long transcript, including its final word, are not used as requirements. The shorter-window transcription resolves the final request as presentation of the cross-section controls.

## Older versions inspected

User clarified on 27 October that “older models” means previous HeartV3/HeartV0 versions. Those are the implementation reference. V1/V2 were inspected initially but are excluded from the design comparison.

- Git commit `19ba238` (`hv0`), `heart v3/HeartModelView.swift`: useful real-part behaviour. Parts are placed from saved rest positions plus local separation/manual offsets; front/back wall panels move locally in depth. Reassembly returns to the saved geometry.
- Existing layered source builders retain adjoining wall interfaces and authored geometry. The live morph now keeps the endocardial reference centred and lifts the surrounding shells nearby, instead of placing three whole shells side by side. This is an inspection arrangement, not a developmental event.

## Rendering and interaction work

Shared studio ambient strength is reduced and a low-intensity rim light added; palette assignments and source textures are preserved. The experimental selection-first drag was withdrawn in the evening visibility recovery: its rendered input proxy obscured the morph. Directional movement retains the selected-layer and bounded-offset behaviour. Nearer/Farther controls remain for depth. This is selection-first manipulation, not per-triangle gaze picking.

See TESTING.md for actual test and visual-review results. These changes do not complete all developmental morph intervals or establish anatomical/clinical validation.
