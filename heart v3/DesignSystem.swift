import Foundation

/// Opaque reading surfaces use explicit contrast pairs; anatomy colours are separate.
enum HeartDesignTokens {
    static let accent: SIMD3<Double> = [214.0/255, 51.0/255, 108.0/255]
    static let primary: SIMD3<Double> = [28.0/255, 28.0/255, 30.0/255]
    static let secondary: SIMD3<Double> = [72.0/255, 72.0/255, 74.0/255]
    static let surface = SIMD3<Double>(repeating: 1)
    static let panel: SIMD3<Double> = [237.0/255, 237.0/255, 240.0/255]
    static let disabled: SIMD3<Double> = [102.0/255, 102.0/255, 110.0/255]
    static var selected: SIMD3<Double> { surface * 0.86 + accent * 0.14 }
    static func contrast(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        func luminance(_ rgb: SIMD3<Double>) -> Double {
            func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            return linear(rgb.x) * 0.2126 + linear(rgb.y) * 0.7152 + linear(rgb.z) * 0.0722
        }
        let x = luminance(a), y = luminance(b)
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }
}

#if os(visionOS)
import SwiftUI

enum HeartDesign {
    static func color(_ rgb: SIMD3<Double>) -> Color { Color(red: rgb.x, green: rgb.y, blue: rgb.z) }
    static let accent = color(HeartDesignTokens.accent)
    static let text = color(HeartDesignTokens.primary)
    static let secondary = color(HeartDesignTokens.secondary)
    static let surface = Color.white
    static let panel = color(HeartDesignTokens.panel)
    static let selected = color(HeartDesignTokens.selected)
    static let disabled = color(HeartDesignTokens.disabled)
    static let border = Color(red: 216.0/255, green: 216.0/255, blue: 222.0/255)
}

private struct HeartReadingPanel: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.foregroundStyle(HeartDesign.text)
            .background(HeartDesign.panel, in: RoundedRectangle(cornerRadius: radius))
    }
}
extension View {
    func heartPanel(cornerRadius: CGFloat = 20) -> some View { modifier(HeartReadingPanel(radius: cornerRadius)) }
    func heartPopover() -> some View {
        self.foregroundStyle(HeartDesign.text)
            .tint(HeartDesign.accent).preferredColorScheme(.light)
            .buttonStyle(HeartSecondaryButtonStyle())
            .presentationBackground(HeartDesign.surface)
    }
}

struct HeartPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body.weight(.semibold))
            .foregroundStyle(enabled ? Color.white : HeartDesign.disabled)
            .padding(.horizontal, 16).frame(minWidth: 60, minHeight: 60)
            .background(enabled ? HeartDesign.accent : HeartDesign.panel, in: Capsule())
            .contentShape(Rectangle()).opacity(enabled ? (configuration.isPressed ? 0.85 : 1) : 1)
            .hoverEffect(.highlight, isEnabled: enabled)
    }
}
struct HeartSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.medium)).foregroundStyle(enabled ? HeartDesign.text : HeartDesign.disabled)
            .padding(.horizontal, 12).frame(minWidth: 60, minHeight: 60)
            .background(HeartDesign.panel, in: Capsule())
            .overlay(Capsule().stroke(HeartDesign.border, lineWidth: 1))
            .contentShape(Rectangle()).opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 1)
            .hoverEffect(.highlight, isEnabled: enabled)
    }
}
struct HeartTertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline).foregroundStyle(enabled ? HeartDesign.accent : HeartDesign.secondary)
            .frame(minWidth: 60, minHeight: 60).contentShape(Rectangle())
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 1)
            .hoverEffect(.highlight, isEnabled: enabled)
    }
}
struct HeartChipStyle: ButtonStyle {
    let selected: Bool
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(enabled ? HeartDesign.text : HeartDesign.disabled)
            .background(selected && enabled ? HeartDesign.selected : HeartDesign.panel, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected && enabled ? HeartDesign.accent : HeartDesign.border, lineWidth: 2))
            .contentShape(Rectangle()).opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 1)
            .hoverEffect(.highlight, isEnabled: enabled)
    }
}
#endif
