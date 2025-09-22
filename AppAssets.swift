//
//  AppAssets.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import Foundation
import SwiftUI

/// Asset management for app icons, logos, and images
struct AppAssets {
    
    // MARK: - Logo Assets
    
    /// Main app logo (looks for "logo" in bundle)
    static let appLogo = "logo"
    
    /// App icon variations
    static let appIcon = "AppIcon"
    static let appIconSmall = "AppIcon-Small"
    static let appIconLarge = "AppIcon-Large"
    
    // MARK: - System Icons (SF Symbols)
    
    struct SystemIcons {
        static let task = "checkmark.circle"
        static let taskFilled = "checkmark.circle.fill" 
        static let reminder = "bell"
        static let reminderFilled = "bell.fill"
        static let calendar = "calendar"
        static let settings = "gearshape.fill"
        static let add = "plus.circle.fill"
        static let delete = "trash"
        static let edit = "pencil"
        static let repeatIcon = "repeat"
        static let alarm = "alarm"
    }
    
    // MARK: - Colors
    
    struct Colors {
        static let primary = Color.red
        static let secondary = Color.orange  
        static let accent = Color.red
        static let background = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
    }
}

/// Instructions for adding logo to the project
struct LogoSetupGuide {
    static let instructions = """
    📱 Adding Your Logo to TaskJarvis
    
    To add your logo to the app, follow these steps:
    
    1. PREPARE YOUR LOGO:
       • Create logo images in multiple sizes:
         - logo.png (120x120 for main display)
         - logo@2x.png (240x240 for Retina)
         - logo@3x.png (360x360 for high-res)
       
    2. ADD TO XCODE PROJECT:
       • Open Xcode
       • Right-click on your project in Navigator
       • Select "Add Files to [Project Name]"
       • Choose your logo files
       • Make sure "Add to target" is checked
    
    3. ALTERNATIVE - ASSETS CATALOG:
       • Open Assets.xcassets in Xcode
       • Right-click → New Image Set
       • Name it "logo"
       • Drag your logo images to 1x, 2x, 3x slots
    
    4. VERIFY:
       • The LogoView will automatically detect and use your logo
       • If no logo is found, it shows a gradient with SF Symbol
    
    📋 Recommended Logo Specifications:
    • Format: PNG with transparency
    • Aspect ratio: Square (1:1)
    • Background: Transparent or solid color
    • Style: Simple, recognizable at small sizes
    • Colors: Should work on light and dark backgrounds
    
    💡 The app is already configured to use your logo!
    Just add the "logo" image to your project bundle.
    """
}

#Preview("Logo Setup Guide") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text("Logo Setup Instructions")
                .font(.title)
                .fontWeight(.bold)
            
            Text(LogoSetupGuide.instructions)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            
            Divider()
            
            Text("Current Logo Display:")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Small")
                    AppIconView(size: 30)
                }
                
                VStack {
                    Text("Medium") 
                    AppIconView(size: 50)
                }
                
                VStack {
                    Text("Large")
                    AppIconView(size: 80)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}