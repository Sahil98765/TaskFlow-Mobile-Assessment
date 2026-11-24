import Foundation
@testable import TaskFlow

struct MockTaskService: TaskServicing {
    var fetchHandler: @Sendable (TaskFilter) async throws -> [TaskItem] = { _ in [] }
    var createHandler: @Sendable (CreateTaskRequest) async throws -> TaskItem = { _ in throw APIError.invalidResponse }
    var toggleHandler: @Sendable (UUID) async throws -> TaskItem = { _ in throw APIError.invalidResponse }

    func fetchTasks(filter: TaskFilter) async throws -> [TaskItem] {
        try await fetchHandler(filter)
    }

    func createTask(_ request: CreateTaskRequest) async throws -> TaskItem {
        try await createHandler(request)
    }

    func toggleCompletion(id: UUID) async throws -> TaskItem {
        try await toggleHandler(id)
    }
}

extension TaskItem {
    static func fixture(
        title: String = "Task",
        dueDate: String? = "2026-10-15",
        priority: Priority = .medium,
        assignee: Assignee = .aarav,
        completed: Bool = false
    ) -> TaskItem {
        TaskItem(
            id: UUID(),
            title: title,
            description: nil,
            dueDate: dueDate,
            priority: priority,
            assigneeId: assignee,
            completed: completed
        )
    }

    func togglingCompletion() -> TaskItem {
        var copy = self
        copy.completed.toggle()
        return copy
    }
}
