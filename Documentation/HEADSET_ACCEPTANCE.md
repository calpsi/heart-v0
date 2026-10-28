# Manual acceptance — outstanding

Record build identifier, headset/OS, seated/standing posture, environment, timestamped video and observed result. No box below is pre-passed by simulator tests.

- [ ] HV3-001/005: Paired heart tubes → at least 20 pinch/rotate repetitions. Interrupt tracking, re-enter hands, change assets, isolate, repeat. No scale spike, accidental selection on release or unsolicited close-up. Slider and pinch stay within limits. Check small and large models.
- [ ] HV3-002/006/019: move the OS window near/far and change environment. At 0.4×, 1× and 2.5×, controls and the fixed label footer stay readable/reachable. Reset model returns a coherent whole. Inspect magnified geometry for control overlap and clipping. This patch does not reposition OS windows or guarantee distance from the user's eyes.
- [ ] HV3-003/021: Separate and Move parts. Identify the origin of a selected displaced part using the white dot/line; reassemble once. Check that the line is not confused with anatomy or flow. A line is an inspection aid, not a biological connection.
- [ ] HV3-004/022: rotate → resize → separate → Undo. Only the last supported manipulation reverses. Reset view changes angle/size; Reset model restores assembled current anatomy; Restore step also restores the lesson's intended anatomical state. Repeated reset is identical.
- [ ] HV3-007/015/017: confirm no Close-up action/window exists; resize then visit the catalogue/home; advance a lesson and open another model; open/close details repeatedly; invoke launcher and return. No previous anatomy remains. Collect logs before claiming a crash or leak.
- [ ] HV3-009/010/011/020: inspect controls/text in bright and dark passthrough/immersive environments, both hands and large text. Identify orientation after arbitrary rotation. Reference anatomical axes remain withheld pending source verification.
- [ ] HV3-023/024/031: enter coarctation step 1. No selected-answer highlight, location label, answer narration, part list or comparison before response/reveal. Try a branch, the connecting remnant, then the correct region; test hint, reveal and retry. Confidence and assistance persist separately. Skip does not create a correct answer.
- [ ] HV3-025/026/027/032/034: educator approves selectable region boundaries and feedback; supplies licensed unseen representation, mechanism explanation and scoring criteria. Run immediate and delayed recognition measures before claiming clinical transfer or retention.

Original review evidence intervals: B 00:24–00:36; A 03:00–03:20; A 03:40–03:55; A 06:30–06:40. Do not label a ticket Fixed until its relevant manual acceptance and regression evidence exist.

Follow-up UI checks: confirm the two-column toolbar does not shift when Return part becomes available; open View and drag both pinned sliders; verify Done remains visible; show/dismiss narration and confirm the original model view returns. At 2.5×, cropped anatomy is expected: Reset view restores the overview. Check that cropping is not mistaken for an anatomical defect and that labels/navigation remain legible from oblique viewing angles.

Additional acceptance for the remaining implementation pass: verify matched normal/abnormal framing at several rotations and zoom levels; distinguish Listen from model motion; compare the installed narration voice and pronunciation on the headset; open Explanation and Sources without losing the current model; enter review practice from the catalogue and confirm no answer cues appear. Review reminders are local to the catalogue, not notifications.

## Research pilot acceptance — 24 October

- Cushion fusion: Observe must show only the initial state; no Compare control before Reveal. Predict hides the explanation until an answer or explicit reveal. Choose an incorrect answer, read the explanation, go back and forward, and complete Recall or skip it. Verify that no action is needed to continue exploring.
- Coarctation: Normal Reference precedes the first blind task. Normal Reference cannot toggle directly into the abnormal state. The identification steps hide labels, model details and comparison until a correct response or reveal. Repeat after visiting the explanation and returning; label concealment must reset. Verify every region can be selected without a conspicuous target hotspot.
- Compare anatomical states after arbitrary rotation and zoom. Corresponding branches and cushions should remain in the same position and at the same scale.
- Recognise Again: deliberately rotate to another view before responding. Confirm this is described as same-model practice, with no clinical-transfer score.
- Investigate in exploration: open and dismiss the optional prompt, change stages, reopen it. Verify text fits, controls remain reachable and the model returns after dismissal without losing orientation.
- Resume an older saved lesson after upgrading: cushion steps map to their equivalent later beats; coarctation resumes the matching study content. Completion state and other lessons remain intact.
- Narration: test installed voice quality and pronunciation on the headset; choosing the best available installed voice cannot guarantee natural speech on every device.

