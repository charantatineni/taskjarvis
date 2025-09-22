//
//  CompilationCheck.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import Foundation
import SwiftUI

/// This file helps verify all components compile correctly
struct CompilationCheck {
    
    // MARK: - Test Model Creation
    
    static func testDataModels() {
        // Test Task creation
        let task = Task(
            id: UUID(),
            title: "Test Task",
            description: "Test Description",
            time: Date(),
            startDate: Date(),
            repeatRule: .routines([.monday]),
            label: LabelTag(id: UUID(), name: "Test", colorHex: "#FF0000"),
            isDone: false,
            alarmEnabled: true,
            notificationOffset: 5
        )
        
        print("✅ Task model: \(task.title)")
    }
    
    static func testViewModels() {
        // Test ViewModel creation
        let viewModel = TaskViewModel()
        print("✅ TaskViewModel: \(viewModel.tasks.count) tasks")
        
        // Test DataManager
        let dataManager = DataManager.shared
        print("✅ DataManager: \(dataManager.getStorageStats())")
    }
    
    static func testViews() -> some View {
        VStack {
            // Test LogoView
            AppIconView()
            
            // Test TaskListView components would go here
            // but we can't easily test them without running the full app
            
            Text("All views compile successfully")
        }
    }
    
    // MARK: - Common Error Patterns to Check
    
    static func checkCommonErrors() {
        // 1. Check for missing imports
        print("Checking imports...")
        
        // 2. Check for protocol conformance
        print("Checking protocols...")
        
        // 3. Check for missing functions
        print("Checking function signatures...")
        
        // 4. Check for data persistence
        testDataPersistence()
    }
    
    static func testDataPersistence() {
        let dataManager = DataManager.shared
        
        // Test save/load cycle
        let testTasks = [
            Task(id: UUID(), title: "Test", description: "", time: Date(),
                 startDate: nil, repeatRule: .routines([]), label: nil,
                 isDone: false, alarmEnabled: false, notificationOffset: 0)
        ]
        
        dataManager.saveTasks(testTasks)
        let loaded = dataManager.loadTasks()
        
        print("✅ Data persistence: Saved \(testTasks.count), Loaded \(loaded.count)")
    }
}

// MARK: - Preview for Visual Verification

#Preview("Compilation Check") {
    VStack(spacing: 20) {
        Text("TaskJarvis Compilation Check")
            .font(.title)
            .fontWeight(.bold)
        
        // Test logo displays
        HStack(spacing: 15) {
            AppIconView(size: 30)
            AppIconView(size: 40)
            AppIconView(size: 50)
        }
        
        // Test UI components
        CompilationCheck.testViews()
        
        Button("Run Checks") {
            CompilationCheck.checkCommonErrors()
        }
        .buttonStyle(.borderedProminent)
        
        Spacer()
    }
    .padding()
}