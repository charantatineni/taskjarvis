import SwiftUI
import Combine

final class ListViewModel: ObservableObject {
    @Published var lists: [SmartList] = []
    @Published var groups: [ListGroup] = []
    @Published var currentSortOption: ListSortOption = .dateModified
    @Published var showingStarredOnly: Bool = false
    
    private let dataManager = DataManager.shared
    
    init() {
        loadData()
        setupAppLifecycleObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - App Lifecycle Management
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        saveLists()
        saveGroups()
        print("💾 Lists data auto-saved on app background")
    }
    
    @objc private func appDidBecomeActive() {
        // Optionally reload data when app becomes active
        // loadData() // Uncomment if you want to reload on app foreground
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        lists = dataManager.loadSmartLists()
        groups = dataManager.loadListGroups()
        print("📋 Lists data loaded: \(lists.count) lists, \(groups.count) groups")
        
        // Create default "Personal" group if no groups exist
        if groups.isEmpty {
            createDefaultGroup()
        }
    }
    
    private func saveLists() {
        dataManager.saveSmartLists(lists)
    }
    
    private func saveGroups() {
        dataManager.saveListGroups(groups)
    }
    
    private func createDefaultGroup() {
        let defaultGroup = ListGroup(name: "Personal", color: "#4ECDC4")
        groups.append(defaultGroup)
        saveGroups()
    }
    
    // MARK: - List Management
    func createList(title: String, groupId: UUID? = nil, borderColor: String? = nil) {
        let color = borderColor ?? ListColorScheme.randomColor()
        var newList = SmartList(title: title, groupId: groupId, borderColor: color)
        newList.sortOrder = lists.count
        lists.append(newList)
        saveLists()
    }
    
    func deleteList(_ list: SmartList) {
        lists.removeAll { $0.id == list.id }
        saveLists()
    }
    
    func updateList(_ listId: UUID, title: String? = nil, borderColor: String? = nil, groupId: UUID? = nil) {
        guard let index = lists.firstIndex(where: { $0.id == listId }) else { return }
        
        if let title = title {
            lists[index].updateTitle(title)
        }
        if let borderColor = borderColor {
            lists[index].updateBorderColor(borderColor)
        }
        if let groupId = groupId {
            lists[index].groupId = groupId
            lists[index].modifiedAt = Date()
        }
        
        saveLists()
    }
    
    func toggleListStar(_ listId: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[index].toggleStar()
        saveLists()
    }
    
    func moveList(from source: IndexSet, to destination: Int, in groupId: UUID?) {
        let filteredLists = getFilteredAndSortedLists(groupId: groupId)
        guard let sourceIndex = source.first,
              sourceIndex < filteredLists.count else { return }
        
        let listToMove = filteredLists[sourceIndex]
        
        // Update sort orders based on new positions
        updateListSortOrders(after: listToMove, newPosition: destination, in: groupId)
        saveLists()
    }
    
    private func updateListSortOrders(after movedList: SmartList, newPosition: Int, in groupId: UUID?) {
        let groupLists = lists.filter { $0.groupId == groupId }
        for (index, list) in groupLists.enumerated() {
            if let listIndex = lists.firstIndex(where: { $0.id == list.id }) {
                lists[listIndex].sortOrder = index
            }
        }
    }
    
    // MARK: - List Item Management
    func addItem(to listId: UUID, content: NSAttributedString) {
        guard let index = lists.firstIndex(where: { $0.id == listId }) else { return }
        let newItem = ListItem(content: content)
        lists[index].addItem(newItem)
        saveLists()
    }
    
