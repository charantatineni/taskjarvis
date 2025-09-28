//
//  TaskListView.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//
import SwiftUI
import Foundation
import UIKit

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @StateObject private var listViewModel = ListViewModel()
    @State private var showingAddTask = false
    @State private var editingTask: Task? = nil
    @State private var selectedTab = 0
    @State private var currentTime = Date()
    @State private var hasScrolledToCurrentTime = false
    
    // Timer to update current time for the time indicator - reduced frequency
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect() // Update every 5 minutes
    
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
            case .morning: return [.yellow.opacity(0.8), Color.white.opacity(0.9), .blue.opacity(0.3)]
            case .afternoon: return [Color.white.opacity(0.9), .blue.opacity(0.2), .cyan.opacity(0.4)]
            case .evening: return [.orange.opacity(0.9), .red.opacity(0.6), .purple.opacity(0.4)]
            case .night: return [Color.black.opacity(0.8), .purple.opacity(0.7), .indigo.opacity(0.5)]
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
                
                combinedTodayDailyView()
                    .tabItem {
                        Label("Daily Routines", systemImage: "repeat.circle")
                    }
                    .tag(0)
                
                MonthlyCalendarView(viewModel: viewModel)
                    .tabItem {
                        Label("Monthly", systemImage: "calendar.badge.plus")
                    }
                    .tag(1)
                
                ListsMainView(viewModel: listViewModel)
                    .tabItem {
                        Label("Lists", systemImage: "list.bullet.rectangle")
                    }
                    .tag(2)
                
            }
            
            // Floating Action Button - only show on non-lists tabs with red color
            Group {
                if selectedTab != 2 {
                    Button(action: { 
                        showingAddTask.toggle() 
                    }) {
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
                }
            }
            .opacity(selectedTab == 2 ? 0 : 1) // Hide content on Lists tab since it has its own
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
    
    // Simplified Daily Routines view
    private func combinedTodayDailyView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Fixed Header - Today's progress
                    TodayHeaderView(currentTime: currentTime, tasks: getAllRoutines())
                        .padding(.horizontal)
                    
                    // All routines sorted by time with sections
                    LazyVStack(spacing: 8) {
                        let allRoutines = getAllRoutinesSortedByTime()
                        let sectionsWithTasks = getSectionsWithTasks(tasks: allRoutines)
                        
                        ForEach(Array(sectionsWithTasks.enumerated()), id: \.offset) { sectionIndex, sectionData in
                            let (section, sectionTasks) = sectionData
                            
                            // Section header (subtle)
                            TimeSectionHeader(section: section)
                                .padding(.horizontal)
                                .padding(.top, sectionIndex == 0 ? 0 : 16)
                            
                            ForEach(Array(sectionTasks.enumerated()), id: \.element.id) { taskIndex, task in
                                let globalIndex = getGlobalIndex(for: task, in: allRoutines)
                                
                                VStack(spacing: 0) {
                                    // Add time indicator before this task if needed
                                    if shouldShowTimeIndicatorBefore(task: task, allTasks: allRoutines, currentIndex: globalIndex) {
                                        CurrentTimeIndicator(currentTime: currentTime, section: getCurrentTimeSection())
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .id("currentTime")
                                    }
                                    
                                    // Task row with touch handling
                                    SimpleTaskRow(
                                        task: task,
                                        onToggle: { touchPoint in
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                viewModel.toggleTask(task)
                                                // Fetch updated state after toggle to decide on confetti
                                                if let updated = viewModel.tasks.first(where: { $0.id == task.id }), updated.isDone {
                                                    triggerConfetti(at: touchPoint)
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                    .contextMenu {
                                        Button("Edit") { editingTask = task }
                                        Button("Delete", role: .destructive) { 
                                            viewModel.deleteTask(task)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Add time indicator at the end if it's the last position
                        if shouldShowTimeIndicatorAtEnd(allTasks: allRoutines) {
                            CurrentTimeIndicator(currentTime: currentTime, section: getCurrentTimeSection())
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .id("currentTime")
                        }
                    }
                    
                    // Bottom padding for floating action button
                    Spacer(minLength: 100)
                }
            }
            .onAppear {
                // Auto-scroll to current time indicator
                if !hasScrolledToCurrentTime {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            proxy.scrollTo("currentTime", anchor: .center)
                        }
                        hasScrolledToCurrentTime = true
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(confettiOverlay)
    }
    

    private func getAllRoutines() -> [Task] {
        let calendar = Calendar.current
        let now = Date()

        // Helper: compare dates by day only
        func isOnOrBeforeToday(_ date: Date) -> Bool {
            let startOfGiven = calendar.startOfDay(for: date)
            let startOfToday = calendar.startOfDay(for: now)
            return startOfGiven <= startOfToday
        }

        let todayWeekday = Weekday(rawValue: calendar.component(.weekday, from: now)) ?? .sunday
        let todayDay = calendar.component(.day, from: now)
        let todayMonth = calendar.component(.month, from: now)
        let todayYear = calendar.component(.year, from: now)

        return viewModel.tasks.filter { task in
            // Respect start date: do not show tasks that start in the future
            if let sd = task.startDate, !isOnOrBeforeToday(sd) {
                return false
            }

            switch task.repeatRule {
            case .routines(let days):
                if days.isEmpty {
                    // Treat as one-off: show only on startDate == today
                    if let sd = task.startDate {
                        return calendar.isDateInToday(sd)
                    } else {
                        // If no startDate provided, default to showing today
                        return true
                    }
                } else {
                    // Show only if today's weekday is included
                    return days.contains(todayWeekday)
                }

            case .custom(let freq, let values):
                switch freq {
                case .monthly:
                    // Show only if today's day-of-month is included
                    return values.contains(todayDay)

                case .yearly:
                    // Yearly semantics: if values is empty, treat as every year on startDate's month/day
                    // If values contains specific years, include only for those years on the startDate's month/day
                    guard let sd = task.startDate else { return false }
                    let sdMonth = calendar.component(.month, from: sd)
                    let sdDay = calendar.component(.day, from: sd)
                    guard sdMonth == todayMonth && sdDay == todayDay else { return false }
                    if values.isEmpty { return true }
                    return values.contains(todayYear)
                }
            }
        }
    }
    
    private func getAllRoutinesSortedByTime() -> [Task] {
        return getAllRoutines().sorted { task1, task2 in
            let calendar = Calendar.current
            let time1Components = calendar.dateComponents([.hour, .minute], from: task1.time)
            let time2Components = calendar.dateComponents([.hour, .minute], from: task2.time)
            
            let time1Minutes = (time1Components.hour ?? 0) * 60 + (time1Components.minute ?? 0)
            let time2Minutes = (time2Components.hour ?? 0) * 60 + (time2Components.minute ?? 0)
            
            return time1Minutes < time2Minutes
        }
    }
    
    private func shouldShowTimeIndicatorBefore(task: Task, allTasks: [Task], currentIndex: Int) -> Bool {
        let calendar = Calendar.current
        let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentMinutes = (currentTimeComponents.hour ?? 0) * 60 + (currentTimeComponents.minute ?? 0)
        
        let taskTimeComponents = calendar.dateComponents([.hour, .minute], from: task.time)
        let taskMinutes = (taskTimeComponents.hour ?? 0) * 60 + (taskTimeComponents.minute ?? 0)
        
        // Check if current time is before this task
        if currentMinutes < taskMinutes {
            // Check if this is the first task or current time is after the previous task
            if currentIndex == 0 {
                return true
            } else {
                let previousTask = allTasks[currentIndex - 1]
                let previousTimeComponents = calendar.dateComponents([.hour, .minute], from: previousTask.time)
                let previousMinutes = (previousTimeComponents.hour ?? 0) * 60 + (previousTimeComponents.minute ?? 0)
                return currentMinutes > previousMinutes
            }
        }
        
        return false
    }
    
    private func shouldShowTimeIndicatorAtEnd(allTasks: [Task]) -> Bool {
        guard !allTasks.isEmpty else { return false }
        
        let calendar = Calendar.current
        let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentMinutes = (currentTimeComponents.hour ?? 0) * 60 + (currentTimeComponents.minute ?? 0)
        
        let lastTask = allTasks.last!
        let lastTaskTimeComponents = calendar.dateComponents([.hour, .minute], from: lastTask.time)
        let lastTaskMinutes = (lastTaskTimeComponents.hour ?? 0) * 60 + (lastTaskTimeComponents.minute ?? 0)
        
        return currentMinutes > lastTaskMinutes
    }
    
    // Confetti animation state
    @State private var showConfetti = false
    @State private var confettiTrigger = 0
    @State private var confettiOrigin = CGPoint.zero
    
    private func triggerConfetti(at point: CGPoint = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)) {
        confettiOrigin = point
        showConfetti = true
        confettiTrigger += 1
        
        // Hide confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showConfetti = false
        }
    }
    
    private var confettiOverlay: some View {
        ZStack {
            if showConfetti {
                ConfettiView(trigger: confettiTrigger, origin: confettiOrigin)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }
    

    private func getCurrentTimeSection() -> TimeSection {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        return TimeSection.allCases.first { $0.hourRange.contains(currentHour) } ?? .morning
    }
    
    // Helper functions for sections
    private func getSectionsWithTasks(tasks: [Task]) -> [(TimeSection, [Task])] {
        var sectionsWithTasks: [(TimeSection, [Task])] = []
        
        for section in TimeSection.allCases {
            let tasksInSection = tasks.filter { task in
                let hour = Calendar.current.component(.hour, from: task.time)
                return section.hourRange.contains(hour)
            }
            
            if !tasksInSection.isEmpty {
                sectionsWithTasks.append((section, tasksInSection))
            }
        }
        
        return sectionsWithTasks
    }
    
    private func getGlobalIndex(for task: Task, in allTasks: [Task]) -> Int {
        return allTasks.firstIndex(where: { $0.id == task.id }) ?? 0
    }
    

}

// MARK: - Simple Task Row (No repeat icons)
struct SimpleTaskRow: View {
    let task: Task
    let onToggle: (CGPoint) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .secondary : .primary)
                
                HStack {
                    Text(task.time, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !task.description.isEmpty {
                        Text("• \(task.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let label = task.label {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(listHex: label.colorHex))
                            .frame(width: 6, height: 6)
                        Text(label.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.nextOccurrenceText)
                    .font(.caption2)
                    .foregroundColor(Color.accentColor)
                    .fontWeight(.medium)
                
                if task.isDone {
                    Text("✓ Done")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
        }
        .contentShape(Rectangle())
        .overlay(
            DoubleTapCapture { point in
                onToggle(point)
            }
        )
        .padding()
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
    }
    
    private var gradientColors: [Color] {
        if task.isDone {
            return [Color.green.opacity(0.6), Color.green.opacity(0.3)]
        } else if let label = task.label {
            let c = Color(listHex: label.colorHex)
            return [c.opacity(0.8), c.opacity(0.4)]
        }
        return [Color(.systemGray).opacity(0.3), Color(.systemGray).opacity(0.1)]
    }
}

// MARK: - Double Tap Capture (UIKit-backed)
struct DoubleTapCapture: UIViewRepresentable {
    var onDoubleTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        recognizer.numberOfTapsRequired = 2
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleTap: onDoubleTap)
    }

    class Coordinator: NSObject {
        let onDoubleTap: (CGPoint) -> Void
        init(onDoubleTap: @escaping (CGPoint) -> Void) { self.onDoubleTap = onDoubleTap }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            // Location in window coordinates (nil -> window), aligns with .global
            let pointInWindow = recognizer.location(in: nil)
            onDoubleTap(pointInWindow)
        }
    }
}

// MARK: - Confetti Animation View
struct ConfettiView: View {
    let trigger: Int
    let origin: CGPoint
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    ConfettiPiece(
                        geometry: geometry,
                        trigger: trigger,
                        delay: Double.random(in: 0...0.05),
                        origin: origin
                    )
                }
            }
        }
    }
}

struct ConfettiPiece: View {
    let geometry: GeometryProxy
    let trigger: Int
    let delay: Double
    let origin: CGPoint
    
    @State private var isAnimating = false
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    @State private var position: CGPoint = .zero
    @State private var offset: CGSize = .zero
    
    private let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
    
    private let shapes = ["circle.fill", "diamond.fill", "star.fill", "heart.fill"]
    
    var body: some View {
        Image(systemName: shapes.randomElement() ?? "star.fill")
            .font(.system(size: CGFloat.random(in: 8...16)))
            .foregroundColor(colors.randomElement() ?? .blue)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .offset(offset)
            .onAppear {
                setupInitialPosition()
                startAnimation()
            }
            .onChange(of: trigger) { _ in
                startAnimation()
            }
    }
    
    private func setupInitialPosition() {
        // Convert global tap location (window coords) to this GeometryReader's local space
        let frame = geometry.frame(in: .global)
        let localX = origin.x - frame.minX
        let localY = origin.y - frame.minY
        position = CGPoint(x: localX, y: localY)
        offset = .zero
    }
    
    private func startAnimation() {
        // Reset state
        isAnimating = false
        opacity = 1.0
        rotation = 0
        setupInitialPosition()
        
        // Start animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.8)) {
                // Explode outward from the origin
                let angle = Double.random(in: 0...(2 * Double.pi))
                let velocity = CGFloat.random(in: 80...160)
                
                // Quick radial burst with minimal drift
                let radialX = cos(angle) * velocity
                let radialY = sin(angle) * velocity
                let driftX = CGFloat.random(in: -10...10)
                let driftY = CGFloat.random(in: -10...10)
                
                offset = CGSize(width: radialX + driftX, height: radialY + driftY)
                
                // Rotate
                rotation = Double.random(in: 180...360)
                
                // Fade out towards the end
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                }
            }
            
            isAnimating = true
        }
    }
}



