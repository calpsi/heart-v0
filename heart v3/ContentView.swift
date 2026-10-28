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
            description: "Trace the developing heart and explore where its anatomy can change.",
            icon: Image(systemName: "heart.text.clipboard"),
            action: {
                showingFreeExploration = true
            }
        )

        DButton(
            title: "Guided Learning",
            description: "Connect developmental changes to congenital heart defects.",
            icon: Image(systemName: "book.closed"),
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
        .frame(minWidth: 1100, minHeight: 780)
        .modifier(HeartWorkspaceBackground())
        .sheet(isPresented: $showingReferences) {
            NavigationStack { ReferencesView() }.frame(width: 700, height: 520)
        }
        .task {
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if (arguments.contains("--validate-heart-assets") || arguments.contains("--validate-heart-transitions")) && !arguments.contains("--preview-guided") && !arguments.contains("--preview-exploration") {
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
                    Text("Welcome to HeartV0").font(.largeTitle.bold())
                    Text("Understand how a heart forms—and where development can differ.")
                        .font(.title3).foregroundStyle(HeartDesign.secondary)
                        .multilineTextAlignment(.center)

                }
                
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 32) {
                        learningButtons
                    }

                    VStack(spacing: 24) {
                        learningButtons
                    }
                }

                Spacer(minLength: 0)

                HStack {
                    Button("References") {
                        showingReferences = true
                    }
                    .buttonStyle(HeartSecondaryButtonStyle())
                }
            }
            .padding(24)

        }
    }
}

#Preview(windowStyle: .plain) {
    ContentView()
}
