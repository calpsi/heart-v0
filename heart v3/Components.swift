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
                    .frame(width: 72, height: 72)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(HeartDesign.accent)
                    .accessibilityHidden(true)
                
                VStack(spacing: 0) {
                    Text(title)
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            // Apply padding to the entire button content, including the icon.
            .padding(24)
            .frame(width: 320, height: 260)
            .background(HeartDesign.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(HeartDesign.border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .hoverEffect(.highlight)
    }
}