// MARK: - Today Header View (Updated for Daily Routines)
struct TodayHeaderView: View {
    let currentTime: Date
    let tasks: [Task]
    
    private var todayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }
    
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
                    Text("Daily Routines")
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
                    Text("routines")
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
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            return "Good morning! Ready to tackle your routines?"
        case (0.0, 12..<17):
            return "Good afternoon! Time to stay consistent with your habits."
        case (0.0, 17..<21):
            return "Good evening! Let's maintain our daily discipline."
        case (0.0, 21...23), (0.0, 0..<5):
            return "Night routines are just as important!"
        
        case (0.1..<0.5, _):
            return "Great momentum! Keep building those habits."
        case (0.5..<0.8, _):
            return "Halfway there! Consistency is key."
        case (0.8..<1.0, _):
            return "Almost perfect! You're crushing it."
        case (1.0, _):
            return "Perfect day! All routines completed! 🎉"
        
        default:
            return "Every routine matters. You've got this!"
        }
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
                                colors: [.clear, Color.white.opacity(0.9), .clear],
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
            
            // Current time display without "Modified" label
            VStack(alignment: .leading, spacing: 2) {
                Text(currentTime, style: .time)
                    .font(.caption2)
                    .foregroundColor(section.primarySkyColor)
            }
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

// MARK: - Time Section Header (Subtle)
struct TimeSectionHeader: View {
    let section: TaskListView.TimeSection
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.caption)
                    .foregroundColor(section.primarySkyColor)
                    .opacity(0.7)
                
                Text(section.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(section.timeRange)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            Spacer()
            
            // Subtle decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            section.primarySkyColor.opacity(0.3),
                            section.primarySkyColor.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .frame(maxWidth: 100)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

