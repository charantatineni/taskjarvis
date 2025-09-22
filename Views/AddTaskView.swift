import SwiftUI
import Foundation

// Enhanced Repeat Rule for better scheduling
enum SmartRepeatRule: Codable, CaseIterable {
    case never
    case daily
    case weekdays // Mon-Fri
    case weekly
    case biweekly
    case monthly
    case yearly
    case custom
    
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays (Mon-Fri)"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .never: return "minus.circle"
        case .daily: return "repeat"
        case .weekdays: return "briefcase"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar.badge.plus"
        case .monthly: return "calendar"
        case .yearly: return "calendar.badge.exclamationmark"
        case .custom: return "slider.horizontal.3"
        }
    }
}

struct EnhancedAddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TaskViewModel
    
    var editTask: Task? = nil
    
    // Basic task properties
    @State private var title: String = ""
    @State private var time: Date = Date()
    @State private var alarmEnabled: Bool = true
    @State private var notificationOffset: Int = 0
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var selectedLabel: LabelTag? = nil
    @State private var showNewLabelSheet = false
    @State private var newLabelName = ""
    @State private var newLabelColor = Color.red
    @State private var showCalendar = false
    
    // Enhanced repeat options
    @State private var repeatType: SmartRepeatRule = .never
    @State private var showRepeatOptions = false
    @State private var customInterval: Int = 1
    @State private var selectedWeekdays: Set<Weekday> = []
    @State private var monthlyOption: MonthlyRepeatType = .dayOfMonth
    @State private var endRepeatOption: EndRepeatType = .never
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var occurrenceCount: Int = 10
    
    enum MonthlyRepeatType: CaseIterable {
        case dayOfMonth // e.g., "Monthly on day 15"
        case weekdayOfMonth // e.g., "Monthly on the 2nd Tuesday"
        
        var displayName: String {
            switch self {
            case .dayOfMonth: return "On day of month"
            case .weekdayOfMonth: return "On the same weekday"
            }
        }
    }
    
    enum EndRepeatType: CaseIterable {
        case never
        case on
        case after
        
        var displayName: String {
            switch self {
            case .never: return "Never"
            case .on: return "On date"
            case .after: return "After"
            }
        }
    }

    init(viewModel: TaskViewModel, editTask: Task? = nil) {
        self.viewModel = viewModel
        self.editTask = editTask

        if let task = editTask {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _time = State(initialValue: task.time)
            _startDate = State(initialValue: task.startDate ?? Date())
            _selectedLabel = State(initialValue: task.label)
            _alarmEnabled = State(initialValue: task.alarmEnabled)
            _notificationOffset = State(initialValue: task.notificationOffset)
            
            // Convert existing RepeatRule to SmartRepeatRule and extract weekdays if needed
            let smartRule = convertToSmartRepeatRule(task.repeatRule)
            _repeatType = State(initialValue: smartRule)
            
            // Extract weekdays for custom/weekly rules
            if case .routines(let days) = task.repeatRule {
                _selectedWeekdays = State(initialValue: days)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Removed NavLogoView here as prominent logo at top
                    
                    // Task Title & Description
                    taskBasicInfo
                    
                    // Label Selection
                    labelSection
                    
                    // Time Selection
                    timeSection
                    
                    // Start Date
                    startDateSection
                    
                    // Repeat Options (Enhanced)
                    repeatSection
                    
                    // Reminder Options
                    reminderSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle(editTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTask() }
                        .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showNewLabelSheet) { newLabelSheet }
        .sheet(isPresented: $showRepeatOptions) { repeatOptionsSheet }
    }
    
    // MARK: - UI Components
    
    private var taskBasicInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task Title")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Enter title", text: $title)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            
            Text("Description")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Enter description", text: $description, axis: .vertical)
                .font(.subheadline)
                .lineLimit(3, reservesSpace: true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }
    
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label")
                .font(.caption).foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.labels) { tag in
                        let color = Color(hex: tag.colorHex) ?? .gray
                        Button {
                            selectedLabel = (selectedLabel == tag) ? nil : tag
                        } label: {
                            HStack(spacing: 6) {
                                Circle().fill(color).frame(width: 8, height: 8)
                                Text(tag.name).font(.subheadline)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background( (selectedLabel == tag) ? color.opacity(0.2) : Color(.secondarySystemBackground) )
                            .cornerRadius(10)
                        }
                    }

                    Button {
                        showNewLabelSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                }
            }
        }
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time")
                .font(.caption)
                .foregroundColor(.secondary)
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(maxWidth: .infinity, maxHeight: 120)
                .clipped()
        }
    }
    
    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Date")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: { showCalendar.toggle() }) {
                HStack {
                    let rel = relativeDay(startDate)
                    Text(rel.isEmpty ? formattedDate(startDate) : "\(formattedDate(startDate)) (\(rel))")
                    Spacer()
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            Text(startDate, formatter: weekdayFormatter)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if showCalendar {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .frame(maxHeight: 350)
            }
        }
    }
    
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Make the entire field clickable
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: repeatType.icon)
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(repeatType.displayName)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        if repeatType != .never {
                            Text(repeatSummary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            .contentShape(Rectangle()) // Makes entire area tappable
            .onTapGesture {
                showRepeatOptions = true
            }
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders & Notifications")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // Notification timing
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notification Alert")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Stepper("Notify \(notificationOffset) minute\(notificationOffset == 1 ? "" : "s") before",
                            value: $notificationOffset, in: 0...60)
                    
                    Text(notificationOffset == 0 ? 
                         "Banner notification will appear exactly at task time with title and description" : 
                         "Banner notification will appear \(notificationOffset) minute\(notificationOffset == 1 ? "" : "s") early")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
                
                // Alarm sound toggle
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alarm Sound")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Toggle("Enable 3-second alarm sound", isOn: $alarmEnabled)
                    
                    Text("Plays a 3-second alarm tone from device speaker when notification appears")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Repeat Options Sheet
    
    private var repeatOptionsSheet: some View {
        NavigationView {
            List {
                Section {
                    ForEach(SmartRepeatRule.allCases, id: \.self) { option in
                        Button(action: {
                            repeatType = option
                            if option == .never {
                                showRepeatOptions = false
                            }
                        }) {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                
                                Text(option.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if repeatType == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Custom options based on selected repeat type
                if repeatType == .custom {
                    customRepeatSection
                    // Always show weekday selection for custom
                    weekdaySelectionSection
                } else if repeatType == .weekly || repeatType == .biweekly {
                    weekdaySelectionSection
                }
                
                if repeatType == .monthly {
                    monthlyOptionsSection
                }
                
                if repeatType != .never {
                    endRepeatSection
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showRepeatOptions = false }
                }
            }
        }
    }
    
    private var customRepeatSection: some View {
        Section("Custom Interval") {
            Stepper("Every \(customInterval) day\(customInterval == 1 ? "" : "s")",
                   value: $customInterval, in: 1...365)
        }
    }
    
    private var weekdaySelectionSection: some View {
        Section("Repeat on") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    let isSelected = selectedWeekdays.contains(day)
                    Button(action: {
                        if isSelected {
                            selectedWeekdays.remove(day)
                        } else {
                            selectedWeekdays.insert(day)
                        }
                    }) {
                        Text(day.short)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var monthlyOptionsSection: some View {
        Section("Monthly repeat") {
            Picker("Monthly Option", selection: $monthlyOption) {
                ForEach(MonthlyRepeatType.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            
            Text(monthlyRepeatDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    private var endRepeatSection: some View {
        Section("End repeat") {
            Picker("End Option", selection: $endRepeatOption) {
                ForEach(EndRepeatType.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            
            switch endRepeatOption {
            case .on:
                DatePicker("End date", selection: $endDate, displayedComponents: .date)
            case .after:
                Stepper("After \(occurrenceCount) occurrence\(occurrenceCount == 1 ? "" : "s")",
                       value: $occurrenceCount, in: 1...999)
            case .never:
                EmptyView()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var repeatSummary: String {
        switch repeatType {
        case .never:
            return ""
        case .daily:
            return "Every day"
        case .weekdays:
            return "Monday to Friday"
        case .weekly:
            let day = Calendar.current.component(.weekday, from: startDate)
            let weekdayName = Calendar.current.weekdaySymbols[day - 1]
            return "Every \(weekdayName)"
        case .biweekly:
            return "Every 2 weeks"
        case .monthly:
            return monthlyRepeatDescription
        case .yearly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return "Every \(formatter.string(from: startDate))"
        case .custom:
            if selectedWeekdays.isEmpty {
                return "Every \(customInterval) day\(customInterval == 1 ? "" : "s")"
            } else {
                let days = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                return days.map(\.short).joined(separator: ", ")
            }
        }
    }
    
    private var monthlyRepeatDescription: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: startDate)
        
        switch monthlyOption {
        case .dayOfMonth:
            let suffix = ordinalSuffix(for: day)
            return "Monthly on the \(day)\(suffix)"
        case .weekdayOfMonth:
            let weekday = calendar.component(.weekday, from: startDate)
            let weekOfMonth = calendar.component(.weekOfMonth, from: startDate)
            let weekdayName = calendar.weekdaySymbols[weekday - 1]
            let weekSuffix = ordinalSuffix(for: weekOfMonth)
            return "Monthly on the \(weekOfMonth)\(weekSuffix) \(weekdayName)"
        }
    }
    
    // MARK: - Sheet Components
    
    private var newLabelSheet: some View {
        NavigationView {
            Form {
                TextField("Label name", text: $newLabelName)
                ColorPicker("Color", selection: $newLabelColor)
            }
            .navigationTitle("New Label")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !newLabelName.isEmpty else { return }
                        let hex = UIColor(newLabelColor).toHexString()
                        let tag = LabelTag(id: UUID(), name: newLabelName, colorHex: hex)
                        viewModel.addLabel(tag)
                        selectedLabel = tag
                        showNewLabelSheet = false
                        newLabelName = ""
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showNewLabelSheet = false
                        newLabelName = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveTask() {
        let convertedRepeatRule = convertToRepeatRule()
        
        if let task = editTask {
            viewModel.updateTask(task,
                               title: title,
                               description: description,
                               time: time,
                               repeatRule: convertedRepeatRule,
                               alarmEnabled: alarmEnabled,
                               notificationOffset: notificationOffset,
                               startDate: startDate,
                               label: selectedLabel)
        } else {
            viewModel.addTask(title: title,
                            description: description,
                            time: time,
                            repeatRule: convertedRepeatRule,
                            alarmEnabled: alarmEnabled,
                            notificationOffset: notificationOffset,
                            startDate: startDate,
                            label: selectedLabel)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func convertToRepeatRule() -> RepeatRule {
        switch repeatType {
        case .never:
            return .routines([])
        case .daily:
            return .routines(Set(Weekday.allCases))
        case .weekdays:
            return .routines([.monday, .tuesday, .wednesday, .thursday, .friday])
        case .weekly:
            let weekday = Weekday(rawValue: Calendar.current.component(.weekday, from: startDate)) ?? .monday
            return .routines([weekday])
        case .biweekly:
            if selectedWeekdays.isEmpty {
                let weekday = Weekday(rawValue: Calendar.current.component(.weekday, from: startDate)) ?? .monday
                return .routines([weekday])
            } else {
                return .routines(selectedWeekdays)
            }
        case .monthly:
            let day = Calendar.current.component(.day, from: startDate)
            return .custom(.monthly, [day])
        case .yearly:
            let year = Calendar.current.component(.year, from: startDate)
            return .custom(.yearly, [year])
        case .custom:
            if selectedWeekdays.isEmpty {
                return .routines(Set(Weekday.allCases))
            } else {
                return .routines(selectedWeekdays)
            }
        }
    }
    
    private func convertToSmartRepeatRule(_ repeatRule: RepeatRule) -> SmartRepeatRule {
        switch repeatRule {
        case .routines(let days):
            if days.isEmpty {
                return .never
            } else if days == Set(Weekday.allCases) {
                return .daily
            } else if days == [.monday, .tuesday, .wednesday, .thursday, .friday] {
                return .weekdays
            } else if days.count == 1 {
                return .weekly
            } else {
                selectedWeekdays = days
                return .custom
            }
        case .custom(let frequency, _):
            switch frequency {
            case .monthly:
                return .monthly
            case .yearly:
                return .yearly
            }
        }
    }
    
    private func ordinalSuffix(for number: Int) -> String {
        let suffix: String
        switch number % 100 {
        case 11...13: suffix = "th"
        default:
            switch number % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return suffix
    }
}

// MARK: - Helper Functions (Global)

private func relativeDay(_ date: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(date) { return "Today" }
    if cal.isDateInTomorrow(date) { return "Tomorrow" }
    if cal.isDateInYesterday(date) { return "Yesterday" }
    return ""
}

private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

private var weekdayFormatter: DateFormatter {
    let f = DateFormatter()
    f.dateFormat = "EEEE"
    return f
}

