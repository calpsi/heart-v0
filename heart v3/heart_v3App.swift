//
//  heart_v3App.swift
//  heart v3
//
//  Created by Phillicia Lim on 10/9/26.
//

import SwiftUI

@main
struct heart_v3App: App {
    private var progressStore: UserDefaults {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return UserDefaults(suiteName: "HeartV3.UIInteractionTests")!
        }
        #endif
        return .standard
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .defaultAppStorage(progressStore)
        }
        .windowStyle(.plain)
        .defaultSize(width: 1100, height: 780)
        .windowResizability(.contentSize)

        WindowGroup(id: "guided-lesson") {
            GuidedLessonWindowView().tint(Color.accentColor)
                .modifier(HeartWorkspaceBackground())
                .defaultAppStorage(progressStore)
        }
        .windowStyle(.plain)
        .defaultSize(width: 1100, height: 780)
        .windowResizability(.contentSize)
    }
}

struct GuidedLessonWindowView: View {
    var body: some View {
        GuidedLearningView()
    }
}
