////
//
//  DataPersistenceUtils.swift  
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import Foundation

/// Utilities for testing data persistence functionality without Testing framework
struct DataPersistenceUtils {
    
    static func testSaveAndLoadTasks() {
        let dataManager = DataManager.shared
        
        // Clear existing data
        dataManager.clearAllData()
        
        // Create test tasks
        let testTasks = [
            Task(id: UUID(), title: "Test Task 1", description: "Description 1",
                 time: Date(), startDate: Date(), repeatRule: .routines([.monday]),
                 label: nil, isDone: false, alarmEnabled: true, notificationOffset: 5),
            Task(id: UUID(), title: "Test Task 2", description: "Description 2",
                 time: Date(), startDate: Date(), repeatRule: .routines([.tuesday]),
                 label: nil, isDone: true, alarmEnabled: false, notificationOffset: 0)
        ]
        
        // Save tasks
        dataManager.saveTasks(testTasks)
        
        // Load tasks
        let loadedTasks = dataManager.loadTasks()
        
        // Verify
        assert(loadedTasks.count == 2, "Should load 2 tasks")
        assert(loadedTasks[0].title == "Test Task 1", "First task title should match")
        assert(loadedTasks[1].isDone == true, "Second task should be completed")
        
        print("✅ Task persistence test passed")
    }
    
    static func testSaveAndLoadLabels() {
        let dataManager = DataManager.shared
        
        // Create test labels
        let testLabels = [
            LabelTag(id: UUID(), name: "Test Work", colorHex: "#FF0000"),
            LabelTag(id: UUID(), name: "Test Home", colorHex: "#00FF00")
        ]
        
        // Save labels
        dataManager.saveLabels(testLabels)
        
        // Load labels
        let loadedLabels = dataManager.loadLabels()
        
        // Verify
        assert(loadedLabels.count >= 2, "Should have at least 2 labels")
        
        let workLabel = loadedLabels.first { $0.name == "Test Work" }
        let homeLabel = loadedLabels.first { $0.name == "Test Home" }
        
        assert(workLabel?.colorHex == "#FF0000", "Work label color should match")
        assert(homeLabel?.colorHex == "#00FF00", "Home label color should match")
        
        print("✅ Label persistence test passed")
    }
    
    static func testStorageStatistics() {
        let dataManager = DataManager.shared
        
        // Get storage stats
        let stats = dataManager.getStorageStats()
        
        // Verify stats string contains expected information
        assert(stats.contains("Storage Statistics"), "Stats should contain title")
        assert(stats.contains("Tasks:"), "Stats should contain task count")
        assert(stats.contains("Labels:"), "Stats should contain label count")
        assert(stats.contains("bytes"), "Stats should contain size information")
        
        print("📊 \(stats)")
    }
    
    /// Run all persistence tests
    static func runAllTests() {
        print("🧪 Running Data Persistence Tests...")
        testSaveAndLoadTasks()
        testSaveAndLoadLabels()
        testStorageStatistics()
        print("✅ All persistence tests passed!")
    }
}
