import Foundation

extension CalendarDay {
    var displayText: String {
        guard let date = date() else { return isoString }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

extension TaskItem {
    var dueDateText: String {
        if let dueDay {
            return dueDay.displayText
        }
        return hasInvalidDueDate ? "Invalid due date" : "No due date"
    }
}
