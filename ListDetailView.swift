import SwiftUI
import UIKit

struct ListDetailView: View {
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    @State private var showingAddItem = false
    @State private var editingItem: ListItem?
    @State private var showingListSettings = false
    
    // Get the current list from viewModel (for real-time updates)
    private var currentList: SmartList {
        viewModel.lists.first { $0.id == list.id } ?? list
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // List Header
                ListDetailHeaderView(list: currentList, viewModel: viewModel)
                    .padding(.horizontal)
                
                // List Items
                LazyVStack(spacing: 12) {
                    ForEach(Array(currentList.items.enumerated()), id: \.element.id) { index, item in
                        ListItemView(
                            item: item,
                            list: currentList,
                            viewModel: viewModel,
                            onEdit: { editingItem = item }
                        )
                        .padding(.horizontal)
                    }
                    .onMove { from, to in
                        viewModel.moveItem(in: currentList.id, from: IndexSet(from), to: to)
                    }
                }
                
                // Empty State
                if currentList.items.isEmpty {
                    EmptyListView(listTitle: currentList.title) {
                        showingAddItem = true
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                }
                
                // Bottom padding for floating action button
                Spacer(minLength: 100)
            }
        }
        .navigationTitle(currentList.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus.circle")
                    }
                    
                    Button(action: { viewModel.toggleListStar(currentList.id) }) {
                        Label(
                            currentList.isStarred ? "Remove Star" : "Add Star",
                            systemImage: currentList.isStarred ? "star.slash" : "star"
                        )
                    }
                    
                    Divider()
                    
                    Button(action: { showingListSettings = true }) {
                        Label("List Settings", systemImage: "gearshape")
                    }
                    
                    Button("Share List", systemImage: "square.and.arrow.up") {
                        // TODO: Implement sharing
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .overlay(
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        )
        .sheet(isPresented: $showingAddItem) {
            AddListItemSheet(list: currentList, viewModel: viewModel)
        }
        .sheet(item: $editingItem) { item in
            EditListItemSheet(item: item, list: currentList, viewModel: viewModel)
        }
        .sheet(isPresented: $showingListSettings) {
            ListSettingsSheet(list: currentList, viewModel: viewModel)
        }
    }
}

// MARK: - List Detail Header
struct ListDetailHeaderView: View {
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(list.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if list.isStarred {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    HStack {
                        if list.totalItemsCount > 0 {
                            Text("\(list.completedItemsCount) of \(list.totalItemsCount) items completed")
                        } else {
                            Text("No items yet")
                        }
                        
                        Text("•")
                        
                        HStack(spacing: 4) {
                            Text("Modified")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(list.modifiedAt, format: .dateTime.day().month(.abbreviated))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(list.modifiedAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if list.totalItemsCount > 0 {
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: list.progressPercentage)
                                .stroke(
                                    Color(listHex: list.borderColor),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: list.progressPercentage)
                            
                            Text("\(Int(list.progressPercentage * 100))%")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            // Progress bar
            if list.totalItemsCount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if list.progressPercentage == 1.0 {
                            Text("All done! 🎉")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(listHex: list.borderColor))
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(listHex: list.borderColor),
                                            Color(listHex: list.borderColor).opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * list.progressPercentage, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: list.progressPercentage)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(listHex: list.borderColor).opacity(0.6),
                            Color(listHex: list.borderColor).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - List Item View
struct ListItemView: View {
    let item: ListItem
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    let onEdit: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion Button
            Button(action: { viewModel.toggleItemCompletion(in: list.id, itemId: item.id) }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(item.isCompleted ? Color(listHex: list.borderColor) : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Item Content
            VStack(alignment: .leading, spacing: 4) {
                // Rich text content
                RichTextView(attributedText: item.content)
                
                // Metadata
                HStack {
                    if item.createdAt != item.modifiedAt {
                        HStack(spacing: 4) {
                            Text("Modified")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(item.modifiedAt, format: .dateTime.day().month(.abbreviated))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(item.modifiedAt, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text("Created")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(item.createdAt, format: .dateTime.day().month(.abbreviated))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(item.createdAt, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if item.isCompleted {
                        Text("Done")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(listHex: list.borderColor))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(listHex: list.borderColor).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .opacity(item.isCompleted ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            
            Spacer()
        }
        .padding()
        .background(item.isCompleted ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    item.isCompleted 
                        ? Color(listHex: list.borderColor).opacity(0.3)
                        : Color(.systemGray4),
                    lineWidth: 0.5
                )
        )
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: { viewModel.toggleItemCompletion(in: list.id, itemId: item.id) }) {
                Label(
                    item.isCompleted ? "Mark Incomplete" : "Mark Complete",
                    systemImage: item.isCompleted ? "circle" : "checkmark.circle"
                )
            }
            
            Button(role: .destructive, action: { viewModel.deleteItem(from: list.id, itemId: item.id) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Rich Text Display View
struct RichTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if attributedText.length == 0 {
            uiView.text = ""
        } else {
            uiView.attributedText = attributedText
        }
    }
}

// MARK: - Empty List View
struct EmptyListView: View {
    let listTitle: String
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text("Your list is empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("Add your first item to get started with '\(listTitle)'")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddItem) {
                Label("Add First Item", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
