import SwiftUI

private struct ExplorationStage: Identifiable {
    let id: Int
    let day: String
    let name: String
}

struct FreeExplorationView: View {
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil
    @State private var selectedStage = 0
    @State private var selectedDevelopmentAssetID: String?
    @State private var selectedAnomalyAssetID: String?
    @State private var showingAnomalies = false
    @State private var showingAllAnomalies = false
    @State private var showingAllStages = false

    private let stages: [ExplorationStage] = [
        .init(id: 0, day: "Day 18", name: "Cardiogenic field"),
        .init(id: 1, day: "Day 21", name: "Paired heart tubes"),
        .init(id: 2, day: "Day 22", name: "Primitive heart tube"),
        .init(id: 3, day: "Days 23–28", name: "Cardiac looping"),
        .init(id: 4, day: "Day 28", name: "Septation begins"),
        .init(id: 5, day: "Day 35", name: "Developing septa"),
        .init(id: 6, day: "Day 50", name: "Outflow and valves"),
        .init(id: 7, day: "Birth", name: "Circulatory transition")
    ]

    private var currentStage: ExplorationStage { stages[selectedStage] }

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
                    Text("FREE EXPLORATION").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                    Text(currentAsset?.lesson ?? currentStage.name).font(.title2.bold()).lineLimit(2)
                }
                .padding(.horizontal, 24).padding(.vertical, 14)
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
                Spacer()
                explorationModeSelector
            }

            if let asset = currentAsset {
                HeartModelView(asset: asset, obscuredBySheet: showingAllAnomalies || showingAllStages).id(asset.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HeartModelUnavailableView(title: currentStage.name)
                    .frame(maxHeight: .infinity)
                    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
                    .padding(80)
            }

            if showingAnomalies { anomalyChooser } else { stageNavigation }
        }
        .onChange(of: selectedStage) { _, _ in selectedDevelopmentAssetID = nil }
        .onAppear {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "--preview-stage"), index + 1 < args.count,
               let stage = Int(args[index + 1]), stages.indices.contains(stage) {
                selectedStage = stage
            }
            if let index = args.firstIndex(of: "--preview-anomaly"), index + 1 < args.count,
               let anomaly = Int(args[index + 1]), anomalyAssets.indices.contains(anomaly) {
                showingAnomalies = true
                selectedAnomalyAssetID = anomalyAssets[anomaly].id
            }
            if args.contains("--preview-all-anomalies") { showingAllAnomalies = true }
            #endif
        }
        .padding(28)
        .frame(minWidth: 960, idealWidth: 1100, maxWidth: .infinity,
               minHeight: 700, idealHeight: 780, maxHeight: .infinity)
    }

    private var explorationModeSelector: some View {
        SpatialChoicePicker(title: "Explore", selection: Binding(
            get: { showingAnomalies ? "anomalies" : "development" },
            set: { showingAnomalies = $0 == "anomalies" }
        ), choices: [
            .init(id: "development", title: "Development"),
            .init(id: "anomalies", title: "Anomalies")
        ])
        .frame(width: 300)
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
            }.buttonStyle(.bordered).disabled(anomalyIndex == 0).accessibilityLabel("Previous anomaly")
            if let asset = currentAsset {
                Image(asset.artworkName).resizable().scaledToFit().frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.shortName ?? asset.lesson).font(.headline)
                    Text("Anomaly \(anomalyIndex + 1) of \(anomalyAssets.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("All anomalies", systemImage: "square.grid.2x2") { showingAllAnomalies = true }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showingAllAnomalies) { anomalyOverview }
            Button { moveAnomaly(by: 1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }.buttonStyle(.bordered).disabled(anomalyIndex >= anomalyAssets.count - 1).accessibilityLabel("Next anomaly")
        }
        .padding(16).frame(maxWidth: 900)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28))
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
                Button { selectedStage -= 1 } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered).disabled(selectedStage == 0)
                .accessibilityLabel("Previous developmental stage")

                VStack(alignment: .leading, spacing: 0) {
                    Text(currentAsset?.category == "reference" ? "\(currentAsset!.lesson) · \(currentStage.name)" : "\(currentStage.day) · \(currentStage.name)").font(.headline)
                    Slider(value: Binding(
                        get: { Double(selectedStage) },
                        set: { selectedStage = min(stages.count - 1, max(0, Int($0.rounded()))) }
                    ), in: 0...Double(stages.count - 1), step: 1)
                    .tint(Color.accentColor).frame(minHeight: 44)
                    .accessibilityLabel("Developmental stage")
                    .accessibilityValue("\(currentStage.day), \(currentStage.name)")
                }
                Button("Stages \(selectedStage + 1)/\(stages.count)", systemImage: "list.bullet") {
                    showingAllStages = true
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showingAllStages) { stageOverview }
                Button { selectedStage += 1 } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered).disabled(selectedStage == stages.count - 1)
                .accessibilityLabel("Next developmental stage")
            }
            if stageAssets.count > 1 {
                SpatialChoicePicker(title: "Model at this stage", selection: Binding(
                    get: { currentAsset?.id ?? "" },
                    set: { selectedAssetID = $0 }
                ), choices: stageAssets.map { .init(id: $0.id, title: $0.lesson) })
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .frame(maxWidth: 900)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
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
