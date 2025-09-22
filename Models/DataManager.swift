//
//  DataManager.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/21/25.
//

import Foundation
import SwiftUI

/// Handles local data persistence using UserDefaults and file storage
final class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let tasksKey = "TaskJarvis_Tasks"
    private let labelsKey = "TaskJarvis_Labels"
    
    private init() {}
    
    // MARK: - Task Persistence
    
    /// Save tasks array to local storage
    func saveTasks(_ tasks: [Task]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: tasksKey)
            print("✅ Tasks saved successfully: \(tasks.count) tasks")
        } catch {
            print("❌ Failed to save tasks: \(error.localizedDescription)")
        }
    }
    
    /// Load tasks array from local storage
    func loadTasks() -> [Task] {
        guard let data = UserDefaults.standard.data(forKey: tasksKey) else {
            print("📄 No saved tasks found")
            return []
        }
        
        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            print("✅ Loaded \(tasks.count) tasks from storage")
            return tasks
        } catch {
            print("❌ Failed to load tasks: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Label Persistence
    
    /// Save labels array to local storage
    func saveLabels(_ labels: [LabelTag]) {
        do {
            let data = try JSONEncoder().encode(labels)
            UserDefaults.standard.set(data, forKey: labelsKey)
            print("✅ Labels saved successfully: \(labels.count) labels")
        } catch {
            print("❌ Failed to save labels: \(error.localizedDescription)")
        }
    }
    
    /// Load labels array from local storage
    func loadLabels() -> [LabelTag] {
        guard let data = UserDefaults.standard.data(forKey: labelsKey) else {
            print("📄 No saved labels found, returning defaults")
            return defaultLabels()
        }
        
        do {
            let labels = try JSONDecoder().decode([LabelTag].self, from: data)
            print("✅ Loaded \(labels.count) labels from storage")
            return labels
        } catch {
            print("❌ Failed to load labels: \(error.localizedDescription)")
            return defaultLabels()
        }
    }
    
    // MARK: - Default Data
    
    /// Default labels for first app launch
    private func defaultLabels() -> [LabelTag] {
        [
            LabelTag(id: UUID(), name: "Work", colorHex: "#FF6B6B"),
            LabelTag(id: UUID(), name: "Health", colorHex: "#4DD0E1"),
            LabelTag(id: UUID(), name: "Home", colorHex: "#FFD166")
        ]
    }
    
    // MARK: - Clear Data (for testing/debugging)
    
    /// Clear all stored data
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: tasksKey)
        UserDefaults.standard.removeObject(forKey: labelsKey)
        print("🗑 All data cleared")
    }
    
    // MARK: - Data Export/Import (Future Feature)
    
    /// Get tasks as JSON string for export
    func exportTasksAsJSON() -> String? {
        let tasks = loadTasks()
        do {
            let data = try JSONEncoder().encode(tasks)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ Failed to export tasks: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Import tasks from JSON string
    func importTasksFromJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        
        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            saveTasks(tasks)
            return true
        } catch {
            print("❌ Failed to import tasks: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Backup Manager (Future Enhancement)

/// Handles automated backups and data integrity
extension DataManager {
    
    /// Create a backup of current data
    func createBackup() {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupKey = "TaskJarvis_Backup_\(timestamp)"
        
        let backupData = [
            "tasks": loadTasks(),
            "labels": loadLabels(),
            "timestamp": timestamp
        ] as [String: Any]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: backupData)
            UserDefaults.standard.set(data, forKey: backupKey)
            print("✅ Backup created: \(backupKey)")
        } catch {
            print("❌ Failed to create backup: \(error.localizedDescription)")
        }
    }
    
    /// Get list of available backups
    func getAvailableBackups() -> [String] {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        return allKeys.filter { $0.hasPrefix("TaskJarvis_Backup_") }
                     .sorted(by: >)  // Most recent first
    }
    
    /// Restore from backup
    func restoreFromBackup(_ backupKey: String) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: backupKey) else {
            return false
        }
        
        do {
            let backupData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let tasksData = backupData?["tasks"] as? Data {
                let tasks = try JSONDecoder().decode([Task].self, from: tasksData)
                saveTasks(tasks)
            }
            
            if let labelsData = backupData?["labels"] as? Data {
                let labels = try JSONDecoder().decode([LabelTag].self, from: labelsData)
                saveLabels(labels)
            }
            
            print("✅ Restored from backup: \(backupKey)")
            return true
        } catch {
            print("❌ Failed to restore backup: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Debug and Utilities
    
    /// Get current storage statistics
    func getStorageStats() -> String {
        let tasks = loadTasks()
        let labels = loadLabels()
        let tasksSize = (try? JSONEncoder().encode(tasks))?.count ?? 0
        let labelsSize = (try? JSONEncoder().encode(labels))?.count ?? 0
        
        return """
        📊 Storage Statistics:
        • Tasks: \(tasks.count) (\(tasksSize) bytes)
        • Labels: \(labels.count) (\(labelsSize) bytes)
        • Total: \(tasksSize + labelsSize) bytes
        """
    }
    
    /// Reset to fresh app state (for testing)
    func resetToDefaults() {
        clearAllData()
        let defaultLabels = [
            LabelTag(id: UUID(), name: "Work", colorHex: "#FF6B6B"),
            LabelTag(id: UUID(), name: "Health", colorHex: "#4DD0E1"),
            LabelTag(id: UUID(), name: "Home", colorHex: "#FFD166")
        ]
        saveLabels(defaultLabels)
        print("🔄 Reset to default state")
    }
}