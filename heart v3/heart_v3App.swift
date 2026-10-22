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

        WindowGroup(id: "heart-close-up", for: HeartCloseUpRequest.self) { request in
            if let request = request.wrappedValue,
               let asset = HeartAsset.allIncludingReferences.first(where: { $0.id == request.assetID }) {
                HeartCloseUpView(asset: asset, controls: request.controls).tint(Color.accentColor)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.1, height: 0.85, depth: 0.9, in: .meters)

        WindowGroup(id: "guided-lesson") {
            GuidedLessonWindowView().tint(Color.accentColor)
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
