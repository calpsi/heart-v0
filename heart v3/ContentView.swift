//
//  ContentView.swift
//  heart v3
//
//  Created by Phillicia Lim on 10/9/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showingFreeExploration = false
    @State private var showingGuidedLearning = false
    @State private var showingReferences = false

    @ViewBuilder
    private var learningButtons: some View {
        DButton(
            title: "Free Exploration",
            description: "Explore, rotate and separate the developing heart at your own pace.",
            icon: Image("ExploreHeart"),
            action: {
                showingFreeExploration = true
            }
        )

        DButton(
            title: "Guided Learning",
            description: "Follow each stage with clear explanations and narrated lessons.",
            icon: Image("GuidedHeart"),
            action: {
                showingGuidedLearning = true
            }
        )
    }

    var body: some View {
        Group {
            if showingFreeExploration {
                FreeExplorationView { showingFreeExploration = false }
            } else if showingGuidedLearning {
                GuidedLearningView(onBack: { showingGuidedLearning = false })
            } else {
                home
            }
        }
        .tint(Color.accentColor)
        .sheet(isPresented: $showingReferences) {
            NavigationStack { ReferencesView() }.frame(width: 700, height: 520)
        }
        .task {
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--validate-heart-assets") && !arguments.contains("--preview-guided") && !arguments.contains("--preview-exploration") {
                showingFreeExploration = true
            }
            if arguments.contains("--preview-exploration") { showingFreeExploration = true }
            if arguments.contains("--preview-guided") { showingGuidedLearning = true }
            #endif
        }
    }

    private var home: some View {
        Group {
            VStack (spacing: 32){
                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    Image("HeartHero")
                        .resizable().scaledToFit().frame(width: 140, height: 140)
                        .accessibilityHidden(true)
                    Text("Welcome to HeartV3").font(.largeTitle.bold())
                    Text("Discover how a heart takes shape.")
                        .font(.title3).foregroundStyle(.secondary)
                }
                
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 40) {
                        learningButtons
                    }

                    VStack(spacing: 24) {
                        learningButtons
                    }
                }

                Spacer(minLength: 0)

                HStack {
                    Spacer()

                    Button("References") {
                        showingReferences = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .glassBackgroundEffect()

        }
    }
}

#Preview(windowStyle: .plain) {
    ContentView()
}
