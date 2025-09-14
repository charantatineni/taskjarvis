//
//  TaskJarvisApp.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//

import SwiftUI

@main
struct TaskJarvisApp: App {
    @StateObject private var viewModel = TaskViewModel()
    @StateObject private var notifier = NotificationManager.shared

    init() { NotificationManager.shared.configure() }

    var body: some Scene {
        WindowGroup {
            TaskListView(viewModel: viewModel)
                .overlay( alarmOverlay ) // full-screen in-app “alarm”
        }
    }

    private var alarmOverlay: some View {
        Group {
            if let tint = notifier.activeAlarmTint {
                ZStack {
                    tint.opacity(0.94).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "bell.fill").font(.system(size: 56)).foregroundColor(.white)
                        Text("Reminder").font(.title).foregroundColor(.white)
                        Button {
                            NotificationManager.shared.activeAlarmTint = nil
                        } label: {
                            Text("Dismiss").bold()
                                .padding(.horizontal, 24).padding(.vertical, 12)
                                .background(Color.white.opacity(0.2)).cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: notifier.activeAlarmTint)
    }
}

