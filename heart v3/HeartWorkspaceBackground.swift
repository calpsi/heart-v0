import SwiftUI

/// A common light window backing. Model viewports have no rendered input
/// planes or opaque overlays between the viewer and their anatomy.
struct HeartWorkspaceBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.light)
            .environment(\.colorScheme, .light)
            .foregroundStyle(HeartDesign.text)
            .tint(HeartDesign.accent)
            .buttonStyle(HeartSecondaryButtonStyle())
            .background {
                RoundedRectangle(cornerRadius: 32).fill(.white)
                    .allowsHitTesting(false)
            }
    }
}
