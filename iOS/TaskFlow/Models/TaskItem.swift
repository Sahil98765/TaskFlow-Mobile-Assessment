import Foundation

struct TaskItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var title: String
    var description: String?
    var dueDate: String?
    var priority: Priority
    var assigneeId: Assignee
    var completed: Bool
}

extension TaskItem {
    var dueDay: CalendarDay? {
        dueDate.flatMap(CalendarDay.init(isoString:))
    }

    var hasInvalidDueDate: Bool {
        dueDate != nil && dueDay == nil
    }

    func isOverdue(today: CalendarDay = .today()) -> Bool {
        guard !completed, let dueDay else { return false }
        return dueDay < today
    }

    static func listOrder(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        switch (lhs.dueDay, rhs.dueDay) {
        case let (left?, right?) where left != right:
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }
}
