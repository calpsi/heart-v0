# Interaction recheck

Implemented and installed:
- Excluded mutable renderer caches from SwiftUI observation to avoid a RealityView update invalidating itself when isolation changes the pivot or appearance.
- Replaced drag Euler accumulation and pitch clamping with normalized quaternion deltas around viewing axes. Each drag begins from the current rotation; subsequent drags, close-up serialization, presets and Reset view use the same orientation. The orientation cue follows that quaternion.
- Isolating a selected tissue overrides cutaway/context filtering so it cannot leave an empty view.

Fresh live RealityKit regression passed for 23 assets and 429 isolated pivots. Added checks for scene observation feedback, vertical drag after a 90-degree yaw, consecutive drags, close-up rotation serialization and reset. Existing lesson and separation checks passed.

Direct pointer verification remains inconclusive. Computer-use clicks in Device Hub moved the pointer but did not visibly activate Parts, Isolate or Next phase. Simulator Home also did not visibly respond to the automated command. Do not treat this as a completed end-to-end button pass or claim that all user-reported button failures are resolved.
