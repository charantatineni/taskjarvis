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
    @State private var selectedMonthlyDates: Set<Int> = []
    @State private var showingMonthlyDatePicker = false
    
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
                        .foregroundColor(Color.accentColor)
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
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(Color.accentColor)
                                .frame(width: 20)
                            
                            Text(option.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if repeatType == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle()) // Makes entire cell tappable
                        .onTapGesture {
                            repeatType = option
                            if option == .never {
                                showRepeatOptions = false
                            } else if option == .weekly {
                                // Pre-populate with current weekday if none selected
                                if selectedWeekdays.isEmpty {
                                    let weekday = Weekday(rawValue: Calendar.current.component(.weekday, from: startDate)) ?? .monday
                                    selectedWeekdays.insert(weekday)
                                }
                            }
                        }
                    }
                }
                
                // Enhanced custom options based on selected repeat type
                if repeatType == .custom {
                    customIntervalSection
                    specificDaysOfWeekSection
                    specificDaysOfMonthSection
                } else if repeatType == .weekly {
                    weekdaySelectionSection
                } else if repeatType == .biweekly {
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
    
    private var customIntervalSection: some View {
        Section("Custom Interval") {
            Stepper("Every \(customInterval) day\(customInterval == 1 ? "" : "s")",
                   value: $customInterval, in: 1...365)
        }
    }
    
    private var specificDaysOfWeekSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.day.timeline.left")
                        .foregroundColor(Color.accentColor)
                    Text("Specific Days of Week")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Text("Select which days of the week this task should repeat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                            VStack(spacing: 4) {
                                Text(day.short)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                Circle()
                                    .fill(isSelected ? Color.accentColor : Color(.systemGray4))
                                    .frame(width: 8, height: 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if selectedWeekdays.isEmpty {
                    Text("Select at least one day")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var specificDaysOfMonthSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(Color.accentColor)
                    Text("Specific Days of Month")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                    
                    Button(action: {
                        showingMonthlyDatePicker.toggle()
                    }) {
                        Text("Select Dates")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Text("Choose specific dates each month when this task should repeat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if selectedMonthlyDates.isEmpty {
                    Text("No dates selected")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedMonthlyDates).sorted(), id: \.self) { date in
                                VStack(spacing: 4) {
                                    Text("\(date)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(dateOrdinal(date))
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(width: 50, height: 50)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    Button(action: {
                                        selectedMonthlyDates.remove(date)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .background(Color.accentColor, in: Circle())
                                    }
                                    .offset(x: 18, y: -18)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingMonthlyDatePicker) {
            MonthlyDatePickerView(selectedDates: $selectedMonthlyDates)
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
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
            
            if selectedWeekdays.isEmpty {
                Text("Select at least one day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
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
            if selectedWeekdays.isEmpty {
                let day = Calendar.current.component(.weekday, from: startDate)
                let weekdayName = Calendar.current.weekdaySymbols[day - 1]
                return "Every \(weekdayName)"
            } else {
                let days = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                return "Weekly on " + days.map(\.short).joined(separator: ", ")
            }
        case .biweekly:
            if selectedWeekdays.isEmpty {
                return "Every 2 weeks"
            } else {
                let days = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                return "Bi-weekly on " + days.map(\.short).joined(separator: ", ")
            }
        case .monthly:
            return monthlyRepeatDescription
        case .yearly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return "Every \(formatter.string(from: startDate))"
        case .custom:
            if !selectedWeekdays.isEmpty {
                let days = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                return "Weekly: " + days.map(\.short).joined(separator: ", ")
            } else if !selectedMonthlyDates.isEmpty {
                let dates = Array(selectedMonthlyDates).sorted()
                if dates.count <= 3 {
                    return "Monthly: " + dates.map(String.init).joined(separator: ", ")
                } else {
                    return "Monthly: \(dates.count) dates"
                }
            } else {
                return "Every \(customInterval) day\(customInterval == 1 ? "" : "s")"
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
            if selectedWeekdays.isEmpty {
                let weekday = Weekday(rawValue: Calendar.current.component(.weekday, from: startDate)) ?? .monday
                return .routines([weekday])
            } else {
                return .routines(selectedWeekdays)
            }
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
            if !selectedWeekdays.isEmpty {
                return .routines(selectedWeekdays)
            } else if !selectedMonthlyDates.isEmpty {
                return .custom(.monthly, Array(selectedMonthlyDates).sorted())
            } else {
                return .routines(Set(Weekday.allCases))
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
                return .weekly // Changed from .custom to .weekly for multiple day selection
            }
        case .custom(let frequency, let values):
            switch frequency {
            case .monthly:
                if values.count > 1 {
                    selectedMonthlyDates = Set(values)
                    return .custom
                } else {
                    return .monthly
                }
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
    
    private func dateOrdinal(_ day: Int) -> String {
        return "\(day)\(ordinalSuffix(for: day))"
    }
}

// MARK: - Monthly Date Picker View
struct MonthlyDatePickerView: View {
    @Binding var selectedDates: Set<Int>
    @Environment(\.presentationMode) var presentationMode
    
    private let daysInMonth = Array(1...31)
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Select dates when your task should repeat each month")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(daysInMonth, id: \.self) { day in
                            let isSelected = selectedDates.contains(day)
                            
                            Button(action: {
                                if isSelected {
                                    selectedDates.remove(day)
                                } else {
                                    selectedDates.insert(day)
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(day)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(isSelected ? .white : .primary)
                                    
                                    Text(dateOrdinal(day))
                                        .font(.caption2)
                                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                }
                                .frame(width: 45, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
                                )
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    
                    if !selectedDates.isEmpty {
                        VStack(spacing: 8) {
                            Text("Selected: \(selectedDates.count) date\(selectedDates.count == 1 ? "" : "s")")
                                .font(.headline)
                            
                            Text(selectedDates.sorted().map { "\($0)" }.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding()
                    }
                }
            }
            .navigationTitle("Monthly Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func dateOrdinal(_ day: Int) -> String {
        let suffix: String
        switch day % 100 {
        case 11...13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(day)\(suffix)"
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

