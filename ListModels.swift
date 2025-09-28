import Foundation
import SwiftUI

// MARK: - List Item Model
struct ListItem: Identifiable, Codable, Hashable {
    let id: UUID
    var content: NSAttributedString // Rich text content
    var isCompleted: Bool
    var createdAt: Date
    var modifiedAt: Date
    
    init(content: NSAttributedString = NSAttributedString(string: ""), isCompleted: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Codable Implementation for NSAttributedString
    private enum CodingKeys: String, CodingKey {
        case id, isCompleted, createdAt, modifiedAt, contentData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        
        if let contentData = try container.decodeIfPresent(Data.self, forKey: .contentData) {
            do {
                content = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: contentData) ?? NSAttributedString()
            } catch {
                content = NSAttributedString()
            }
        } else {
            content = NSAttributedString()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        
        do {
            let contentData = try NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: false)
            try container.encode(contentData, forKey: .contentData)
        } catch {
            // If encoding fails, encode empty data
            let emptyData = try NSKeyedArchiver.archivedData(withRootObject: NSAttributedString(), requiringSecureCoding: false)
            try container.encode(emptyData, forKey: .contentData)
        }
    }
    
    mutating func updateContent(_ newContent: NSAttributedString) {
        content = newContent
        modifiedAt = Date()
    }
    
    mutating func toggleCompletion() {
        isCompleted.toggle()
        modifiedAt = Date()
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(content.string) // Use the string content for hashing
        hasher.combine(isCompleted)
        hasher.combine(createdAt)
        hasher.combine(modifiedAt)
    }
    
    static func == (lhs: ListItem, rhs: ListItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.content.string == rhs.content.string &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.createdAt == rhs.createdAt &&
               lhs.modifiedAt == rhs.modifiedAt
    }
}

// MARK: - Smart List Model
struct SmartList: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var items: [ListItem]
    var groupId: UUID?
    var isStarred: Bool
    var borderColor: String // Hex color for border grading
    var createdAt: Date
    var modifiedAt: Date
    var sortOrder: Int // For manual ordering
    
    init(title: String, groupId: UUID? = nil, borderColor: String = "#FF6B6B") {
        self.id = UUID()
        self.title = title
        self.items = []
        self.groupId = groupId
        self.isStarred = false
        self.borderColor = borderColor
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.sortOrder = 0
    }
    
    var completedItemsCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    var totalItemsCount: Int {
        items.count
    }
    
    var progressPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    mutating func addItem(_ item: ListItem) {
        items.append(item)
        modifiedAt = Date()
    }
    
    mutating func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        modifiedAt = Date()
    }
    
    mutating func moveItem(from: IndexSet, to: Int) {
        items.move(fromOffsets: from, toOffset: to)
        modifiedAt = Date()
    }
    
    mutating func toggleStar() {
        isStarred.toggle()
        modifiedAt = Date()
    }
    
    mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        modifiedAt = Date()
    }
    
    mutating func updateBorderColor(_ newColor: String) {
        borderColor = newColor
        modifiedAt = Date()
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SmartList, rhs: SmartList) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - List Group Model
struct ListGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String // Hex color for the group
    var isExpanded: Bool
    var createdAt: Date
    var modifiedAt: Date
    var sortOrder: Int
    
    init(name: String, color: String = "#4ECDC4") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.isExpanded = true
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.sortOrder = 0
    }
    
    mutating func updateName(_ newName: String) {
        name = newName
        modifiedAt = Date()
    }
    
    mutating func updateColor(_ newColor: String) {
        color = newColor
        modifiedAt = Date()
    }
    
    mutating func toggleExpanded() {
        isExpanded.toggle()
        modifiedAt = Date()
    }
}

// MARK: - Predefined Color Schemes
struct ListColorScheme {
    static let predefinedColors: [(name: String, hex: String)] = [
        ("Coral", "#FF6B6B"),
        ("Mint", "#4ECDC4"),
        ("Lavender", "#A8E6CF"),
        ("Peach", "#FFB347"),
        ("Sky Blue", "#87CEEB"),
        ("Rose", "#FFB6C1"),
        ("Sage", "#9CAF88"),
        ("Sunset", "#FF8C69"),
        ("Ocean", "#20B2AA"),
        ("Violet", "#9370DB"),
        ("Gold", "#FFD700"),
        ("Forest", "#228B22")
    ]
    
    static func randomColor() -> String {
        return predefinedColors.randomElement()?.hex ?? "#FF6B6B"
    }
}

// MARK: - List Sort Options
enum ListSortOption: String, CaseIterable {
    case dateCreated = "Date Created"
    case dateModified = "Date Modified"
    case alphabetical = "Alphabetical"
    case starred = "Starred First"
    case manual = "Manual"
    
    var icon: String {
        switch self {
        case .dateCreated: return "calendar.badge.plus"
        case .dateModified: return "calendar.badge.clock"
        case .alphabetical: return "textformat.abc"
        case .starred: return "star.fill"
        case .manual: return "hand.draw"
        }
    }
}

// MARK: - Extensions for SwiftUI Integration
extension Color {
    init(listHex: String) {
        // Try to create color from hex string, fallback to gray
        if let color = Color.fromHexString(listHex) {
            self = color
        } else {
            self = Color.gray
        }
    }
    
    static func fromHexString(_ hex: String) -> Color? {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}