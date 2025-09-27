import SwiftUI

import SwiftUI

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var selectedDateTasks: [Task] = []
    @State private var showingDayDetails = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month Header
                monthHeader
                
                // Calendar Grid
                calendarGrid
                
                // Selected Day Details (Expandable)
                if showingDayDetails && !selectedDateTasks.isEmpty {
                    dayDetailsSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .navigationTitle("Monthly Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color.accentColor)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Week day headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(generateCalendarDays(), id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        taskCount: getTaskCount(for: date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedDate = date
                            selectedDateTasks = getTasksForDate(date)
                            showingDayDetails = !selectedDateTasks.isEmpty
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Day Details Section
    private var dayDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate, formatter: dayDetailFormatter)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("\(selectedDateTasks.count) task\(selectedDateTasks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingDayDetails = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tasks for selected date
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(selectedDateTasks.sorted(by: { $0.time < $1.time })) { task in
                        DayDetailTaskRow(task: task) {
                            viewModel.toggleTask(task)
                            // Update the tasks after toggling
                            selectedDateTasks = getTasksForDate(selectedDate)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func generateCalendarDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let lastOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)!
        
        // Find the first day of the week containing the first of the month
        let firstDayWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstDayWeekday - calendar.firstWeekday + 7) % 7
        
        // Find the last day of the week containing the last of the month
        let lastDayWeekday = calendar.component(.weekday, from: lastOfMonth)
        let daysFromNextMonth = (calendar.firstWeekday + 6 - lastDayWeekday) % 7
        
        // Create date range including previous and next month days
        let startDate = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: firstOfMonth)!
        let endDate = calendar.date(byAdding: .day, value: daysFromNextMonth, to: lastOfMonth)!
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    private func getTaskCount(for date: Date) -> Int {
        return getTasksForDate(date).count
    }
    
    private func getTasksForDate(_ date: Date) -> [Task] {
        return viewModel.tasks.filter { task in
            guard let startDate = task.startDate else { return false }
            
            // Don't show tasks that haven't started yet
            if startDate > date { return false }
            
            switch task.repeatRule {
            case .routines(let weekdays):
                if weekdays.isEmpty { return false }
                let dateWeekday = Weekday(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
                return weekdays.contains(dateWeekday)
            case .custom(let frequency, let values):
                switch frequency {
                case .monthly:
                    let dateDay = calendar.component(.day, from: date)
                    return values.contains(dateDay)
                case .yearly:
                    let dateYear = calendar.component(.year, from: date)
                    return values.contains(dateYear) || values.isEmpty
                }
            }
        }
    }
}

// MARK: - Calendar Day View (GitHub-style with themed filled squares)
struct CalendarDayView: View {
    let date: Date
    let taskCount: Int
    let isCurrentMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    
    private var intensity: Double {
        switch taskCount {
        case 0: return 0.0
        case 1: return 0.3
        case 2: return 0.5
        case 3: return 0.7
        default: return 1.0
        }
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    // Get the appropriate theme based on the primary task time or current time
    private var dominantTimeTheme: TaskListView.TimeSection {
        // For simplicity, we'll use the current hour to determine theme
        // In a more sophisticated version, you'd analyze the actual task times
        let hour = Calendar.current.component(.hour, from: Date())
        return TaskListView.TimeSection.allCases.first { $0.hourRange.contains(hour) } ?? .morning
    }
    
    var body: some View {
        ZStack {
            // Background square with theme-based color intensity
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColorWithIntensity)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
            
            // Day number text
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(textColor)
                .shadow(color: shadowColor, radius: shadowIntensity, x: 0, y: 1)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .shadow(
            color: isSelected ? dominantTimeTheme.primarySkyColor.opacity(0.3) : .clear,
            radius: isSelected ? 8 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private var backgroundColorWithIntensity: Color {
        if !isCurrentMonth {
            return Color(.systemGray6)
        } else if taskCount == 0 {
            return Color(.systemGray5)
        } else {
            // Use the dominant time theme with intensity
            return dominantTimeTheme.primarySkyColor.opacity(intensity)
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if taskCount == 0 {
            return .primary
        } else if intensity > 0.5 {
            // High intensity background needs white text
            return .white
        } else {
            return .primary
        }
    }
    
    private var shadowColor: Color {
        if taskCount > 0 && intensity > 0.3 {
            return .black.opacity(0.3)
        }
        return .clear
    }
    
    private var shadowIntensity: CGFloat {
        intensity > 0.5 ? 1 : 0
    }
}

// MARK: - Day Detail Task Row
struct DayDetailTaskRow: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(task.time, style: .time)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Task info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .secondary : .primary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let label = task.label, let color = Color(hex: label.colorHex) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                        Text(label.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Toggle button
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isDone ? .green : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Date Formatters
private let dayDetailFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    return formatter
}()
