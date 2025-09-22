//
//  LogoView.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import SwiftUI

/// A flexible logo view that can display custom images or fallback to SF Symbols
struct LogoView: View {
    let size: CGSize
    let logoName: String
    let fallbackSymbol: String
    
    init(size: CGSize = CGSize(width: 40, height: 40), 
         logoName: String = "logo",
         fallbackSymbol: String = "checkmark.circle.fill") {
        self.size = size
        self.logoName = logoName
        self.fallbackSymbol = fallbackSymbol
    }
    
    var body: some View {
        Group {
            if let logoImage = UIImage(named: logoName) {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Fallback to SF Symbol with gradient background
                ZStack {
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Image(systemName: fallbackSymbol)
                        .font(.system(size: size.width * 0.5, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

/// App icon view for various contexts
struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        LogoView(
            size: CGSize(width: size, height: size),
            logoName: "logo",
            fallbackSymbol: "list.bullet.clipboard"
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

/// Small logo for navigation bars and headers
struct NavLogoView: View {
    var body: some View {
        AppIconView(size: 28)
    }
}