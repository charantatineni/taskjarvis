import Foundation
import UserNotifications
import SwiftUI

final class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var labels: [LabelTag] = []
    
    private let dataManager = DataManager.shared
    
    init() {
        loadData()
        setupAppLifecycleObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - App Lifecycle
    
    /// Setup observers for app background/foreground events
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        // Save data when app goes to background
        saveTasks()
        saveLabels()
        print("💾 Data auto-saved on app background")
    }
    
    @objc private func appDidBecomeActive() {
        // Optionally reload data when app becomes active
        // loadData() // Uncomment if you want to reload on app foreground
    }
    
    // MARK: - Data Persistence
    
    /// Load data from local storage
    private func loadData() {
        tasks = dataManager.loadTasks()
        labels = dataManager.loadLabels()
        print("📱 Data loaded: \(tasks.count) tasks, \(labels.count) labels")
    }
    
    /// Save tasks to local storage
    private func saveTasks() {
        dataManager.saveTasks(tasks)
    }
    
    /// Save labels to local storage
    private func saveLabels() {
        dataManager.saveLabels(labels)
    }
    
    // MARK: - Task CRUD Operations
    func addTask(title: String, description: String, time: Date, repeatRule: RepeatRule,
                 alarmEnabled: Bool, notificationOffset: Int, startDate: Date? = nil, label: LabelTag? = nil) {
        let t = Task(id: UUID(), title: title, description: description,
                     time: time, startDate: startDate, repeatRule: repeatRule,
                     label: label, isDone: false, alarmEnabled: alarmEnabled,
                     notificationOffset: notificationOffset)
        tasks.append(t)
        saveTasks() // Save after adding
        scheduleNotifications(for: t)
    }

    func updateTask(_ task: Task, title: String, description: String, time: Date,
                    repeatRule: RepeatRule, alarmEnabled: Bool, notificationOffset: Int,
                    startDate: Date? = nil, label: LabelTag? = nil) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        // Remove ALL existing notifications for this task (not just base ID)
        removeAllNotificationsForTask(task)
        
        tasks[idx].title = title
        tasks[idx].description = description
        tasks[idx].time = time
        tasks[idx].repeatRule = repeatRule
        tasks[idx].alarmEnabled = alarmEnabled
        tasks[idx].notificationOffset = notificationOffset
        tasks[idx].startDate = startDate
        tasks[idx].label = label
        saveTasks() // Save after updating
        scheduleNotifications(for: tasks[idx])
    }
    
    func deleteTask(_ task: Task) {
        // remove from array
        tasks.removeAll { $0.id == task.id }
        saveTasks() // Save after deletion
        // also remove any pending notifications that belong to this task
        removeAllNotificationsForTask(task)
    }
    
    func toggleTask(_ task: Task) {
        if let i = tasks.firstIndex(where: {$0.id == task.id}) {
            tasks[i].isDone.toggle()
            saveTasks() // Save after toggling
        }
    }
    
    private func removeAllNotificationsForTask(_ task: Task) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs
                .filter { $0.identifier.hasPrefix(task.id.uuidString) }
                .map(\.identifier)
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    // MARK: - Label Management
    
    /// Add a new label and save to storage
    func addLabel(_ label: LabelTag) {
        labels.append(label)
        saveLabels()
    }
    
    /// Update an existing label
    func updateLabel(_ label: LabelTag, name: String, colorHex: String) {
        if let index = labels.firstIndex(where: { $0.id == label.id }) {
            labels[index].name = name
            labels[index].colorHex = colorHex
            saveLabels()
            
            // Also update any tasks using this label
            for i in tasks.indices {
                if tasks[i].label?.id == label.id {
                    tasks[i].label = labels[index]
                }
            }
            saveTasks()
        }
    }
    
    /// Delete a label
    func deleteLabel(_ label: LabelTag) {
        labels.removeAll { $0.id == label.id }
        saveLabels()
        
        // Remove label from any tasks using it
        for i in tasks.indices {
            if tasks[i].label?.id == label.id {
                tasks[i].label = nil
            }
        }
        saveTasks()
    }

    // MARK: - Notification Scheduling
    private func scheduleNotifications(for task: Task) {
        // Remove ALL existing notifications for this task first
        removeAllNotificationsForTask(task)
        
        // Wait a moment to ensure removal completes before scheduling new ones
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.createNotifications(for: task)
        }
    }
    
    private func createNotifications(for task: Task) {
        // choose content
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.description.isEmpty ? "Reminder" : task.description
        // custom sound (also plays on lock screen). If "alarm" disabled, use default.
        content.sound = task.alarmEnabled
            ? UNNotificationSound(named: .init("alarm2s.caf"))
            : .default

        if let hex = task.label?.colorHex { content.userInfo["labelHex"] = hex }

        // compute trigger(s)
        let cal = Calendar.current
        let baseTime = task.time.addingTimeInterval(TimeInterval(-task.notificationOffset * 60))

        // Start gate: if startDate in future, first fire is on that date (hour/minute from time)
        let firstDate: Date? = {
            if let sd = task.startDate {
                let comps = cal.dateComponents([.year,.month,.day], from: sd)
                let hm = cal.dateComponents([.hour,.minute], from: baseTime)
                var merged = DateComponents()
                merged.year = comps.year; merged.month = comps.month; merged.day = comps.day
                merged.hour = hm.hour; merged.minute = hm.minute
                return cal.date(from: merged)
            }
            return nil
        }()

        switch task.repeatRule {
        case .routines(let days):
            // schedule repeated by weekday at that hour/min
            for d in (days.isEmpty ? Set(Weekday.allCases) : days) {
                var dc = DateComponents()
                dc.weekday = d.rawValue
                dc.hour = cal.component(.hour, from: baseTime)
                dc.minute = cal.component(.minute, from: baseTime)
                let trig = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(task.id.uuidString)-\(d.rawValue)", content: content, trigger: trig)
                UNUserNotificationCenter.current().add(req) { error in
                    if let error = error {
                        print("❌ Notification scheduling failed: \(error.localizedDescription)")
                    }
                }
            }
            // if startDate exists and is in future, also schedule a one-off first fire
            if let f = firstDate, f > Date() {
                let trig = UNTimeIntervalNotificationTrigger(timeInterval: max(5, f.timeIntervalSinceNow), repeats: false)
                UNUserNotificationCenter.current().add(.init(identifier: "\(task.id.uuidString)-first", content: content, trigger: trig))
            }

        case .custom(let freq, let values):
            switch freq {
            case .monthly:
                // fire on given days-of-month (default 1 if empty)
                let days = values.isEmpty ? [cal.component(.day, from: baseTime)] : values
                for day in days {
                    var dc = DateComponents()
                    dc.day = day
                    dc.hour = cal.component(.hour, from: baseTime)
                    dc.minute = cal.component(.minute, from: baseTime)
                    let trig = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    UNUserNotificationCenter.current().add(.init(identifier: "\(task.id.uuidString)-m\(day)", content: content, trigger: trig))
                }
            case .yearly:
                // optional: restrict to specific years via one-off time interval triggers
                // If values empty, just every year on this day/month.
                if values.isEmpty {
                    var dc = cal.dateComponents([.month,.day], from: baseTime)
                    dc.hour = cal.component(.hour, from: baseTime)
                    dc.minute = cal.component(.minute, from: baseTime)
                    let trig = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    UNUserNotificationCenter.current().add(.init(identifier: "\(task.id.uuidString)-y", content: content, trigger: trig))
                } else {
                    for y in values {
                        var dc = cal.dateComponents([.month,.day], from: baseTime)
                        dc.year = y
                        dc.hour = cal.component(.hour, from: baseTime)
                        dc.minute = cal.component(.minute, from: baseTime)
                        if let date = cal.date(from: dc), date > Date() {
                            let trig = UNTimeIntervalNotificationTrigger(timeInterval: max(5, date.timeIntervalSinceNow), repeats: false)
                            UNUserNotificationCenter.current().add(.init(identifier: "\(task.id.uuidString)-y\(y)", content: content, trigger: trig))
                        }
                    }
                }
            }
            if let f = firstDate, f > Date() {
                let trig = UNTimeIntervalNotificationTrigger(timeInterval: max(5, f.timeIntervalSinceNow), repeats: false)
                UNUserNotificationCenter.current().add(.init(identifier: "\(task.id.uuidString)-first", content: content, trigger: trig))
            }
        }
    }

    // MARK: - Task Reset Management
    
    /// Reset completed tasks based on their repeat rules (called daily/on app launch)
    func resetCompletedTasksIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        for i in tasks.indices {
            let task = tasks[i]
            
            // Only reset tasks that are completed and have repeat rules
            guard task.isDone else { continue }
            
            switch task.repeatRule {
            case .routines(let weekdays):
                if !weekdays.isEmpty {
                    // Reset daily/weekly tasks at midnight
                    let todayWeekday = Weekday(rawValue: calendar.component(.weekday, from: now)) ?? .sunday
                    if weekdays.contains(todayWeekday) {
                        // Check if we should reset (new day)
                        if shouldResetTask(task, on: now) {
                            tasks[i].isDone = false
                            print("🔄 Reset task: \(task.title)")
                        }
                    }
                }
            case .custom(let frequency, let values):
                switch frequency {
                case .monthly:
                    let todayDay = calendar.component(.day, from: now)
                    if values.contains(todayDay) && shouldResetTask(task, on: now) {
                        tasks[i].isDone = false
                        print("🔄 Reset monthly task: \(task.title)")
                    }
                case .yearly:
                    let todayYear = calendar.component(.year, from: now)
                    if (values.contains(todayYear) || values.isEmpty) && shouldResetTask(task, on: now) {
                        tasks[i].isDone = false
                        print("🔄 Reset yearly task: \(task.title)")
                    }
                }
            }
        }
        
        // Save changes if any tasks were reset
        saveTasks()
    }
    
    /// Check if a task should be reset based on its last completion time
    private func shouldResetTask(_ task: Task, on date: Date) -> Bool {
        // For now, we'll implement a simple daily reset logic
        // In a more sophisticated app, you'd store the last completion date
        let calendar = Calendar.current
        let taskTime = task.time
        
        // Create today's version of the task time
        let todayTaskTime = calendar.date(bySettingHour: calendar.component(.hour, from: taskTime),
                                         minute: calendar.component(.minute, from: taskTime),
                                         second: 0,
                                         of: date)
        
        // Reset if current time has passed today's task time
        return date >= (todayTaskTime ?? date)
    }
    
    // MARK: - Enhanced Task Filtering
    func filteredTasksForFutureStart() -> [Task] {
        tasks.filter { ($0.startDate ?? Date.distantPast) > Date() }
    }
    
    func filteredTasks(filter: TaskListView.TaskFilter) -> [Task] {
        let now = Date()
        let cal = Calendar.current

        switch filter {
        case .all:
            return tasks
        case .completed:
            return tasks.filter { $0.isDone }
        case .pending:
            return tasks.filter { !$0.isDone }
        case .futureStart:
            return tasks.filter { ($0.startDate ?? Date.distantPast) > now }
        case .today:
            return tasks.filter {
                cal.isDateInToday($0.startDate ?? now)
            }
        case .daily:
            return tasks.filter {
                if case .routines = $0.repeatRule { return true }
                return false
            }
        }
    }
    
    // MARK: - Debug and Utility Functions
    
    /// Get data storage statistics
    func getStorageStats() -> String {
        return dataManager.getStorageStats()
    }
    
    /// Force save all data (useful for debugging)
    func forceSaveAll() {
        saveTasks()
        saveLabels()
        print("💾 Force saved all data")
    }
    
    /// Reload all data from storage
    func reloadData() {
        loadData()
        print("🔄 Data reloaded from storage")
    }
    
    /// Create sample data for testing
    func createSampleData() {
        // Create sample tasks
        let sampleTasks = [
            Task(id: UUID(), title: "Morning Exercise", description: "30 minutes cardio",
                 time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
                 startDate: Date(), repeatRule: .routines([.monday, .wednesday, .friday]),
                 label: labels.first { $0.name == "Health" }, isDone: false, alarmEnabled: true, notificationOffset: 5),
            
            Task(id: UUID(), title: "Team Meeting", description: "Weekly standup meeting",
                 time: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()) ?? Date(),
                 startDate: Date(), repeatRule: .routines([.monday]),
                 label: labels.first { $0.name == "Work" }, isDone: false, alarmEnabled: false, notificationOffset: 10),
            
            Task(id: UUID(), title: "Clean Kitchen", description: "Dishes and counters",
                 time: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date(),
                 startDate: Date(), repeatRule: .routines([.sunday]),
                 label: labels.first { $0.name == "Home" }, isDone: false, alarmEnabled: true, notificationOffset: 0)
        ]
        
        tasks.append(contentsOf: sampleTasks)
        saveTasks()
        
        // Schedule notifications for sample tasks
        sampleTasks.forEach { scheduleNotifications(for: $0) }
        
        print("📝 Created \(sampleTasks.count) sample tasks")
    }
}
