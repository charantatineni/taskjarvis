import SwiftUI

struct ListsMainView: View {
    @ObservedObject var viewModel: ListViewModel
    @State private var showingAddListSheet = false
    @State private var showingAddGroupSheet = false
    @State private var searchText = ""
    @State private var showingStarredSection = false
    @State private var selectedList: SmartList? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    ListsHeaderView(
                        viewModel: viewModel,
                        searchText: $searchText
                    )
                    .padding(.horizontal)
                    
                    // Search Results (if searching)
                    if !searchText.isEmpty {
                        SearchResultsSection(viewModel: viewModel, searchText: searchText)
                            .padding(.horizontal)
                    } else {
                        // Main Content
                        VStack(spacing: 20) {
                            // Starred Lists Section (if any exist)
                            if viewModel.totalStarredLists > 0 {
                                StarredListsSection(viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                            
                            // Groups and Lists
                            GroupedListsSection(viewModel: viewModel)
                                .padding(.horizontal)
                            
                            // Ungrouped Lists
                            UngroupedListsSection(viewModel: viewModel)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Bottom padding for floating action button
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Lists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddListSheet = true }) {
                            Label("New List", systemImage: "plus.rectangle.on.rectangle")
                        }
                        
                        Button(action: { showingAddGroupSheet = true }) {
                            Label("New Group", systemImage: "folder.badge.plus")
                        }
                        
                        Button(action: { viewModel.showingStarredOnly.toggle() }) {
                            Label(
                                viewModel.showingStarredOnly ? "Show All Lists" : "Show Starred Only",
                                systemImage: viewModel.showingStarredOnly ? "star.slash" : "star.fill"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search lists and items...")
        .overlay(
            // Floating Action Button for Lists - only show when not in detail view
            Group {
                if selectedList == nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showingAddListSheet = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 70) // Above tab bar
                        }
                    }
                }
            }
        )
        .sheet(isPresented: $showingAddListSheet) {
            AddListSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddGroupSheet) {
            AddGroupSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Header View
struct ListsHeaderView: View {
    @ObservedObject var viewModel: ListViewModel
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Stats Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Lists")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(viewModel.totalLists) lists • \(viewModel.totalItems) items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.totalItems > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(viewModel.overallProgress * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                        
                        Text("completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Overall Progress Bar (if there are items)
            if viewModel.totalItems > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Overall Progress")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(viewModel.totalCompletedItems) of \(viewModel.totalItems) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.8), .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.overallProgress, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: viewModel.overallProgress)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Search Results Section
struct SearchResultsSection: View {
    @ObservedObject var viewModel: ListViewModel
    let searchText: String
    
    var searchResults: [SmartList] {
        viewModel.searchLists(searchText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(searchResults.count) found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No lists found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Try a different search term")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(searchResults) { list in
                        NavigationLink(destination: ListDetailView(list: list, viewModel: viewModel)) {
                            ListCardView(list: list, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Starred Lists Section
struct StarredListsSection: View {
    @ObservedObject var viewModel: ListViewModel
    
    var starredLists: [SmartList] {
        viewModel.getStarredLists()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Starred")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(starredLists.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(starredLists) { list in
                    NavigationLink(destination: ListDetailView(list: list, viewModel: viewModel)) {
                        ListCardView(list: list, viewModel: viewModel, showStarBadge: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Grouped Lists Section
struct GroupedListsSection: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.groups.sorted(by: { $0.sortOrder < $1.sortOrder })) { group in
                GroupSectionView(group: group, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Group Section View
struct GroupSectionView: View {
    let group: ListGroup
    @ObservedObject var viewModel: ListViewModel
    @State private var showingGroupOptions = false
    
    var listsInGroup: [SmartList] {
        viewModel.getListsInGroup(group.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header
            HStack {
                Button(action: { viewModel.toggleGroupExpansion(group.id) }) {
                    HStack(spacing: 8) {
                        Image(systemName: group.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(Color(listHex: group.color))
                            .frame(width: 12, height: 12)
                        
                        Text(group.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("(\(listsInGroup.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: { showingGroupOptions = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Group Lists (if expanded)
            if group.isExpanded {
                LazyVStack(spacing: 8) {
                    ForEach(listsInGroup) { list in
                        NavigationLink(destination: ListDetailView(list: list, viewModel: viewModel)) {
                            ListCardView(list: list, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.leading, 20)
            }
        }
        .actionSheet(isPresented: $showingGroupOptions) {
            ActionSheet(
                title: Text(group.name),
                buttons: [
                    .default(Text("Edit Group")) {
                        // TODO: Implement edit group
                    },
                    .destructive(Text("Delete Group")) {
                        viewModel.deleteGroup(group.id)
                    },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - Ungrouped Lists Section
struct UngroupedListsSection: View {
    @ObservedObject var viewModel: ListViewModel
    
    var ungroupedLists: [SmartList] {
        viewModel.getUngroupedLists()
    }
    
    var body: some View {
        if !ungroupedLists.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Other Lists")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(ungroupedLists.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(ungroupedLists) { list in
                        NavigationLink(destination: ListDetailView(list: list, viewModel: viewModel)) {
                            ListCardView(list: list, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - List Card View
struct ListCardView: View {
    let list: SmartList
    @ObservedObject var viewModel: ListViewModel
    var showStarBadge: Bool = false
    @State private var showingSettings = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(list.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if list.isStarred && !showStarBadge {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    if list.totalItemsCount > 0 {
                        Text("\(list.completedItemsCount) of \(list.totalItemsCount) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text(list.modifiedAt, format: .dateTime.day().month(.abbreviated))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(list.modifiedAt, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Progress bar for lists with items
                if list.totalItemsCount > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray6))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(listHex: list.borderColor))
                                .frame(width: geometry.size.width * list.progressPercentage, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: list.progressPercentage)
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Button(action: { viewModel.toggleListStar(list.id) }) {
                    Image(systemName: list.isStarred ? "star.fill" : "star")
                        .foregroundColor(list.isStarred ? .yellow : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                if showStarBadge {
                    Text("★")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(listHex: list.borderColor).opacity(0.8),
                            Color(listHex: list.borderColor).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(action: { viewModel.toggleListStar(list.id) }) {
                Label(list.isStarred ? "Remove Star" : "Add Star", 
                      systemImage: list.isStarred ? "star.slash" : "star")
            }
            
            Button(action: { showingSettings = true }) {
                Label("List Settings", systemImage: "gear")
            }
            
            Divider()
            
            Button(role: .destructive, action: { viewModel.deleteList(list) }) {
                Label("Delete List", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingSettings) {
            ListSettingsSheet(list: list, viewModel: viewModel)
        }
    }
}