    func updateItem(in listId: UUID, itemId: UUID, content: NSAttributedString) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }),
              let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        lists[listIndex].items[itemIndex].updateContent(content)
        saveLists()
    }
    
    func toggleItemCompletion(in listId: UUID, itemId: UUID) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }),
              let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        lists[listIndex].items[itemIndex].toggleCompletion()
        saveLists()
    }
    
    func deleteItem(from listId: UUID, itemId: UUID) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }),
              let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        lists[listIndex].items.remove(at: itemIndex)
        lists[listIndex].modifiedAt = Date()
        saveLists()
    }
    
    func moveItem(in listId: UUID, from source: IndexSet, to destination: Int) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[listIndex].moveItem(from: source, to: destination)
        saveLists()
    }
    
    // MARK: - Group Management
    func createGroup(name: String, color: String? = nil) {
        let groupColor = color ?? ListColorScheme.randomColor()
        var newGroup = ListGroup(name: name, color: groupColor)
        newGroup.sortOrder = groups.count
        groups.append(newGroup)
        saveGroups()
    }
    
    func updateGroup(_ groupId: UUID, name: String? = nil, color: String? = nil) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        
        if let name = name {
            groups[index].updateName(name)
        }
        if let color = color {
            groups[index].updateColor(color)
        }
        
        saveGroups()
    }
    
    func deleteGroup(_ groupId: UUID) {
        // Move all lists in this group to no group (ungrouped)
        for index in lists.indices {
            if lists[index].groupId == groupId {
                lists[index].groupId = nil
                lists[index].modifiedAt = Date()
            }
        }
        
        groups.removeAll { $0.id == groupId }
        saveLists()
        saveGroups()
    }
    
    func toggleGroupExpansion(_ groupId: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].toggleExpanded()
        saveGroups()
    }
    
    func moveGroup(from source: IndexSet, to destination: Int) {
        groups.move(fromOffsets: source, toOffset: destination)
        // Update sort orders
        for (index, group) in groups.enumerated() {
            groups[index].sortOrder = index
        }
        saveGroups()
    }
    
    // MARK: - Filtering and Sorting
    func getFilteredAndSortedLists(groupId: UUID? = nil) -> [SmartList] {
        var filteredLists = lists.filter { list in
            let groupMatch = list.groupId == groupId
            let starredMatch = !showingStarredOnly || list.isStarred
            return groupMatch && starredMatch
        }
        
        // Sort based on current option
        switch currentSortOption {
        case .dateCreated:
            filteredLists.sort { $0.createdAt < $1.createdAt }
        case .dateModified:
            filteredLists.sort { $0.modifiedAt > $1.modifiedAt }
        case .alphabetical:
            filteredLists.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .starred:
            filteredLists.sort { ($0.isStarred && !$1.isStarred) || ($0.isStarred == $1.isStarred && $0.modifiedAt > $1.modifiedAt) }
        case .manual:
            filteredLists.sort { $0.sortOrder < $1.sortOrder }
        }
        
        return filteredLists
    }
    
    func getStarredLists() -> [SmartList] {
        return lists.filter { $0.isStarred }.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    func getUngroupedLists() -> [SmartList] {
        return getFilteredAndSortedLists(groupId: nil)
    }
    
    func getListsInGroup(_ groupId: UUID) -> [SmartList] {
        return getFilteredAndSortedLists(groupId: groupId)
    }
    
    // MARK: - Search Functionality
    func searchLists(_ searchText: String) -> [SmartList] {
        guard !searchText.isEmpty else { return getFilteredAndSortedLists() }
        
        return lists.filter { list in
            // Search in list title
            list.title.localizedCaseInsensitiveContains(searchText) ||
            // Search in list items content
            list.items.contains { item in
                item.content.string.localizedCaseInsensitiveContains(searchText)
            }
        }.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    // MARK: - Statistics
    var totalLists: Int {
        lists.count
    }
    
    var totalStarredLists: Int {
        lists.filter { $0.isStarred }.count
    }
    
    var totalCompletedItems: Int {
        lists.reduce(0) { $0 + $1.completedItemsCount }
    }
    
    var totalItems: Int {
        lists.reduce(0) { $0 + $1.totalItemsCount }
    }
    
    var overallProgress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(totalCompletedItems) / Double(totalItems)
    }
}

// MARK: - DataManager Extensions
extension DataManager {
    // MARK: - SmartLists Persistence
    func saveSmartLists(_ lists: [SmartList]) {
        do {
            let data = try JSONEncoder().encode(lists)
            try data.write(to: smartListsURL)
        } catch {
            print("❌ Failed to save smart lists: \(error)")
        }
    }
    
    func loadSmartLists() -> [SmartList] {
        do {
            let data = try Data(contentsOf: smartListsURL)
            return try JSONDecoder().decode([SmartList].self, from: data)
        } catch {
            print("❌ Failed to load smart lists: \(error)")
            return []
        }
    }
    
    // MARK: - ListGroups Persistence
    func saveListGroups(_ groups: [ListGroup]) {
        do {
            let data = try JSONEncoder().encode(groups)
            try data.write(to: listGroupsURL)
        } catch {
            print("❌ Failed to save list groups: \(error)")
        }
    }
    
    func loadListGroups() -> [ListGroup] {
        do {
            let data = try Data(contentsOf: listGroupsURL)
            return try JSONDecoder().decode([ListGroup].self, from: data)
        } catch {
            print("❌ Failed to load list groups: \(error)")
            return []
        }
    }
    
    // MARK: - File URLs
    private var smartListsURL: URL {
        documentsDirectory.appendingPathComponent("smartlists.json")
    }
    
    private var listGroupsURL: URL {
        documentsDirectory.appendingPathComponent("listgroups.json")
    }
}