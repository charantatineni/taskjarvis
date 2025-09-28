import SwiftUI

// MARK: - Lists Feature Integration Check
struct ListsIntegrationCheck {
    
    // Test that all components can be instantiated
    static func testInstantiation() {
        let listViewModel = ListViewModel()
        let _ = ListsMainView(viewModel: listViewModel)
        
        // Test model creation
        let _ = SmartList(title: "Test List")
        let _ = ListGroup(name: "Test Group")
        let _ = ListItem()
        
        print("✅ All Lists components can be instantiated")
    }
    
    // Test data operations
    static func testDataOperations() {
        let viewModel = ListViewModel()
        
        // Test list creation
        viewModel.createList(title: "Test List")
        viewModel.createGroup(name: "Test Group")
        
        // Test persistence methods exist
        let dataManager = DataManager.shared
        let _ = dataManager.documentsDirectory
        
        print("✅ Data operations available")
    }
}

// MARK: - Preview Providers
struct ListsMainView_Previews: PreviewProvider {
    static var previews: some View {
        ListsMainView(viewModel: ListViewModel())
    }
}

struct ListDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleList = SmartList(title: "Sample List")
        ListDetailView(list: sampleList, viewModel: ListViewModel())
    }
}

// MARK: - Testing Data
extension ListViewModel {
    static func withSampleData() -> ListViewModel {
        let viewModel = ListViewModel()
        
        // Add sample groups
        viewModel.createGroup(name: "Work", color: "#FF6B6B")
        viewModel.createGroup(name: "Personal", color: "#4ECDC4")
        
        // Add sample lists
        viewModel.createList(title: "Project Tasks", borderColor: "#FF6B6B")
        viewModel.createList(title: "Shopping List", borderColor: "#4ECDC4")
        viewModel.createList(title: "Travel Planning", borderColor: "#FFD166")
        
        return viewModel
    }
}

// MARK: - Integration Test
@available(iOS 15.0, *)
struct ListsFeatureTest: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var listViewModel = ListViewModel.withSampleData()
    @State private var selectedTab = 2
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Daily Routines")
                .tabItem {
                    Label("Daily Routines", systemImage: "repeat.circle")
                }
                .tag(0)
            
            Text("Monthly")
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
    }
}

// MARK: - Color Scheme Testing
struct ColorSchemeTest: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("List Color Schemes")
                .font(.title)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(ListColorScheme.predefinedColors, id: \.hex) { colorScheme in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color(listHex: colorScheme.hex))
                            .frame(width: 50, height: 50)
                        
                        Text(colorScheme.name)
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}