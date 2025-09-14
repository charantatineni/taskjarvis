import Foundation
import UserNotifications
import SwiftUI

final class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var labels: [LabelTag] = [
        LabelTag(id: UUID(), name: "Work",  colorHex: "#FF6B6B"),
        LabelTag(id: UUID(), name: "Health",colorHex: "#4DD0E1"),
        LabelTag(id: UUID(), name: "Home",  colorHex: "#FFD166")
    ]

    // MARK: CRUD
    func addTask(title: String, description: String, time: Date, repeatRule: RepeatRule,
                 alarmEnabled: Bool, notificationOffset: Int, startDate: Date? = nil, label: LabelTag? = nil) {
        let t = Task(id: UUID(), title: title, description: description,
                     time: time, startDate: startDate, repeatRule: repeatRule,
                     label: label, isDone: false, alarmEnabled: alarmEnabled,
                     notificationOffset: notificationOffset)
        tasks.append(t)
        scheduleNotifications(for: t)
    }

    func updateTask(_ task: Task, title: String, description: String, time: Date,
                    repeatRule: RepeatRule, alarmEnabled: Bool, notificationOffset: Int,
                    startDate: Date? = nil, label: LabelTag? = nil) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].title = title
        tasks[idx].description = description
        tasks[idx].time = time
        tasks[idx].repeatRule = repeatRule
        tasks[idx].alarmEnabled = alarmEnabled
        tasks[idx].notificationOffset = notificationOffset
        tasks[idx].startDate = startDate
        tasks[idx].label = label
        scheduleNotifications(for: tasks[idx])
    }
    
    func deleteTask(_ task: Task) {
        // remove from array
        tasks.removeAll { $0.id == task.id }

        // also remove any pending notifications that belong to this task
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs
                .filter { $0.identifier.hasPrefix(task.id.uuidString) }
                .map(\.identifier)
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func toggleTask(_ task: Task) {
        if let i = tasks.firstIndex(where: {$0.id == task.id}) {
            tasks[i].isDone.toggle()
        }
    }

    // MARK: Scheduling
    private func scheduleNotifications(for task: Task) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])

        // choose content
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.description.isEmpty ? "Reminder" : task.description
        // custom sound (also plays on lock screen). If “alarm” disabled, use default.
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

    // Filters you already have can be extended to use startDate etc.
    func filteredTasksForFutureStart() -> [Task] { tasks.filter { ($0.startDate ?? Date.distantPast) > Date() } }
    
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
}
