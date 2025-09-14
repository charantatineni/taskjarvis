//
//  TaskRow.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//

import SwiftUI

struct TaskRow: View {
    var task: Task
    var onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isDone ? .green : .blue)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(Color(.label)) // adapts to dark/light
                    .strikethrough(task.isDone, color: .gray)
                Text(task.time, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground)) // works in dark/light
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

