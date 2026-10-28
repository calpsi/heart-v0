# Build 2 button migration

Native bordered controls were accent-tinted by visionOS. Explicit shared styles now control both fill and label.

| Source before migration | Previous | Replacement |
|---|---|---|
| FreeExplorationView.swift:129 | Native bordered/prominent | Secondary, dark label on neutral fill |
| FreeExplorationView.swift:187 | Native bordered/prominent | Secondary, dark label on neutral fill |
| FreeExplorationView.swift:199 | Native bordered/prominent | Secondary, dark label on neutral fill |
| FreeExplorationView.swift:203 | Native bordered/prominent | Secondary, dark label on neutral fill |
| FreeExplorationView.swift:249 | Native bordered/prominent | Secondary, dark label on neutral fill |
| FreeExplorationView.swift:265 | Native bordered/prominent | Secondary, dark label on neutral fill |
| FreeExplorationView.swift:270 | Native bordered/prominent | Secondary, dark label on neutral fill |
| HeartModelView.swift:398 | Native bordered/prominent | Secondary, dark label on neutral fill |
| HeartModelView.swift:562 | Native bordered/prominent | Secondary, dark label on neutral fill |
| HeartModelView.swift:967 | Native bordered/prominent | Secondary, dark label on neutral fill |
| GuidedLearningView.swift:970 | Native bordered/prominent | Secondary, dark label on neutral fill |
| GuidedLearningView.swift:1066 | Native bordered/prominent | Primary, white label |
| GuidedLearningView.swift:1075 | Native bordered/prominent | Secondary, dark label on neutral fill |
| GuidedLearningView.swift:1092 | Native bordered/prominent | Secondary, dark label on neutral fill |
| GuidedLearningView.swift:1126 | Native bordered/prominent | Secondary, dark label on neutral fill |
| GuidedLearningView.swift:1137 | Native bordered/prominent | Secondary, dark label on neutral fill |
| GuidedLearningView.swift:1154 | Native bordered/prominent | Primary, white label |
| ContentView.swift:98 | Native bordered/prominent | Secondary, dark label on neutral fill |

Narration uses Primary; navigation and information peers use Secondary. Custom tool/filter chips retain Chip styling.
