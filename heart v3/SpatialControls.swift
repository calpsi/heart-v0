import SwiftUI
import simd

struct SpatialChoice: Identifiable {
    let id: String
    let title: String
}

/// Keep every option readable; long option sets stack rather than truncate.
struct SpatialChoicePicker: View {
    let title: String
    @Binding var selection: String
    let choices: [SpatialChoice]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                ForEach(choices) { choice in choiceButton(choice, horizontal: true) }
            }
            VStack(spacing: 4) {
                ForEach(choices) { choice in choiceButton(choice, horizontal: false) }
            }
        }
        .padding(4)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func choiceButton(_ choice: SpatialChoice, horizontal: Bool) -> some View {
        let selected = selection == choice.id
        return Button {
            if !selected { selection = choice.id }
        } label: {
            Text(choice.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.black : Color.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: horizontal, vertical: true)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(selected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 22))
                .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Reusable, comfortably sized controls for the floating spatial interface.
struct SpatialToolButton: View {
    let title: String
    let symbol: String
    var selected = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 20, weight: .medium))
                Text(title).font(.caption2.weight(.medium))
            }
            .frame(minWidth: 58, minHeight: 52)
            .padding(.horizontal, 4)
            .background(selected ? Color.accentColor.opacity(0.24) : .clear, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel(title)
        .accessibilityIdentifier("tool." + title)
        .accessibilityValue(selected ? "On" : "Off")
    }
}

struct SpatialBackButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "chevron.left")
                .font(.headline)
                .padding(.horizontal, 20)
                .frame(height: 52)
        }
        .buttonStyle(.plain)
        .glassBackgroundEffect(in: Capsule())
        .hoverEffect(.highlight)
    }
}

/// Projects the asset's documented axes through the same rotation as its anatomy.
struct HeartOrientationCue: View {
    let rotation: simd_quatf
    let schematic: Bool

    private var axes: [(String, SIMD3<Float>)] {
        schematic ? [("Cr", [0, 1, 0]), ("V", [0, 0, 1])]
                  : [("L", [1, 0, 0]), ("Cr", [0, 1, 0]), ("A", [0, 0, 1])]
    }

    private func projected(_ axis: SIMD3<Float>) -> SIMD3<Float> {
        return rotation.act(axis)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(axes.indices, id: \.self) { index in
                    let axis = projected(axes[index].1)
                    let x = CGFloat(axis.x) * 24
                    let y = -CGFloat(axis.y) * 24
                    Path { path in
                        path.move(to: CGPoint(x: 32, y: 32))
                        path.addLine(to: CGPoint(x: 32 + x, y: 32 + y))
                    }.stroke(.white.opacity(axis.z < 0 ? 0.4 : 0.9), lineWidth: 2)
                    Text(axes[index].0).font(.caption2.bold())
                        .foregroundStyle(.white.opacity(axis.z < 0 ? 0.55 : 1))
                        .offset(x: abs(x) + abs(y) < 8 ? 20 : x * 1.25,
                                y: abs(x) + abs(y) < 8 ? 20 : y * 1.25)
                }
                Circle().fill(.white).frame(width: 4, height: 4)
            }.frame(width: 64, height: 64)
        }
        .padding(4)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(schematic ? "Orientation: Cr is cranial; V is the schematic viewing side."
                            : "Orientation: L is anatomical left; Cr is cranial; A is anterior.")
    }
}
