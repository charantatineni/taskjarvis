//
//  TaskListView.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//
import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var editingTask: Task? = nil
    @State private var selectedTab = 0
    @State private var currentTime = Date()
    @State private var hasScrolledToCurrentTime = false
    
    // Timer to update current time for the time indicator
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    enum TaskFilter {
        case all
        case today
        case daily
        case completed
        case pending
        case futureStart
    }
    
    enum TimeSection: String, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon" 
        case evening = "Evening"
        case night = "Night"
        
        var timeRange: String {
            switch self {
            case .morning: return "12AM - 12PM"
            case .afternoon: return "12PM - 5PM"
            case .evening: return "5PM - 9PM"
            case .night: return "9PM - 12AM"
            }
        }
        
        var hourRange: Range<Int> {
            switch self {
            case .morning: return 0..<12
            case .afternoon: return 12..<17
            case .evening: return 17..<21
            case .night: return 21..<24
            }
        }
        
        var icon: String {
            switch self {
            case .morning: return "sun.and.horizon"
            case .afternoon: return "sun.max"
            case .evening: return "sunset"
            case .night: return "moon.stars"
            }
        }
        
        // Sky-themed colors for time indicators
        var skyColors: [Color] {
            switch self {
            case .morning: return [.yellow.opacity(0.8), .white.opacity(0.9), .blue.opacity(0.3)]
            case .afternoon: return [.white.opacity(0.9), .blue.opacity(0.2), .cyan.opacity(0.4)]
            case .evening: return [.orange.opacity(0.9), .red.opacity(0.6), .purple.opacity(0.4)]
            case .night: return [.black.opacity(0.8), .purple.opacity(0.7), .indigo.opacity(0.5)]
            }
        }
        
        var primarySkyColor: Color {
            switch self {
            case .morning: return .yellow
            case .afternoon: return .blue
            case .evening: return .orange
            case .night: return .purple
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                
                todayTaskListView()
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }
                    .tag(0)
                
                taskListView(filter: .daily)
                    .tabItem {
                        Label("Daily", systemImage: "repeat")
                    }
                    .tag(1)
                
                MonthlyCalendarView(viewModel: viewModel)
                    .tabItem {
                        Label("Monthly", systemImage: "calendar.badge.plus")
                    }
                    .tag(2)
                
                
            }
            
            // Floating Action Button above tab bar
            Button(action: { showingAddTask.toggle() }) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 70) // move above tab bar
            .sheet(isPresented: $showingAddTask) {
                EnhancedAddTaskView(viewModel: viewModel)
            }
            .sheet(item: $editingTask) { task in
                EnhancedAddTaskView(viewModel: viewModel, editTask: task)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            // Reset completed tasks based on their repeat rules
            viewModel.resetCompletedTasksIfNeeded()
        }
        .onAppear {
            currentTime = Date()
            viewModel.resetCompletedTasksIfNeeded()
        }
    }
    
    // Special today view with current date header and auto-scroll
    private func todayTaskListView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Today's date header with progress
                    TodayHeaderView(currentTime: currentTime, tasks: getTodayTasks())
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    // Time-based sections
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(TimeSection.allCases, id: \.self) { section in
                            let sectionTasks = getTasksForSection(section, filter: .today)
                            
                            if !sectionTasks.isEmpty || shouldShowCurrentTimeIndicator(in: section) {
                                Section {
                                    LazyVStack(spacing: 8) {
                                        ForEach(sectionTasks) { task in
                                            TaskRow(task: task, onToggle: {
                                                viewModel.toggleTask(task)
                                            })
                                            .onTapGesture { editingTask = task }
                                            .padding(.horizontal)
                                            .contextMenu {
                                                Button("Edit") { editingTask = task }
                                                Button("Delete", role: .destructive) { 
                                                    viewModel.deleteTask(task)
                                                }
                                            }
                                        }
                                        
                                        // Add current time indicator if needed
                                        if shouldShowCurrentTimeIndicator(in: section) {
                                            CurrentTimeIndicator(currentTime: currentTime, section: section)
                                                .padding(.horizontal)
                                                .padding(.vertical, 4)
                                                .id("currentTime") // For auto-scroll
                                        }
                                    }
                                    .padding(.bottom, 16)
                                } header: {
                                    SectionHeader(section: section)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Auto-scroll to current time section on first load
                if !hasScrolledToCurrentTime {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if shouldShowCurrentTimeIndicator(in: getCurrentTimeSection()) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                proxy.scrollTo("currentTime", anchor: .center)
                            }
                            hasScrolledToCurrentTime = true
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func taskListView(filter: TaskFilter) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(TimeSection.allCases, id: \.self) { section in
                    let sectionTasks = getTasksForSection(section, filter: filter)
                    
                    if !sectionTasks.isEmpty {
                        Section {
                            LazyVStack(spacing: 8) {
                                ForEach(sectionTasks) { task in
                                    TaskRow(task: task, onToggle: {
                                        viewModel.toggleTask(task)
                                    })
                                    .onTapGesture { editingTask = task }
                                    .padding(.horizontal)
                                    .contextMenu {
                                        Button("Edit") { editingTask = task }
                                        Button("Delete", role: .destructive) { 
                                            viewModel.deleteTask(task)
                                        }
                                    }
                                }
                                
                                // Add current time indicator if needed
                                if shouldShowCurrentTimeIndicator(in: section) {
                                    CurrentTimeIndicator(currentTime: currentTime, section: section)
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                }
                            }
                            .padding(.bottom, 16)
                        } header: {
                            SectionHeader(section: section)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func getTasksForSection(_ section: TimeSection, filter: TaskFilter) -> [Task] {
        let filteredTasks = viewModel.filteredTasks(filter: filter)
        let sectionTasks = filteredTasks.filter { task in
            let hour = Calendar.current.component(.hour, from: task.time)
            return section.hourRange.contains(hour)
        }
        
        // Sort tasks by time within each section
        return sectionTasks.sorted { task1, task2 in
            task1.time < task2.time
        }
    }
    
    private func shouldShowCurrentTimeIndicator(in section: TimeSection) -> Bool {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        return section.hourRange.contains(currentHour)
    }
    
    private func getCurrentTimeSection() -> TimeSection {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        return TimeSection.allCases.first { $0.hourRange.contains(currentHour) } ?? .morning
    }
    
    private func getTodayTasks() -> [Task] {
        let calendar = Calendar.current
        let today = Date()
        
        return viewModel.tasks.filter { task in
            // Include tasks that should appear today based on their repeat rule and start date
            guard let startDate = task.startDate else { return false }
            
            // Don't show tasks that haven't started yet
            if startDate > today { return false }
            
            switch task.repeatRule {
            case .routines(let weekdays):
                if weekdays.isEmpty { return false }
                let todayWeekday = Weekday(rawValue: calendar.component(.weekday, from: today)) ?? .sunday
                return weekdays.contains(todayWeekday)
            case .custom(let frequency, let values):
                switch frequency {
                case .monthly:
                    let todayDay = calendar.component(.day, from: today)
                    return values.contains(todayDay)
                case .yearly:
                    let todayYear = calendar.component(.year, from: today)
                    return values.contains(todayYear) || values.isEmpty
                }
            }
        }
    }
}

private var todayDateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    return formatter
}

// MARK: - Today Header View with Progress
struct TodayHeaderView: View {
    let currentTime: Date
    let tasks: [Task]
    
    private var completedCount: Int {
        tasks.filter { $0.isDone }.count
    }
    
    private var progress: Double {
        guard tasks.count > 0 else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }
    
    private var currentSection: TaskListView.TimeSection {
        let hour = Calendar.current.component(.hour, from: currentTime)
        return TaskListView.TimeSection.allCases.first { $0.hourRange.contains(hour) } ?? .morning
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(currentTime, formatter: todayDateFormatter)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tasks.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if completedCount > 0 {
                        Text("\(completedCount) done")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Progress bar
            if tasks.count > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Daily Progress")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))% Complete")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(currentSection.primarySkyColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: currentSection.skyColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 8)
                }
            }
            
            // Quick motivational message based on progress and time
            if tasks.count > 0 {
                HStack {
                    Image(systemName: motivationalIcon)
                        .foregroundColor(currentSection.primarySkyColor)
                    
                    Text(motivationalMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var motivationalIcon: String {
        switch progress {
        case 0.0: return "sun.horizon"
        case 0.1..<0.5: return "sun.and.horizon"
        case 0.5..<0.8: return "sun.max"
        case 0.8..<1.0: return "sunset"
        case 1.0: return "star.fill"
        default: return "sun.horizon"
        }
    }
    
    private var motivationalMessage: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        switch (progress, hour) {
        case (0.0, 5..<12):
            return "Good morning! Ready to tackle today's tasks?"
        case (0.0, 12..<17):
            return "Good afternoon! Time to make progress on your goals."
        case (0.0, 17..<21):
            return "Good evening! Let's wrap up today's important tasks."
        case (0.0, 21...23), (0.0, 0..<5):
            return "It's getting late, but you can still get things done!"
        
        case (0.1..<0.5, _):
            return "Great start! Keep the momentum going."
        case (0.5..<0.8, _):
            return "You're halfway there! Excellent progress."
        case (0.8..<1.0, _):
            return "Almost done! You've got this."
        case (1.0, _):
            return "Perfect! All tasks completed. Well done! 🎉"
        
        default:
            return "Every small step counts. You've got this!"
        }
    }
}

struct SectionHeader: View {
    let section: TaskListView.TimeSection
    
    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundColor(section.primarySkyColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(section.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [section.primarySkyColor.opacity(0.1), section.primarySkyColor.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(section.primarySkyColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct CurrentTimeIndicator: View {
    let currentTime: Date
    let section: TaskListView.TimeSection
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated pulse circle with sky colors
            Circle()
                .fill(
                    RadialGradient(
                        colors: [section.primarySkyColor, section.primarySkyColor.opacity(0.3)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 8
                    )
                )
                .frame(width: 12, height: 12)
                .scaleEffect(1.0 + animationOffset * 0.3)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: animationOffset
                )
            
            // Flowing line with sky-themed gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: section.skyColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .overlay {
                    // Animated shimmer effect
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.9), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: animationOffset * 200)
                        .animation(
                            .linear(duration: 2).repeatForever(autoreverses: false),
                            value: animationOffset
                        )
                }
            
            // Current time display with sky color theme
            Text(currentTime, style: .time)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(section.primarySkyColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(section.primarySkyColor.opacity(0.1), in: Capsule())
            
            Text("NOW")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(section.primarySkyColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(section.primarySkyColor.opacity(0.2), in: Capsule())
        }
        .onAppear {
            animationOffset = 1.0
        }
    }
}

