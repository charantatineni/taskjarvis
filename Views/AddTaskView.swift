//
//  AddTaskView.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//
import SwiftUI

struct AddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TaskViewModel
    
    var editTask: Task? = nil
    
    @State private var title: String = ""
    @State private var time: Date = Date()
    @State private var repeatRule: RepeatRule = .routines(Set(Weekday.allCases))
    @State private var alarmEnabled: Bool = true
    @State private var notificationOffset: Int = 0
    @State private var description: String = ""
    @State private var selectedWeekdays: Set<Weekday> = Set(Weekday.allCases)
    @State private var startDate: Date = Date()
    @State private var selectedLabel: LabelTag? = nil
    @State private var customFrequency: CustomFrequency = .monthly
    @State private var customValues: [Int] = [] // days-of-month or years depending on freq
    @State private var showNewLabelSheet = false
    @State private var newLabelName = ""
    @State private var newLabelColor = Color.red
    @State private var showCalendar = false
    @State private var customMonths: [Int] = [] // Jan=1, Feb=2
    @State private var customDays: [Int] = []
    
    // map segmented index <-> RepeatRule
    private var repeatRuleBinding: Binding<Int> {
        Binding {
            switch repeatRule {
            case .routines: return 0
            case .custom: return 1
            }
        } set: { idx in
            switch idx {
            case 0: repeatRule = .routines(selectedWeekdays)
            default: repeatRule = .custom(customFrequency, customValues)
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
                _repeatRule = State(initialValue: task.repeatRule)
                _selectedLabel = State(initialValue: task.label)
                _alarmEnabled = State(initialValue: task.alarmEnabled)
                _notificationOffset = State(initialValue: task.notificationOffset)

                if case let .routines(days) = task.repeatRule {
                    _selectedWeekdays = State(initialValue: days)
                }
                if case let .custom(freq, values) = task.repeatRule {
                    _customFrequency = State(initialValue: freq)
                    _customValues = State(initialValue: values)
                }
            }
        }
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack(spacing: 20) {
                    // Task Title
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
                        
                        TextField("Enter description", text: $description, axis: .vertical) // 👈 add this new state var
                            .font(.subheadline)
                            .lineLimit(3, reservesSpace: true)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
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
                    .sheet(isPresented: $showNewLabelSheet) {
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
                                        viewModel.labels.append(tag)
                                        selectedLabel = tag
                                        showNewLabelSheet = false
                                    }
                                }
                                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showNewLabelSheet = false } }
                            }
                        }
                    }
                    
                    // Time
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: { showCalendar.toggle() }) {
                            HStack {
                                let rel = relativeDay(startDate)
                                Text(rel.isEmpty ? formattedDate(startDate) : "\(formattedDate(startDate)) (\(rel))") // shows selected date
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
                    
                    // Repeat Rule
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repeat").font(.caption).foregroundColor(.secondary)

                        // first choose mode
                        Picker("Mode", selection: repeatRuleBinding) {
                            Text("Routines").tag(0)   // was "Daily"
                            Text("Custom").tag(1)
                        }
                        .pickerStyle(.segmented)

                        // If routines → weekday multi-select
                        if case .routines = repeatRule {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    let isOn = selectedWeekdays.contains(day)
                                    Button {
                                        if isOn { selectedWeekdays.remove(day) } else { selectedWeekdays.insert(day) }
                                    } label: {
                                        Text(day.short)
                                            .font(.caption)
                                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                                            .background(isOn ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        // If custom → frequency + values
                        if case .custom = repeatRule {
                            Picker("Frequency", selection: $customFrequency) {
                                ForEach(CustomFrequency.allCases, id: \.self) { f in
                                    Text(f.rawValue.capitalized).tag(f)
                                }
                            }
                            .pickerStyle(.segmented)

                            if customFrequency == .monthly {
                                Text("Months").font(.caption2).foregroundColor(.secondary)
                                ChipsStringPicker(selected: $customMonths, items: Calendar.current.shortMonthSymbols)

                                Text("Days of month (1–31)").font(.caption2).foregroundColor(.secondary)
                                ChipsNumberPicker(selected: $customDays, range: 1...31)
                            }
                            else if customFrequency == .yearly {
                                Text("Years").font(.caption2).foregroundColor(.secondary)
                                ChipsNumberPicker(selected: $customValues, range: 2025...2035)
                            } // quarterly/halfYearly don’t need manual values
                        }
                    }

                    
                    // Reminders
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Enable Alarm Sound", isOn: $alarmEnabled)
                        
                        Stepper("Notify \(notificationOffset) mins before",
                                value: $notificationOffset, in: 0...60)
                    }
//                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle(editTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // normalize repeatRule from UI selections
                        let normalizedRepeat: RepeatRule = {
                            switch repeatRule {
                            case .routines: return .routines(selectedWeekdays)
                            case .custom: return .custom(customFrequency, customMonths + customDays)
                            }
                        }()

                        if let task = editTask {
                            viewModel.updateTask(task,
                                                 title: title,
                                                 description: description,
                                                 time: time,
                                                 repeatRule: normalizedRepeat,
                                                 alarmEnabled: alarmEnabled,
                                                 notificationOffset: notificationOffset,
                                                 startDate: startDate,
                                                 label: selectedLabel)
                        } else {
                            viewModel.addTask(title: title,
                                              description: description,
                                              time: time,
                                              repeatRule: normalizedRepeat,
                                              alarmEnabled: alarmEnabled,
                                              notificationOffset: notificationOffset,
                                              startDate: startDate,
                                              label: selectedLabel)
                        }
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
}

struct ChipsStringPicker: View {
    @Binding var selected: [Int]
    let items: [String]   // ["Jan", "Feb", ...]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { idx in
                    let on = selected.contains(idx + 1)
                    Button {
                        if on {
                            selected.removeAll { $0 == idx + 1 }
                        } else {
                            selected.append(idx + 1)
                        }
                    } label: {
                        Text(items[idx])
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(on ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}
struct ChipsNumberPicker: View {
    @Binding var selected: [Int]
    let numbers: [Int]

    init(selected: Binding<[Int]>, range: ClosedRange<Int>) {
        self._selected = selected
        self.numbers = Array(range)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(numbers, id: \.self) { n in
                    let on = selected.contains(n)
                    Button {
                        if on {
                            selected.removeAll { $0 == n }
                        } else {
                            selected.append(n)
                        }
                    } label: {
                        Text("\(n)")
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(on ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}


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
    f.dateFormat = "EEEE" // full day name
    return f
}
