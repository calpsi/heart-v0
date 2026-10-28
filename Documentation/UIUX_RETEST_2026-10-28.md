# HeartV0 recording repair — 28 October

Inputs: `~/Downloads/HeartV0_UIUX_Critique_and_Fix_Prompts.md` and `ScreenRecording_10-27-2026 22-48-06_1.MP4`. Reviewed extracted stills at 20, 100, 175 and 225 seconds; the original duration and additional frames are retained in `verification/retest-oct28`. This pass does not claim to have transcribed audio.

The document is critique and proposed prompts, not blanket authorization to rename the product, replace its learning modes, recolour anatomy as oxygenation, invent date ranges or commit the user's existing work. Earlier user decisions remain: HeartV0, white workspace, palette B, guided/free modes, source references kept separately and no clinical handoff.

## Confirmed causes and changes

| Review issue | Code-backed cause | Change |
|---|---|---|
| 1, 6, 15: white labels / faded panels | `glassBackgroundEffect` applied after opaque light backplates; glass foreground vibrancy remained white. Native specimen picker also had unreadable selected text. | Shared solid reading-panel modifier, explicit text token, opaque controls. No new glass nested over reading panels. |
| 2: microtext | Caption/caption2 throughout inspection and learning; tiny persistent scope notes. | Caption→subheadline, caption2→footnote; no explicit text size below 14. Morph notes/region key moved to existing animation-info panel, with 14-point legend dots and two columns. |
| 3: model near control rows | Model stage was squeezed between scope/legend/layer notes and toolbar. | Removed persistent fine print and added stage padding/minimum height. This does not prove 3D clipping or headset containment at every zoom. |
| 4: broken Section label | Standard horizontal Menu label in a narrow two-column tool grid. | Vertical Slice icon/label with single-line text and a minimum 82×68 target; widened palette to 204. |
| 4: mystery pink bar | Bound to `zoom` in `HeartProjectView`, not rotation or decoration. | Shared visible Size label, current × value and labelled slider in all specimen viewers. |
| 5, 6: undifferentiated pills | Native tint inherited on default controls, no shared hierarchy. | Contrast-tested dark rose accent; neutral secondary controls, filled Play primary, outlined selected chips. Four reusable styles added; migration is incremental, not claimed complete. |
| 8: repeated timeline label | A hard-coded Days 21–28 string replaced `currentStage` in morph intervals. Only one interactive timeline slider already existed there. | Centralized the eight existing anchors; header/timeline share stage identity. Removed “Timeline below” and permanent interval footnotes. Local percentage retained for existing practice feedback; continuous global playback remains future work. |
| 11: truncated model choices | Ten models placed in one native segmented row. | Current full title + Choose model popover with adaptive grid. Model note moved to Model info. |
| 11: lesson title clipping | Large thumbnail + title constrained inside fixed-height card. | Smaller artwork, wrapping headline without line limit, content-driven card height; in-app chevron. |

## Implementation order / scope

1. Contrast tokens and backing repair, keeping anatomy and learning state intact.
2. Tool labels, model chooser, explicit size control, note relocation and shared timeline labels.
3. Build, portable contrast/stage/model policies, minimum-window containment and both-mode interaction tests; inspect screenshots.
4. Record remaining work, do not mark the entire critique implemented.

Deferred: a full ornament/navigation redesign; exactly five controls everywhere; globally continuous playback through currently unmorphed intervals; prediction-radio/submit redesign; complete reset/undo consolidation; loader prefetch/cancellation; full AX3/VoiceOver audit and headset acceptance. No fabricated biological date ranges or oxygenation-based recolouring were introduced. The existing two modes and recovery operations are preserved.

## Visual changes by component

| Component | Before | After |
|---|---|---|
| Reading panels / guided catalogue | White text on glass over light panels | Solid light panel, dark text |
| Mode chips | Pink selected fill | Subtle rose fill plus accent outline, dark label |
| Morph Play | Same pill as utilities | Dark accent primary with white text |
| Default utilities | Tinted system pills | Neutral outlined secondary |
| Tool Slice | Wrapped horizontal menu label | Single-line caption under icon |
| Specimen picker | Truncated segmented strip | Full model title and grid chooser |
| Specimen size | Unlabelled bar | Size + slider + numeric multiplier |
| Morph notes | Permanent small rows | Existing info popover |

Typography audit is source-level only: inherited fonts and Dynamic Type mean static source inspection cannot truthfully list each Text's resolved point size. Runtime accessibility and largest-size verification remain separate acceptance work.

## Continued placement repair

Full-window inspection found a second, confirmed issue after the contrast repair: the static cardiogenic model touched its caption. A temporary viewport border and runtime bounds probe isolated an inherited 540-point (~0.397 m) depth in `GeometryReader3D`. The border itself projected outside the intended 2D stage. Changing RealityView alignment alone did not fix this. Constraining layout depth to zero aligned the stage, but exposed another incorrect assumption: the old negative-z mesh placement put anatomy behind the new opaque white backing.

`HeartViewportLayout.swift` now gives all three renderers a common zero-depth layout plane. Their real meshes sit in front of the backing with a 2 mm gap and a maximum 0.50 m depth envelope, inside a 0.60 m front window margin. This applies to teaching models, source specimens and live morphs in both modes. Fitting measures the original source surfaces for cuts, so opening a section does not itself change the fitting envelope. Meshes retain their existing shape, colour, tissue finish, rotation and part controls. Maximum requested zoom remains 2.5×, with a physical depth cap for bulky or separated geometry.

Removed the redundant full-width progress bar and percentage above guided lessons. The same phase count and phase buttons now share one row, preserving phase navigation and answer-concealment labels. Selected phase chips use the shared outline style and 60-point targets. Hide lesson uses the neutral utility style.

The new UI regression checks actual viewport/caption frames after phase changes, hiding/showing the lesson, resetting and reopening. Runtime geometry assertions now test anatomy against the actual opaque backing/front-depth envelope; the previous local negative-z assertion was not proof that models stayed behind the visible controls. Full-window screenshots remain essential for visual acceptance. Apple reference: [RealityView layout behavior](https://developer.apple.com/documentation/realitykit/controlling-the-layout-behavior-of-a-realityview).

Validation maintenance: the full asset audit still expected eight specimen files and fifteen guided studies, predating the authored PDA pair. Coverage assertions now use the complete bundled model and lesson inventories, while still validating every mapped file and interaction. The debug-only static-model preview presets now run after model readiness; applying them in onAppear let initial lesson restoration silently overwrite the requested zoom/separation. Preview screenshots must show the requested multiplier before being used as evidence.

Follow-up limitation: default framing improved, but the 2.5× screenshot still shows anatomy projecting across the caption despite `.clipped()`. The physical depth cap is not a screen-space containment guarantee. A portal experiment was withdrawn after inconclusive direct-input testing; subsequent Build 2 UI changes and open issues are tracked in BUILD2_RETEST_2026-10-28.md.
