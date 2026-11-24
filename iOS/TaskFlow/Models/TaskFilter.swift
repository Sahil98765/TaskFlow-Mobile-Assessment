import Foundation

enum StatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case active
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .active: "Active"
        case .completed: "Completed"
        }
    }
}

struct TaskFilter: Hashable, Sendable {
    var assignee: Assignee?
    var status: StatusFilter = .all

    var isDefault: Bool {
        assignee == nil && status == .all
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let assignee {
            items.append(URLQueryItem(name: "assignee", value: assignee.rawValue))
        }
        if status != .all {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        return items
    }

    func matches(_ task: TaskItem) -> Bool {
        if let assignee, task.assigneeId != assignee {
            return false
        }
        switch status {
        case .all: return true
        case .active: return !task.completed
        case .completed: return task.completed
        }
    }
}
