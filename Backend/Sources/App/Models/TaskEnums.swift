enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

enum Assignee: String, Codable, CaseIterable, Sendable {
    case aarav
    case priya
    case rohan
}

enum TaskStatusFilter: String, CaseIterable, Sendable {
    case all
    case active
    case completed
}

extension CaseIterable where Self: RawRepresentable, RawValue == String {
    static var allowedValuesDescription: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }
}
