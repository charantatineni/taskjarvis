//
//  TaskRow.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//

import SwiftUI

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                Text(task.time, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(task.repeatTag)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
    }
    
    private var gradientColors: [Color] {
        if let label = task.label, let c = Color(hex: label.colorHex) {
            return [c.opacity(0.8), c.opacity(0.4)]
        }
        return [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]
    }
}


