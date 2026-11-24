import SwiftUI

enum Assignee: String, Codable, CaseIterable, Identifiable, Sendable {
    case aarav
    case priya
    case rohan

    var id: String { rawValue }

    var name: String {
        switch self {
        case .aarav: "Aarav"
        case .priya: "Priya"
        case .rohan: "Rohan"
        }
    }

    var color: Color {
        switch self {
        case .aarav: .blue
        case .priya: .purple
        case .rohan: .teal
        }
    }
}
