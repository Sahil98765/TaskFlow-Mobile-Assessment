import Foundation
import Testing
@testable import TaskFlow

struct TaskItemTests {
    private let today = CalendarDay(isoString: "2026-11-25")!

    @Test func activeTaskWithPastDueDateIsOverdue() {
        let task = TaskItem.fixture(dueDate: "2026-10-15", completed: false)
        #expect(task.isOverdue(today: today))
    }

    @Test func completedTaskWithPastDueDateIsNotOverdue() {
        let task = TaskItem.fixture(dueDate: "2026-10-15", completed: true)
        #expect(!task.isOverdue(today: today))
    }

    @Test func taskDueTodayIsNotOverdue() {
        let task = TaskItem.fixture(dueDate: "2026-11-25")
        #expect(!task.isOverdue(today: today))
    }

    @Test func taskWithoutDueDateIsNeverOverdue() {
        let task = TaskItem.fixture(dueDate: nil)
        #expect(!task.isOverdue(today: today))
        #expect(task.dueDateText == "No due date")
    }

    @Test func taskWithMalformedDueDateIsNotOverdue() {
        let task = TaskItem.fixture(dueDate: "15/10/2026")
        #expect(!task.isOverdue(today: today))
        #expect(task.hasInvalidDueDate)
    }

    @Test func listOrderPlacesUndatedTasksLast() {
        let undated = TaskItem.fixture(title: "A", dueDate: nil)
        let later = TaskItem.fixture(title: "B", dueDate: "2026-10-20")
        let earlier = TaskItem.fixture(title: "C", dueDate: "2026-10-10")

        let sorted = [undated, later, earlier].sorted(by: TaskItem.listOrder)

        #expect(sorted.map(\.title) == ["C", "B", "A"])
    }

    @Test func decodesNullDueDateFromServer() throws {
        let json = Data("""
        {"id":"7E4C9F1A-6C0B-4C57-9E58-2B7B6D1F0A11","title":"Update portfolio website","description":null,
         "dueDate":null,"priority":"medium","assigneeId":"aarav","completed":false}
        """.utf8)

        let task = try JSONDecoder().decode(TaskItem.self, from: json)

        #expect(task.dueDate == nil)
        #expect(task.description == nil)
    }
}
