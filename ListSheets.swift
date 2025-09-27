import SwiftUI

// MARK: - Add List Sheet
struct AddListSheet: View {
    @ObservedObject var viewModel: ListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var listTitle = ""
    @State private var selectedGroup: ListGroup?
    @State private var selectedColor = ListColorScheme.predefinedColors[0].hex
    @State private var showingColorPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("List Details")) {
                    TextField("List Name", text: $listTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Group Selection
                    HStack {
                        Text("Group")
                        Spacer()
                        Menu {
                            Button("No Group") {
                                selectedGroup = nil
                                // Reset to default color when no group selected
                                selectedColor = ListColorScheme.predefinedColors[0].hex
                            }
                            
                            ForEach(viewModel.groups) { group in
                                Button(action: { 
                                    selectedGroup = group 
                                    // Use group's color as default for the list
                                    selectedColor = group.color
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(Color(listHex: group.color))
                                            .frame(width: 12, height: 12)
                                        Text(group.name)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let group = selectedGroup {
                                    Circle()
                                        .fill(Color(listHex: group.color))
                                        .frame(width: 12, height: 12)
                                    Text(group.name)
                                } else {
                                    Text("None")
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Border Color")
                        Spacer()
                        Button(action: { showingColorPicker = true }) {
                            Circle()
                                .fill(Color(listHex: selectedColor))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
                
                if showingColorPicker {
                    Section("Predefined Colors") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(ListColorScheme.predefinedColors, id: \.hex) { colorScheme in
                                Button(action: { 
                                    selectedColor = colorScheme.hex
                                    showingColorPicker = false
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(listHex: colorScheme.hex))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedColor == colorScheme.hex ? .primary : Color(.systemGray4),
                                                        lineWidth: selectedColor == colorScheme.hex ? 2 : 1
                                                    )
                                            )
                                        
                                        Text(colorScheme.name)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Custom Color") {
                        ColorPicker("Select Color", selection: Binding(
                            get: { Color(listHex: selectedColor) },
                            set: { newColor in
                                // Convert SwiftUI Color to hex string
                                if let components = newColor.cgColor?.components,
                                   components.count >= 3 {
                                    let red = Int(components[0] * 255)
                                    let green = Int(components[1] * 255)
                                    let blue = Int(components[2] * 255)
                                    selectedColor = String(format: "%02X%02X%02X", red, green, blue)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createList()
                    }
                    .disabled(listTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createList() {
        let title = listTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        viewModel.createList(
            title: title,
            groupId: selectedGroup?.id,
            borderColor: selectedColor
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add Group Sheet
struct AddGroupSheet: View {
    @ObservedObject var viewModel: ListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var groupName = ""
    @State private var selectedColor = ListColorScheme.predefinedColors[1].hex
    @State private var showingColorPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Group Color")
                        Spacer()
                        Button(action: { showingColorPicker = true }) {
                            Circle()
                                .fill(Color(listHex: selectedColor))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
                
                if showingColorPicker {
                    Section("Predefined Colors") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(ListColorScheme.predefinedColors, id: \.hex) { colorScheme in
                                Button(action: { 
                                    selectedColor = colorScheme.hex
                                    showingColorPicker = false
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(listHex: colorScheme.hex))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedColor == colorScheme.hex ? .primary : Color(.systemGray4),
                                                        lineWidth: selectedColor == colorScheme.hex ? 2 : 1
                                                    )
                                            )
                                        
                                        Text(colorScheme.name)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Custom Color") {
                        ColorPicker("Select Color", selection: Binding(
                            get: { Color(listHex: selectedColor) },
                            set: { newColor in
                                // Convert SwiftUI Color to hex string
                                if let components = newColor.cgColor?.components,
                                   components.count >= 3 {
                                    let red = Int(components[0] * 255)
                                    let green = Int(components[1] * 255)
                                    let blue = Int(components[2] * 255)
                                    selectedColor = String(format: "%02X%02X%02X", red, green, blue)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createGroup() {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        viewModel.createGroup(name: name, color: selectedColor)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add List Item Sheet
struct AddListItemSheet: View {
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var itemText = ""
    @State private var attributedText = NSMutableAttributedString()
    
    var body: some View {
        NavigationView {
            VStack {
                // Rich Text Editor
                RichTextEditor(attributedText: $attributedText, placeholder: "Enter your list item...")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            // Initialize with basic formatting
            attributedText = NSMutableAttributedString(
                string: "",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
            )
        }
    }
    
    private func addItem() {
        guard !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.addItem(to: list.id, content: attributedText)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit List Item Sheet
struct EditListItemSheet: View {
    let item: ListItem
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var attributedText = NSMutableAttributedString()
    
    var body: some View {
        NavigationView {
            VStack {
                // Rich Text Editor
                RichTextEditor(attributedText: $attributedText, placeholder: "Edit your list item...")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            // Initialize with current item content
            attributedText = NSMutableAttributedString(attributedString: item.content)
        }
    }
    
    private func saveItem() {
        guard !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.updateItem(in: list.id, itemId: item.id, content: attributedText)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - List Settings Sheet
struct ListSettingsSheet: View {
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var listTitle: String
    @State private var selectedGroup: ListGroup?
    @State private var selectedColor: String
    @State private var showingColorPicker = false
    @State private var showingDeleteAlert = false
    
    init(list: SmartList, viewModel: ListViewModel) {
        self.list = list
        self.viewModel = viewModel
        self._listTitle = State(initialValue: list.title)
        self._selectedGroup = State(initialValue: viewModel.groups.first { $0.id == list.groupId })
        self._selectedColor = State(initialValue: list.borderColor)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("List Details")) {
                    TextField("List Name", text: $listTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Group Selection
                    HStack {
                        Text("Group")
                        Spacer()
                        Menu {
                            Button("No Group") {
                                selectedGroup = nil
                            }
                            
                            ForEach(viewModel.groups) { group in
                                Button(action: { selectedGroup = group }) {
                                    HStack {
                                        Circle()
                                            .fill(Color(listHex: group.color))
                                            .frame(width: 12, height: 12)
                                        Text(group.name)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let group = selectedGroup {
                                    Circle()
                                        .fill(Color(listHex: group.color))
                                        .frame(width: 12, height: 12)
                                    Text(group.name)
                                } else {
                                    Text("None")
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Border Color")
                        Spacer()
                        Button(action: { showingColorPicker = true }) {
                            Circle()
                                .fill(Color(listHex: selectedColor))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
                
                if showingColorPicker {
                    Section("Predefined Colors") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(ListColorScheme.predefinedColors, id: \.hex) { colorScheme in
                                Button(action: { 
                                    selectedColor = colorScheme.hex
                                    showingColorPicker = false
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(listHex: colorScheme.hex))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedColor == colorScheme.hex ? .primary : Color(.systemGray4),
                                                        lineWidth: selectedColor == colorScheme.hex ? 2 : 1
                                                    )
                                            )
                                        
                                        Text(colorScheme.name)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Custom Color") {
                        ColorPicker("Select Color", selection: Binding(
                            get: { Color(listHex: selectedColor) },
                            set: { newColor in
                                // Convert SwiftUI Color to hex string
                                if let components = newColor.cgColor?.components,
                                   components.count >= 3 {
                                    let red = Int(components[0] * 255)
                                    let green = Int(components[1] * 255)
                                    let blue = Int(components[2] * 255)
                                    selectedColor = String(format: "%02X%02X%02X", red, green, blue)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Total Items")
                        Spacer()
                        Text("\(list.totalItemsCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Completed Items")
                        Spacer()
                        Text("\(list.completedItemsCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(list.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Modified")
                        Spacer()
                        Text(list.modifiedAt, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Delete List", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("List Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete List"),
                message: Text("This will permanently delete '\(list.title)' and all its items. This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteList(list)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func saveSettings() {
        let title = listTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        viewModel.updateList(
            list.id,
            title: title,
            borderColor: selectedColor,
            groupId: selectedGroup?.id
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}
