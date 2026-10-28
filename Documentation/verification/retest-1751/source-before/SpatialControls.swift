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
        .background(HeartDesign.panel, in: RoundedRectangle(cornerRadius: 20))
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
                .foregroundStyle(HeartDesign.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: horizontal, vertical: true)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 60)

                .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .heartSegment(selected: selected)
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
                HStack(spacing: 4) {
                    Image(systemName: symbol).font(.system(size: 20, weight: .medium))
                    if selected { Image(systemName: "checkmark").font(.subheadline.bold()) }
                }
                Text(title).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.9)
            }
            .frame(minWidth: 82, minHeight: 68)
            .padding(.horizontal, 4)

            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(HeartChipStyle(selected: selected))
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
                .frame(minHeight: 60)
        }
        .buttonStyle(HeartSecondaryButtonStyle())
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
        VStack(spacing: 2) {
            Text("Orientation").font(.footnote)
            ZStack {
                ForEach(axes.indices, id: \.self) { index in
                    let axis = projected(axes[index].1)
                    let x = CGFloat(axis.x) * 24
                    let y = -CGFloat(axis.y) * 24
                    Path { path in
                        path.move(to: CGPoint(x: 32, y: 32))
                        path.addLine(to: CGPoint(x: 32 + x, y: 32 + y))
                    }.stroke(Color.primary.opacity(axis.z < 0 ? 0.4 : 0.9), lineWidth: 2)
                    Text(axes[index].0).font(.footnote.bold())
                        .foregroundStyle(Color.primary.opacity(axis.z < 0 ? 0.55 : 1))
                        .offset(x: abs(x) + abs(y) < 8 ? 20 : x * 1.25,
                                y: abs(x) + abs(y) < 8 ? 20 : y * 1.25)
                }
                Circle().fill(Color.primary).frame(width: 4, height: 4)
            }.frame(width: 64, height: 64)
        }
        .padding(4)
        .help(schematic ? "Cr: cranial · V: viewing side" : "L: anatomical left · Cr: cranial · A: anterior")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(schematic ? "Orientation: Cr is cranial; V is the schematic viewing side."
                            : "Orientation: L is anatomical left; Cr is cranial; A is anterior.")
    }
}

/// The visible value and label identify the former unlabeled pink slider.
struct HeartSizeControl: View {
    @Binding var value: Double
    let label: String
    var body: some View {
        HStack(spacing: 12) {
            Text("Size").font(.subheadline)
            HeartSlider(value: $value, in: HeartModelZoom.range)
                .tint(HeartDesign.accent).frame(minWidth: 100, minHeight: 60)
                .accessibilityLabel(label)
                .accessibilityHint("Change viewing size without changing the anatomy.")
            Text("\(value, format: .number.precision(.fractionLength(1)))×")
                .font(.subheadline.monospacedDigit()).frame(minWidth: 50)
        }
    }
}

/// Persistent selection uses a white inset segment and an accent underline;
/// gaze highlighting does not change this selected state.
private struct HeartSegment: ViewModifier {
    let selected: Bool
    func body(content: Content) -> some View {
        content
            .foregroundStyle(selected ? HeartDesign.text : HeartDesign.secondary)
            .background(selected ? HeartDesign.surface : .clear, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? HeartDesign.border : .clear, lineWidth: 1))
            .overlay(alignment: .bottom) {
                if selected { Capsule().fill(HeartDesign.accent).frame(width: 28, height: 3).padding(.bottom, 4) }
            }
            .hoverEffect(.highlight)
    }
}
extension View {
    func heartSegment(selected: Bool) -> some View { modifier(HeartSegment(selected: selected)) }
}
