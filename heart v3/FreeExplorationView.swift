import SwiftUI

struct FreeExplorationView: View {
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil
    @State private var timelinePosition = 1.0
    @State private var tubeSession = HeartMorphSession()
    @State private var outflowSession = HeartMorphSession()
    private var selectedStage: Int {
        get { HeartDevelopmentTimeline.stage(timelinePosition) }
        nonmutating set { timelinePosition = Double(min(7, max(0, newValue))) }
    }
    private var isOutflowMorph: Bool { (5...6).contains(timelinePosition) && (showingLooping || timelinePosition != timelinePosition.rounded()) }
    private var connections: [HeartDevelopmentConnection] { HeartDevelopmentConnection.at(isOutflowMorph ? max(5.001, timelinePosition) : timelinePosition) }
    private var isTimelineMorph: Bool { (1...3).contains(timelinePosition) && (showingLooping || timelinePosition != timelinePosition.rounded()) }
    private var showsMorph: Bool { !showingAnomalies && (isOutflowMorph || isTimelineMorph || (showingLooping && [1, 2, 3].contains(selectedStage))) }
    private var morphProgress: Binding<Double> {
        Binding(get: { isOutflowMorph ? timelinePosition - 5 : min(2, max(0, timelinePosition - 1)) },
                set: { timelinePosition = isOutflowMorph ? 5 + min(1, max(0, $0)) : 1 + min(2, max(0, $0)) })
    }
    @State private var developmentConnection: HeartDevelopmentConnection?
    @State private var showingLooping = true
    @State private var showingHeartAnatomy = false
    @State private var timelineScrubbing = false
    @State private var showingInvestigation = false
    @State private var selectedDevelopmentAssetID: String?
    @State private var selectedAnomalyAssetID: String?
    @State private var showingAnomalies = false
    @State private var showingAllAnomalies = false
    @State private var showingAllStages = false

    private let stages = HeartDevelopmentStage.all
    private var currentStage: HeartDevelopmentStage { stages[selectedStage] }

    private var selectedAssetID: String? {
        get { showingAnomalies ? selectedAnomalyAssetID : selectedDevelopmentAssetID }
        nonmutating set {
            if showingAnomalies { selectedAnomalyAssetID = newValue }
            else { selectedDevelopmentAssetID = newValue }
        }
    }

