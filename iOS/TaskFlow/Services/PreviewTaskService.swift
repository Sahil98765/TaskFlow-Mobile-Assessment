#if DEBUG
import Foundation

struct PreviewTaskService: TaskServicing {
    var fails = false

    static let sampleTasks: [TaskItem] = [
        TaskItem(id: UUID(), title: "Complete project proposal", description: "Draft and send the proposal to the client.", dueDate: "2026-10-15", priority: .high, assigneeId: .aarav, completed: false),
        TaskItem(id: UUID(), title: "Review design mockups", description: "Provide feedback on new UI designs.", dueDate: "2026-10-12", priority: .medium, assigneeId: .aarav, completed: true),
        TaskItem(id: UUID(), title: "Write blog post", description: nil, dueDate: "2099-10-25", priority: .low, assigneeId: .priya, completed: false),
        TaskItem(id: UUID(), title: "Update portfolio website", description: nil, dueDate: nil, priority: .medium, assigneeId: .aarav, completed: false),
    ]

    func fetchTasks(filter: TaskFilter) async throws -> [TaskItem] {
        if fails { throw APIError.network(.cannotConnectToHost) }
        return Self.sampleTasks.filter(filter.matches)
    }

    func createTask(_ request: CreateTaskRequest) async throws -> TaskItem {
        throw APIError.server(statusCode: 400, reason: "Validation failed.", fieldErrors: ["title": "Title must be 120 characters or fewer."])
    }

    func toggleCompletion(id: UUID) async throws -> TaskItem {
        guard var task = Self.sampleTasks.first(where: { $0.id == id }) else {
            throw APIError.server(statusCode: 404, reason: "Task not found.", fieldErrors: [:])
        }
        task.completed.toggle()
        return task
    }
}
#endif
