//
//  TaskJarvisTests.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import Foundation

/// Simple test utilities for verifying core functionality (without Testing framework)
struct TaskJarvisTestUtils {
    
    static func testDataManagerBasicFunctionality() {
        let dataManager = DataManager.shared
        
        // Clear existing data
        dataManager.clearAllData()
        
        // Test empty state
        let emptyTasks = dataManager.loadTasks()
        let defaultLabels = dataManager.loadLabels()
        
        assert(emptyTasks.isEmpty, "Should start with no tasks")
        assert(defaultLabels.count == 3, "Should have 3 default labels")
        
        print("✅ DataManager basic test passed")
    }
    
    static func testTaskPersistence() {
        let dataManager = DataManager.shared
        
        // Create test task
        let testTask = Task(
            id: UUID(),
            title: "Test Task",
            description: "Test Description", 
            time: Date(),
            startDate: Date(),
            repeatRule: .routines([.monday]),
            label: nil,
            isDone: false,
            alarmEnabled: true,
            notificationOffset: 5
        )
        
        // Save and load
        dataManager.saveTasks([testTask])
        let loadedTasks = dataManager.loadTasks()
        
        assert(loadedTasks.count == 1, "Should save and load 1 task")
        assert(loadedTasks.first?.title == "Test Task", "Task title should match")
        
        print("✅ Task persistence test passed")
    }
    
    /// Run all tests
    static func runAllTests() {
        print("🧪 Running TaskJarvis Tests...")
        testDataManagerBasicFunctionality()
        testTaskPersistence()
        print("✅ All tests passed!")
    }
}