    private var anomalyAssets: [HeartAsset] { HeartAsset.all.filter { $0.isAnomaly } }
    private var stageAssets: [HeartAsset] {
        showingAnomalies ? anomalyAssets : HeartAsset.allIncludingReferences.filter { !$0.isAnomaly && $0.stageIndex == selectedStage }
    }
    private var currentAsset: HeartAsset? {
        stageAssets.first(where: { $0.id == selectedAssetID }) ?? stageAssets.first
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 20) {
                SpatialBackButton(title: "Home") { if let onBack { onBack() } else { dismiss() } }
                VStack(alignment: .leading, spacing: 4) {
                    Text("FREE EXPLORATION").font(.subheadline.weight(.semibold)).tracking(0.6).foregroundStyle(HeartDesign.secondary)
                    Text(showingHeartAnatomy ? "Heart anatomy" : showingAnomalies ? currentAsset?.lesson ?? "Anomalies" : currentStage.name).font(.title2.bold()).lineLimit(2)
                }
                .padding(.vertical, 4)
                Spacer()
                if !showingHeartAnatomy { Button("Investigate", systemImage: "questionmark.circle") { showingInvestigation.toggle() }
                    .accessibilityIdentifier("exploration.investigate")
                    .popover(isPresented: $showingInvestigation) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Optional investigation").font(.headline)
                                Spacer()
                                Button("Done") { showingInvestigation = false }
                            }
                            Text(showingAnomalies ? "Compare the available configurations. Describe the visible difference before opening its explanation. What does this schematic leave uncertain?" : HeartLearningPilot.investigation(stage: selectedStage))
                            Text("What did you notice? Explain the relationship in your own words, then check it by rotating or reassembling the model.").font(.subheadline).foregroundStyle(HeartDesign.secondary)
                        }.padding(24).frame(width: 400).heartPopover()
                    }
                }
                explorationModeSelector
            }

            if showingHeartAnatomy {
                HeartProjectView(embedded: true)
                    .heartPanel(cornerRadius: 28)
            } else if let connection = developmentConnection {
                DevelopmentConnectionView(connection: connection, embedded: true,
                    onReturn: { developmentConnection = nil },
                    onReplay: { developmentConnection = nil; showingLooping = true })
                    .id(connection.id)
            } else if showsMorph {
                HeartLoopingMorphView(obscured: showingAllStages || showingInvestigation || showingHeartAnatomy || developmentConnection != nil, timelineProgress: morphProgress, includesFusion: !isOutflowMorph, scrubbing: timelineScrubbing, outflow: isOutflowMorph,
                                     savedSession: isOutflowMorph ? outflowSession : tubeSession,
                                     onExploreConnection: connections.first.map { connection in
                                         { developmentConnection = connection }
                                     }).id(isOutflowMorph ? "outflow" : "tube")
            } else if showingAnomalies, let asset = currentAsset,
                      let modelID = HeartProjectModel.modelID(for: asset.lesson) {
                HeartReferenceAnatomyPreview(modelID: modelID,
                    obscured: showingAllAnomalies || showingInvestigation)
                    .id(modelID)
            } else if let asset = currentAsset {
                HeartModelView(asset: asset, obscuredBySheet: showingAllAnomalies || showingAllStages || showingInvestigation || developmentConnection != nil || showingHeartAnatomy).id(asset.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HeartModelUnavailableView(title: currentStage.name)
                    .frame(maxHeight: .infinity)
                    .heartPanel(cornerRadius: 28)
                    .padding(80)
            }

            if !showingHeartAnatomy {
            if developmentConnection == nil {
            HStack {
                if !showingAnomalies {
                    if [1, 2, 3, 5, 6].contains(selectedStage) && timelinePosition == timelinePosition.rounded() {
                        Button(showingLooping ? "Inspect detailed anatomy" : "Watch development", systemImage: showingLooping ? "cube" : "play.circle") {
                            showingLooping.toggle()
                        }.accessibilityIdentifier("development.morph")
                    }
                    if let connection = connections.first {
                        Button("What if this process changes?", systemImage: "arrow.triangle.branch") {
                            developmentConnection = connection
                        }.accessibilityIdentifier("development.connection")
                    }
                    if connections.count > 1 {
                        Menu("Other branches at this process") {
                            ForEach(Array(connections.dropFirst())) { connection in
                                Button(connection.lesson) { developmentConnection = connection }
                            }
                        }.accessibilityIdentifier("development.otherBranches")
                    }
                }
            }.buttonStyle(HeartSecondaryButtonStyle())
            }
            if showingAnomalies { anomalyChooser } else { stageNavigation }
            }
        }
        .onChange(of: timelinePosition) { _, _ in developmentConnection = nil }
        .onChange(of: showingAnomalies) { _, _ in developmentConnection = nil }
        .onChange(of: selectedStage) { _, _ in selectedDevelopmentAssetID = nil }
        .onAppear {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--validate-heart-assets") || args.contains("--validate-heart-transitions") { timelinePosition = 0 }
            if let index = args.firstIndex(of: "--preview-stage"), index + 1 < args.count,
               let stage = Int(args[index + 1]), stages.indices.contains(stage) {
                selectedStage = stage
            }
            if let index = args.firstIndex(of: "--preview-anomaly"), index + 1 < args.count,
               let anomaly = Int(args[index + 1]), anomalyAssets.indices.contains(anomaly) {
                showingAnomalies = true
                selectedAnomalyAssetID = anomalyAssets[anomaly].id
            }
            if let index = args.firstIndex(of: "--preview-timeline"), index + 1 < args.count,
               let position = Double(args[index + 1]) { timelinePosition = HeartDevelopmentTimeline.position(position) }
            if args.contains("--preview-whole-heart") { showingHeartAnatomy = true }
            if args.contains("--preview-looping") { showingLooping = true }
            if args.contains("--preview-all-anomalies") { showingAllAnomalies = true }
            #endif
        }
        .padding(28)
        .frame(minWidth: 1100, idealWidth: 1100, maxWidth: .infinity,
               minHeight: 780, idealHeight: 780, maxHeight: .infinity)
    }

    private var explorationModeSelector: some View {
        SpatialChoicePicker(title: "Explore", selection: Binding(
            get: { showingHeartAnatomy ? "anatomy" : showingAnomalies ? "anomalies" : "development" },
            set: { showingHeartAnatomy = $0 == "anatomy"; if $0 != "anatomy" { showingAnomalies = $0 == "anomalies" } }
        ), choices: [
            .init(id: "development", title: "Development"),
            .init(id: "anomalies", title: "Anomalies"),
            .init(id: "anatomy", title: "Heart anatomy")
        ])
        .frame(width: 420)
    }

    private var anomalyIndex: Int {
        anomalyAssets.firstIndex(where: { $0.id == currentAsset?.id }) ?? 0
    }

    private func moveAnomaly(by offset: Int) {
        let next = anomalyIndex + offset
        guard anomalyAssets.indices.contains(next) else { return }
        selectedAssetID = anomalyAssets[next].id
    }

    private var anomalyChooser: some View {
        HStack(spacing: 16) {
            Button { moveAnomaly(by: -1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }.buttonStyle(HeartSecondaryButtonStyle()).disabled(anomalyIndex == 0).accessibilityLabel("Previous anomaly")
            if let asset = currentAsset {
                Image(asset.artworkName).resizable().scaledToFit().frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.shortName ?? asset.lesson).font(.headline)
                    Text("Anomaly \(anomalyIndex + 1) of \(anomalyAssets.count)")
                        .font(.subheadline).foregroundStyle(HeartDesign.secondary)
                }
            }
            Spacer()
            Button("All anomalies", systemImage: "square.grid.2x2") { showingAllAnomalies = true }
                .buttonStyle(HeartSecondaryButtonStyle())
                .sheet(isPresented: $showingAllAnomalies) { anomalyOverview }
            Button { moveAnomaly(by: 1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }.buttonStyle(HeartSecondaryButtonStyle()).disabled(anomalyIndex >= anomalyAssets.count - 1).accessibilityLabel("Next anomaly")
        }
        .padding(16).frame(maxWidth: 900)
        .heartPanel(cornerRadius: 28)
    }

    private var anomalyOverview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("All anomalies").font(.title2.bold())
                Spacer()
                Button("Done") { showingAllAnomalies = false }
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(anomalyAssets) { asset in
                        Button {
                            selectedAssetID = asset.id
                            showingAllAnomalies = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(asset.artworkName).resizable().scaledToFit().frame(width: 56, height: 56)
                                    .accessibilityHidden(true)
                                Text(asset.shortName ?? asset.lesson).font(.headline).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                if asset.id == currentAsset?.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor) }
                            }
                            .padding(14).frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
                            .background(Color.accentColor.opacity(asset.id == currentAsset?.id ? 0.2 : 0.05), in: RoundedRectangle(cornerRadius: 20))
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain).hoverEffect(.highlight)
                        .accessibilityLabel(asset.lesson)
                        .accessibilityAddTraits(asset.id == currentAsset?.id ? .isSelected : [])
                    }
                }
            }.frame(maxHeight: 360)
        }.padding(24).frame(width: 640)
    }

    private var stageNavigation: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Button { timelinePosition = HeartDevelopmentTimeline.adjacentStage(from: timelinePosition, forward: false) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .buttonStyle(HeartSecondaryButtonStyle()).disabled(selectedStage == 0)
                .accessibilityLabel("Previous developmental stage")

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(currentStage.day) · \(currentStage.name)").font(.headline).accessibilityIdentifier("development.stageTitle")
                    HeartSlider(value: Binding(
                        get: { timelinePosition },
                        set: { timelinePosition = HeartDevelopmentTimeline.position($0); showingLooping = true }
                    ), in: 0...Double(stages.count - 1), onEditingChanged: { timelineScrubbing = $0 })
                    .tint(Color.accentColor).frame(minHeight: 44)
                    .accessibilityLabel("Developmental stage")
                    .accessibilityValue("Stage \(selectedStage + 1) of \(stages.count), \(currentStage.day), \(currentStage.name)")
                }
                Button("Stages \(selectedStage + 1)/\(stages.count)", systemImage: "list.bullet") {
                    showingAllStages = true
                }
                .buttonStyle(HeartSecondaryButtonStyle())
                .sheet(isPresented: $showingAllStages) { stageOverview }
                Button { timelinePosition = HeartDevelopmentTimeline.adjacentStage(from: timelinePosition, forward: true) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .buttonStyle(HeartSecondaryButtonStyle()).disabled(selectedStage == stages.count - 1)
                .accessibilityLabel("Next developmental stage")
            }
            if stageAssets.count > 1 && !showsMorph {
                SpatialChoicePicker(title: "Model at this stage", selection: Binding(
                    get: { currentAsset?.id ?? "" },
                    set: { selectedAssetID = $0 }
                ), choices: stageAssets.map { .init(id: $0.id, title: $0.lesson) })
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .frame(maxWidth: 900)
        .heartPanel(cornerRadius: 24)
    }

    private var stageOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Developmental stages").font(.title2.bold())
                Spacer()
                Button("Done") { showingAllStages = false }
            }
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(stages) { stage in
                        Button {
                            selectedStage = stage.id
                            showingAllStages = false
                        } label: {
                            HStack(spacing: 16) {
                                Text(stage.day).font(.headline).frame(width: 110, alignment: .leading)
                                Text(stage.name).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                if selectedStage == stage.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(14).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(selectedStage == stage.id ? Color.accentColor.opacity(0.18) : .clear,
                                        in: RoundedRectangle(cornerRadius: 16))
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain).hoverEffect(.highlight)
                        .accessibilityLabel("\(stage.day), \(stage.name)")
                        .accessibilityAddTraits(selectedStage == stage.id ? .isSelected : [])
                    }
                }
            }.frame(maxHeight: 440)
        }.padding(24).frame(width: 580)
    }

}

#Preview(windowStyle: .plain) { FreeExplorationView() }
