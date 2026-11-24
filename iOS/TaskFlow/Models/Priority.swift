import SwiftUI

enum Priority: String, Codable, CaseIterable, Identifiable, Sendable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var color: Color {
        switch self {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    var symbolName: String {
        switch self {
        case .low: "arrow.down"
        case .medium: "equal"
        case .high: "exclamationmark"
        }
    }
}