## HeartV0 deadline acceptance — 27 October core route

Use the ordinary window size in both passthrough and the bright environment from the recording. These are pending headset checks, not simulator results.

1. Home → Guided Learning → Paired heart tubes. The former Follow development in 3D shortcut was removed at the user’s request. Play joining to its endpoint, scrub backwards, then use Next animation for looping and outflow. Watch whether the wall stays coherent and the observation prompt matches the current shape. Check that the model and controls remain together during resize/rotation.
2. In outflow, open/close the wall, separate/reassemble components, and use Where can this process differ? Inspect related versus typical anatomy; Explain the connection should be visible without scrolling. Reveal the explanation and return to normal development. The source specimens are comparisons, not matched morph targets.
3. In Free Exploration, scrub within joining/looping and outflow, open a related anomaly, and return. The timeline should remain visible and retain its position. Moving to another stage must close the previous anomaly branch.
4. Enter TGA from the lesson catalogue, replay normal outflow division, and return to related anatomy. Confirm the replay is explicitly labelled normal development. Compare the TGA surface finish between this view and the Heart anatomy subsection.
5. Return Home and reopen a different lesson. Check for leftover models, oversized parts, controls behind geometry, hard-to-read text, or a running animation that should have stopped.

Outstanding content: full-timeline transitions, animated chamber/AV-junction partitioning, and correspondence between developmental illustrations and later specimens. This acceptance run does not establish anatomical accuracy or durable learning.

## Evening visibility recovery

Confirm joining, looping and outflow render without a black rectangle in both modes, including after opening size/layer controls and returning. The background should be white. Confirm VSD, ASD, Fallot, TGA and coarctation in Free Anomalies open the imported specimens; guided ASD/VSD should start on their altered specimens. PDA remains a teaching illustration. Direct layer drag was withdrawn after the failed experiment; use directional movement, isolation and reassembly. The existing coarctation blind recognition still uses its gated teaching model.

### Authored PDA follow-up

- In Free Exploration → Anomalies → PDA and Guided Learning → PDA, verify that the initial oblique view makes the short duct visible between the pulmonary arterial region and descending aorta. Rotate without losing orientation, then Reset view.
- Compare Patent ductus and Closed remnant. The view angle and geometric cut direction should remain stable. Inspect the actual channel and closed walls; the fade is a representation switch, not a physiological closure animation.
- Open all three cut directions; move the duct/ligament and each artery; confirm dark origin tethers remain readable on white. Reassemble and Restore model must recover the assembled region.
- Open the birth-transition connection, reveal the explanation, and return without advancing the lesson. Recognise that fetal ductal patency is normal and persistence after birth is the issue.

### 22:48 recording repairs / 28 October

- Guided catalogue: Development/Anomalies/Heart anatomy labels remain readable; titles wrap in full and cards scroll without a clipped trailing column.
- Cardiogenic lesson: dark heading/body on a solid reading panel; Slice stays on one line; open/close the section and verify no anatomy crosses text or control rows.
- Heart anatomy: Choose model exposes full labels; selection returns to a readable current title. Size shows a numeric multiplier and actually changes scale. Model info is readable and does not allow the underlying model to obstruct it.
- Joining/looping/outflow: main stage has clear space above/below; Play is the primary action. Information is available via the info control. Repeat separation, pinch, resize the window and restore.
- Test bright passthrough, a darker environment, Increase Contrast, Reduce Transparency and large Dynamic Type. Solid surfaces address transparency, but AX3 layout and physical gaze/pinch target usability are not yet verified.

- After the viewport-depth correction, compare a static cardiogenic lesson, a realistic specimen and a live morph at 0.4×, 1× and 2.5×. Rotate, separate and reassemble; verify the nearest surfaces remain reachable and the white backing never hides anatomy. Check from an oblique head position as well as straight on. At default size, the model should not touch its caption. The depth cap may limit effective magnification for bulky separated anatomy.
