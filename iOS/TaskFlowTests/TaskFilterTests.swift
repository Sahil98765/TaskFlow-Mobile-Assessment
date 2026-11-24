import Foundation
import Testing
@testable import TaskFlow

struct TaskFilterTests {
    private let tasks: [TaskItem] = [
        .fixture(title: "Aarav active", assignee: .aarav, completed: false),
        .fixture(title: "Aarav done", assignee: .aarav, completed: true),
        .fixture(title: "Priya active", assignee: .priya, completed: false),
    ]

    @Test func defaultFilterMatchesEverything() {
        let filter = TaskFilter()
        #expect(filter.isDefault)
        #expect(filter.queryItems.isEmpty)
        #expect(tasks.filter(filter.matches).count == 3)
    }

    @Test func combinesAssigneeAndStatus() {
        let filter = TaskFilter(assignee: .aarav, status: .completed)
        #expect(tasks.filter(filter.matches).map(\.title) == ["Aarav done"])
        #expect(filter.queryItems == [
            URLQueryItem(name: "assignee", value: "aarav"),
            URLQueryItem(name: "status", value: "completed"),
        ])
    }

    @Test func combinedFilterCanMatchNothing() {
        let filter = TaskFilter(assignee: .priya, status: .completed)
        #expect(tasks.filter(filter.matches).isEmpty)
    }
}
