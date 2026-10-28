import SwiftUI

enum HeartRegion: Hashable {
    case wholeHeart, atria, avJunction, ventricles, outflow, greatVessels
}

/// A conceptual locator, not a transform between separately authored meshes.
struct HeartLocationGuide {
    let title: String
    let detail: String
    let regions: Set<HeartRegion>

    static func guide(for asset: HeartAsset) -> HeartLocationGuide? {
        switch asset.id {
        case "Heart_01_CardiogenicRegion", "Heart_02_PairedHeartTubes", "Heart_03_PrimitiveHeartTube":
            return .init(title: "Early heart formation", detail: "This model shows an early developmental stage, before the four-chamber arrangement used in the later location guides.", regions: [])
        case "Heart_04_CardiacLooping":
            return .init(title: "Developing heart", detail: "The model includes the looped heart and its developing chamber and tube segments.", regions: [.wholeHeart])
        case "Heart_05_AtrialSeptation", "Heart_12_AtrialSeptalDefect":
            return .init(title: "Atrial region", detail: "Inspect the partition between the atria in the enlarged regional model.", regions: [.atria])
        case "Heart_06_EndocardialCushions":
            return .init(title: "Atrioventricular junction", detail: "The cushion model focuses on the junction between the atrial and ventricular regions.", regions: [.avJunction])
        case "Heart_07_VentricularSeptation", "Heart_11_VentricularSeptalDefect":
            return .init(title: "Ventricular region", detail: "Inspect the partition between the ventricles in the enlarged regional model.", regions: [.ventricles])
        case "Heart_08_OutflowSeptation":
            return .init(title: "Outflow tract", detail: "The model focuses on the developing outflow pathways above the ventricles.", regions: [.outflow])
        case "Heart_09_ValvularRefinement":
            return .init(title: "Valve regions", detail: "Atrioventricular and semilunar valve assemblies are spaced apart in the 3D model for inspection.", regions: [.avJunction, .outflow])
        case "Heart_10_CirculatoryTransition":
            return .init(title: "Atria and great vessels", detail: "The model compares the foramen ovale and ductus arteriosus regions across the transition at birth.", regions: [.atria, .greatVessels])
        case "Heart_13_TetralogyOfFallot":
            return .init(title: "Ventricles and outflow", detail: "The model brings the ventricular and outflow features together for inspection.", regions: [.ventricles, .outflow])
        case "Heart_14_TranspositionGreatArteries":
            return .init(title: "Ventricular outlets", detail: "Compare the connections between the ventricular region and the great arteries.", regions: [.ventricles, .outflow, .greatVessels])
        case "Heart_15_AorticCoarctation", "Heart_16_PatentDuctusArteriosus":
            return .init(title: "Great vessels", detail: "The enlarged model focuses on the vessels above the heart.", regions: [.greatVessels])
        default: return nil
        }
    }
}

struct HeartLocationView: View {
    let asset: HeartAsset
    let guide: HeartLocationGuide
    var onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Location guide").font(.title2.bold())
                    Spacer()
                    Button("Done", action: onDone)
                }
                Text(guide.title).font(.headline)
                if guide.regions.isEmpty {
                    Image(asset.artworkName).resizable().scaledToFit().frame(height: 190)
                        .frame(maxWidth: .infinity).accessibilityHidden(true)
                } else {
                    HeartRegionDiagram(regions: guide.regions)
                    Label("Highlighted region", systemImage: "circle.fill")
                        .font(.subheadline).foregroundStyle(Color.accentColor)
                    Text("Simplified heart layout. Positions and proportions are schematic; the 3D model is shown separately.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Text(guide.detail)
                Text(asset.lesson).font(.subheadline).foregroundStyle(.secondary)
            }.padding(24)
        }.frame(width: 400, height: 520).scrollBounceBehavior(.basedOnSize)
    }
}

/// A labelled chamber layout avoids implying registration with a regional asset.
private struct HeartRegionDiagram: View {
    let regions: Set<HeartRegion>

    private func region(_ name: String, _ region: HeartRegion, height: CGFloat) -> some View {
        let selected = regions.contains(region) || regions.contains(.wholeHeart)
        return Text(name).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity).frame(height: height)
            .background(selected ? Color.accentColor.opacity(0.4) : .white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(selected ? Color.accentColor : .white.opacity(0.25), lineWidth: selected ? 2 : 1))
            .accessibilityValue(selected ? "Highlighted" : "")
    }

    var body: some View {
        VStack(spacing: 8) {
            region("Great vessels", .greatVessels, height: 36).padding(.horizontal, 32)
            region("Outflow", .outflow, height: 30).padding(.leading, 160).padding(.trailing, 32)
            HStack(spacing: 8) {
                region("Right atrium", .atria, height: 48)
                region("Left atrium", .atria, height: 48)
            }
            region("Atrioventricular junction", .avJunction, height: 30)
            HStack(spacing: 8) {
                region("Right ventricle", .ventricles, height: 68)
                region("Left ventricle", .ventricles, height: 68)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
