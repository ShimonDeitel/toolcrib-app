import Foundation

struct ToolItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String          // Tool / Equipment
    var amount: Double         // Value
    var date: Date             // Checked out
    var isComplete: Bool       // Returned
    var notes: String = ""
    var createdAt: Date = Date()
}
