# Build 2 recording follow-up — 28 October 2026

Inputs: `~/Downloads/HeartV0_UI_Audit_Build2.md` and the 231.516-second `ScreenRecording_10-28-2026 02-31-12_1.MP4`. Local AVFoundation extraction retained frames at 5, 35, 60, 110, 155 and 195 seconds in `verification/retest-build2`. Inspected the 35/60/155-second views directly. This is a visual review, not an audio transcription.

The audit's embedded implementation prompts are proposals. Its request to commit after each step is not treated as authorization to commit the pre-existing work. Existing user decisions remain: HeartV0, both learning modes, a white workspace, muted anatomical region colours, no clinical-review handoff.

## Confirmed causes and implemented changes

| Build 2 issue | Evidence / cause | This pass |
|---|---|---|
| 1–2: dark labels on pink, inconsistent peer buttons | Native `.bordered` styles remained in five views; visionOS supplied accent fills. Listen/Next/Commit had explicit dark foreground overrides. | Replaced every remaining native bordered/prominent style with shared Secondary/Primary. Primary labels inherit white; utility peers use neutral fill/dark labels. Narration uses Primary. Per-control migration is in `verification/retest-build2/button-migration.md`. |
| 3: hover versus selection | Mode/representation choices used the same pink outline as tool chips. | Shared choice picker now has inset white selection, neutral outline and a persistent accent underline. Guided phases share the same selection treatment. Tool chips remain distinct. Gaze uses native highlight, without a custom hover colour. |
| 4: nested containers | Free header had a title panel and two wrappers around its mode track; morph toolbar/caption each added another grey bar. | Removed those wrappers and bars. Existing tool/timeline surfaces remain; this is not a claim of complete surface simplification. |
| 6: “Cr” | Source and frame show the rotating orientation cue, not a clipped tool name. | Retained anatomically meaningful axis abbreviations and added visible “Orientation”, help explaining Cr/V/L/A, and existing complete accessibility description. |
| 7.2: home affordances | Glossy artwork plus title and two card images made the home hierarchy inconsistent with the workspace. | Home mode cards use 72-point hierarchical SF Symbols, a visible neutral outline, consistent 320×260 footprint and centred References action. Descriptions remain complete, rather than being clipped to one line. |
| 9: vanishing disabled controls | Shared styles applied 40% opacity to an already pale fill and label. | Disabled controls retain a neutral shape and readable grey label; no accent, no hover, and SwiftUI disabled semantics remain. Contrast test includes disabled text against control fill. |
| 10: dark info popovers | A light parent did not explicitly set presentation surfaces. | Investigation, narration, model info/location, size, layers, parts and specimen chooser/info popovers now explicitly request an opaque white presentation surface and shared text/button tokens. |

Accent remains **#D6336C**; white contrast already passes 4.5:1. No anatomy material or region identity was changed to match the UI. No new oxygenation meaning was assigned.

## Remaining work / limitations

- Build 2 issue 8: full on-screen model fitting and enlarged-model projection containment are not solved by this UI pass. Slider work is described below.
- The previous zero-depth layout repair improves default framing, but a 2.5× model can still project across its caption. A rendering-portal prototype contained it visually, but coordinate-tap input tests failed for both the portal and the existing baseline. This is inconclusive input evidence, not proof of a portal regression. The unverified prototype and temporary diagnostic tests were removed; the existing native entity gesture path remains. Baseline direct input still needs real pointer/headset verification.
- The audit's right-edge cropping is partly outside the recording frame. Simulator bounds tests are useful but do not establish physical-headset layout, gaze, Dynamic Type or oblique-view acceptance.
- Full typography, surface-radius, lesson-column and slider redesigns remain. No claim that all eleven audit issues or all original 35 issues are resolved.
- White popovers and neutral controls require screenshot review as well as UI tests; software tests cannot prove appearance from accessibility labels alone.

Original issue references: HV3-009/010/012/013/014/020/021; viewport containment remains HV3-001/002/008/019.

## Slider and popover continuation

Build 2 issue 5: all six adjustable-control sites now share `HeartSlider`, a UIKit `UISlider` wrapper with a six-point track, 28-point white thumb and 60-point layout/hit area. Size, separation, guided morph and the free timeline preserve their existing binding ranges. Touch-down/up/cancel and accessibility value changes retain the editing callback that pauses playback and releases timeline scrubbing. This uses native adjustment/tracking rather than a decorative bar over an invisible control. [Apple UISlider](https://developer.apple.com/documentation/uikit/uislider) and the installed visionOS SDK expose the track/thumb customization used here. Final interaction and screenshot outcomes are recorded in TESTING.md.

The animation-info popover now has a bounded scrollable body and a persistent Done header, so long layer explanations cannot push dismissal below the visible panel. The guided title also loses its redundant grey container, matching Free Exploration.

Visual follow-up: the native visionOS slider hid its custom thumb at rest despite `.default` style. A non-interactive 28-point position indicator now follows the normalized value along the native track, including right-to-left layout. UIKit still owns tracking and accessibility; the marker is not a separate hit target or accessibility element. The initial test run also exposed stale pre-morph-default navigation/title expectations and reliance on SwiftUI's private AXSliderKnob. Tests now enter detailed anatomy explicitly and use XCTest's public normalized slider adjustment for UIKit controls.

Verified outcome: the final simulator build succeeds; portable policy/contrast checks, the complete live asset audit and selected UI regressions pass. The slider track and correctly aligned resting marker are visible in `verification/retest-build2/final-timeline.png`. The two final tests cover popover scrolling/dismissal and size/reset state across both modes. Larger default model framing and maximum-zoom containment remain open; the screenshot makes the current small default morph presentation visible rather than concealing it.
