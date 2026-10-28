# HeartV3 — Codex implementation brief (second-pass review)

**Read `HEARTV3_SECOND_PASS_AUDIT.md` first, followed by `ISSUE_REGISTER.csv`.** Use `evidence/` only as screenshots; the source recordings should be reviewed around the indicated elapsed timestamps. This is a code task, but the audit is **not** a code diagnosis.

## Fix order (do not implement everything in one change)

1. **PR-1 | Spatial stability:** HV3-001, 002, 005, 006. Identify model root transforms and gesture handling; clamp relative scale/distance; prevent tracking-loss jumps; keep a persistent reachable Fit/Recentre button; preserve intentional rotate/scale. Reproduce B 00:24–00:36 and A 03:00–03:20, then prove the fix on-device.
2. **PR-2 | State lifecycle and recovery:** HV3-003, 004, 007, 022. Independent visibility/explosion/selection/scale/stage state; deterministic Reset model; zero stale anatomy on home/catalogue; regression against A 03:40–03:55 and 06:30–06:40.
3. **PR-3 | Spatial clarity:** HV3-008–016, 019–021, 035. Always legible accessible control dock, clear selection and anatomy axes, default-safe panels and consistent vocabulary. Test passthrough **and** immersive with actual headset, seated and standing.
4. **PR-4 | One genuine recognition task:** HV3-023/024/031. Fix Coarctation → Find the Narrowing so the answer is not shown before response; hint/reveal and confidence tracked distinctly; no advancement alone implies mastery.
5. **PR-5 | Educational transfer vertical slice:** HV3-025–034. Build **Predict → Observe → Explain → Apply to an unseen clinically valid representation → Revisit** with stage linkage, matched normal/anomaly visual comparison and explicit source limitations. Obtain clinician/embryology educator sign-off.

## First output from Codex

Before editing, return a repository-backed implementation plan identifying **actual** framework, file names, model/entity transform/scale code, scene navigation and assessment state. Map the priority tickets to code paths. State which behaviour is intentional, which can be reproduced and which needs an on-headset check. Then implement PR-1 only, run tests, report results, and proceed through independent patches.

## Definition of done

A ticket is **Fixed** only after reproduction, implemented change, automated regression where feasible, and a manual acceptance test. Mark **Not reproduced**, **Needs clinical approval**, **Design decision needed** or **Partially fixed** when appropriate. Do not report every instructional recommendation as a runtime bug, and do not infer a crash from the appearance of the system launcher.
