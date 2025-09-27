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
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .secondary : .primary)
                
                Text(task.time, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.repeatTag)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(task.nextOccurrenceText)
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                    .fontWeight(.medium)
                
                // Show completion status without circle
                if task.isDone {
                    Text("✓ Done")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
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
        if let label = task.label {
            let c = Color(listHex: label.colorHex)
            return [c.opacity(0.8), c.opacity(0.4)]
        }
        return [Color(.systemGray).opacity(0.3), Color(.systemGray).opacity(0.1)]
    }
}


