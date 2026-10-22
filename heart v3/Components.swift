//
//  Components.swift
//  heart v3
//
//  Created by Phillicia Lim on 10/9/26.
//

import SwiftUI

struct DButton: View {
    
    let title: String
    let description: String
    let icon: Image
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118, height: 110)
                    .accessibilityHidden(true)
                
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(description)
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            // Apply padding to the entire button content, including the icon.
            .padding(24)
            .frame(width: 320)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 32))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .hoverEffect(.highlight)
    }
}
