import Foundation
//
//  Task.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//

import Foundation
import SwiftUI

enum Weekday: Int, CaseIterable, Codable { // Sun=1 per Calendar
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    var short: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

enum CustomFrequency: String, Codable, CaseIterable {
    case monthly, yearly
}

enum RepeatRule: Codable {
    case routines(Set<Weekday>)
    case custom(CustomFrequency, [Int])

    // Manual CaseIterable
    static var allCases: [RepeatRule] {
        [.routines(Set(Weekday.allCases)), .custom(.monthly, [])]
    }

    // Codable implementation
    private enum CodingKeys: String, CodingKey { case type, weekdays, frequency, values }
    private enum RuleType: String, Codable { case routines, custom }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(RuleType.self, forKey: .type)
        switch type {
        case .routines:
            let days = try container.decode(Set<Weekday>.self, forKey: .weekdays)
            self = .routines(days)
        case .custom:
            let freq = try container.decode(CustomFrequency.self, forKey: .frequency)
            let values = try container.decode([Int].self, forKey: .values)
            self = .custom(freq, values)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .routines(let days):
            try container.encode(RuleType.routines, forKey: .type)
            try container.encode(days, forKey: .weekdays)
        case .custom(let freq, let values):
            try container.encode(RuleType.custom, forKey: .type)
            try container.encode(freq, forKey: .frequency)
            try container.encode(values, forKey: .values)
        }
    }
}

struct LabelTag: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String = ""
    var time: Date
    var startDate: Date?
    var repeatRule: RepeatRule
    var label: LabelTag?
    var isDone: Bool = false
    var alarmEnabled: Bool = false
    var notificationOffset: Int = 0
}

// MARK: - Color Helpers
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    /// Initialize UIColor from SwiftUI Color safely
    convenience init(_ color: Color) {
        if let cgColor = color.cgColor {
            self.init(cgColor: cgColor)
        } else {
            // Fallback to black if cgColor not available
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }

    /// Convert UIColor to HEX string (#RRGGBB)
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
}

// MARK: - Task Extensions
extension Task {
    var repeatTag: String {
        switch repeatRule {
        case .routines(let days):
            if days == Set(Weekday.allCases) {
                return "Daily"
            } else if days == [.saturday, .sunday] {
                return "Weekend"
            } else if days == [.monday, .tuesday, .wednesday, .thursday, .friday] {
                return "Weekdays"
            } else if days.count == 1 {
                return days.first?.short ?? "Day"
            } else if days.count > 1 {
                let sortedDays = days.sorted { $0.rawValue < $1.rawValue }
                return sortedDays.map(\.short).joined(separator: ", ")
            } else {
                return "Never"
            }

        case .custom(let freq, let values):
            switch freq {
            case .monthly:
                if values.count == 1 {
                    return "Monthly (\(values.first!))"
                } else if values.count > 1 {
                    return "Monthly (\(values.count) days)"
                } else {
                    return "Monthly"
                }
            case .yearly:
                if values.count == 1 {
                    return "Yearly (\(values.first!))"
                } else if values.count > 1 {
                    return "Yearly (\(values.count) years)"
                } else {
                    return "Yearly"
                }
            }
        }
    }
    
    var nextOccurrenceText: String {
        let calendar = Calendar.current
        let now = Date()
        
        switch repeatRule {
        case .routines(let days):
            if days.isEmpty { return "Never" }
            
            // Find next occurrence
            for i in 0...7 {
                let futureDate = calendar.date(byAdding: .day, value: i, to: now)!
                let futureWeekday = Weekday(rawValue: calendar.component(.weekday, from: futureDate)) ?? .sunday
                
                if days.contains(futureWeekday) {
                    if calendar.isDateInToday(futureDate) {
                        return "Today"
                    } else if calendar.isDateInTomorrow(futureDate) {
                        return "Tomorrow"
                    } else {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE"
                        return formatter.string(from: futureDate)
                    }
                }
            }
            return "Next week"
            
        case .custom(let frequency, let values):
            switch frequency {
            case .monthly:
                let currentDay = calendar.component(.day, from: now)
                if let nextDay = values.first(where: { $0 > currentDay }) {
                    return "Day \(nextDay)"
                } else if let firstDay = values.first {
                    return "Next month, day \(firstDay)"
                } else {
                    return "Monthly"
                }
                
            case .yearly:
                return "Yearly"
            }
        }
    }
}

