import SwiftUI

struct DevelopmentConnectionView: View {
    let connection: HeartDevelopmentConnection
    var embedded = false
    var onReturn: (() -> Void)? = nil
    var onReplay: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showingSpecimen = false
    @State private var normalComparison = false
    @State private var showingExplanation = false
    @State private var showingProcess = false
    @State private var processSession = HeartMorphSession()
    private var referenceModel: String? { connection.referenceModel }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(connection.timing.uppercased()).font(.subheadline).foregroundStyle(HeartDesign.secondary)
                        .accessibilityLabel(connection.timing).accessibilityIdentifier("connection.window")
                    Text(connection.lesson).font(.title2.bold())
                }
                Spacer()
                Button("Return to development") { if let onReturn { onReturn() } else { dismiss() } }
            }
            HStack(alignment: .top, spacing: 24) {
                if let referenceModel {
                    VStack(spacing: 10) {
                        SpatialChoicePicker(title: "Anatomical comparison",
                            selection: Binding(get: { normalComparison ? "normal" : "altered" }, set: { normalComparison = $0 == "normal" }),
                            choices: [.init(id: "altered", title: connection.id == "ductus" ? "Patent ductus" : "Related anomaly"),
                                      .init(id: "normal", title: connection.id == "ductus" ? "Closed remnant" : "Typical anatomy")])
                        HeartReferenceAnatomyPreview(modelID: normalComparison ? connection.comparisonModel : referenceModel,
                                                     obscured: showingSpecimen || showingProcess, allowsDuctalComparison: false)
                        Text(connection.id == "ductus" ? "Matched authored regional models; closure is gradual after birth." : "Different specimens; compare connections and shape, not size.").font(.subheadline).foregroundStyle(HeartDesign.secondary)
                    }
                } else if let asset = connection.asset {
                    HeartModelView(asset: asset, obscuredBySheet: showingSpecimen || showingProcess).id(asset.id)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Observe → explain").font(.headline)
                    Button(showingExplanation ? "Hide explanation" : "Explain the connection") { showingExplanation.toggle() }
                        .accessibilityIdentifier("connection.explain")
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if showingExplanation {
                                Text("What changes?").font(.headline)
                                Text(connection.difference).accessibilityIdentifier("connection.difference")
                                Text("Why does it matter?").font(.headline)
                                Text(connection.consequence)
                            }
                            Text("Normal process").font(.headline)
                            Text(connection.process)
                            if ["outflow", "tga"].contains(connection.id) {
                                Button("Replay normal outflow division", systemImage: "play.circle") { if let onReplay { onReplay() } else { showingProcess = true } }
                                    .accessibilityIdentifier("connection.replayProcess")
                            }
                            Text("Find the difference").font(.headline)
                            Text("Rotate the anatomy. What connection, opening or narrowing differs from the typical arrangement?")
                            if referenceModel != nil {
                                Button("Explore another anatomical model") { showingSpecimen = true }
                            }
                            Text("Processes overlap; the developmental window above is not an exact onset date.").font(.subheadline).foregroundStyle(HeartDesign.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    }.id(showingExplanation)
                }.frame(width: 300)
            }
        }.padding(embedded ? 18 : 28)
            .frame(width: embedded ? nil : 1040, height: embedded ? nil : 680)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            .sheet(isPresented: $showingSpecimen) { HeartProjectView(initialModel: referenceModel ?? "Normal_Neonatal_Heart") }
            .sheet(isPresented: $showingProcess) {
                VStack(alignment: .trailing) {
                    Button("Return to the anatomy") { showingProcess = false }
                    HeartLoopingMorphView(outflow: true, savedSession: processSession)
                }.padding(24).frame(width: 1000, height: 700)
            }
    }
}

extension HeartDevelopmentConnection {
    var comparisonModel: String { id == "ductus" ? "PDA_Closed" : "Normal_Teenage_Heart" }
    var asset: HeartAsset? { HeartAsset.teachingAsset(for: lesson) }
    var referenceModel: String? {
        id == "cushion" ? "Atrioventricular_septal_defect_4_chamber_view" : HeartProjectModel.modelID(for: lesson)
    }
}
