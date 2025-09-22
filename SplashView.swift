//
//  SplashView.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import SwiftUI

/// Splash screen shown when app is loading
struct SplashView: View {
    @State private var isAnimating = false
    @State private var loadingProgress: Double = 0
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated logo
                VStack(spacing: 20) {
                    AppIconView(size: 120)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .rotationEffect(.degrees(isAnimating ? 0 : -10))
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6),
                            value: isAnimating
                        )
                    
                    Text("TaskJarvis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.8).delay(0.3),
                            value: isAnimating
                        )
                    
                    Text("Your Intelligent Task Assistant")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.8).delay(0.5),
                            value: isAnimating
                        )
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 12) {
                    ProgressView(value: loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(width: 200)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.5).delay(0.8),
                            value: isAnimating
                        )
                    
                    Text("Loading your tasks...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.5).delay(1.0),
                            value: isAnimating
                        )
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .onAppear {
            startLoadingSequence()
        }
    }
    
    private func startLoadingSequence() {
        // Start animations
        withAnimation {
            isAnimating = true
        }
        
        // Simulate loading progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            loadingProgress += 0.02
            
            if loadingProgress >= 1.0 {
                timer.invalidate()
                
                // Complete after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        onComplete()
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView {
        print("Splash completed")
    }
}