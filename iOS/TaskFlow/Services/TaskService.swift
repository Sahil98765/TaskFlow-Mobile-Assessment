import Foundation

protocol TaskServicing: Sendable {
    func fetchTasks(filter: TaskFilter) async throws -> [TaskItem]
    func createTask(_ request: CreateTaskRequest) async throws -> TaskItem
    func toggleCompletion(id: UUID) async throws -> TaskItem
}

struct TaskService: TaskServicing {
    let client: APIClient

    func fetchTasks(filter: TaskFilter) async throws -> [TaskItem] {
        try await client.get("api/tasks", queryItems: filter.queryItems)
    }

    func createTask(_ request: CreateTaskRequest) async throws -> TaskItem {
        try await client.post("api/tasks", body: request)
    }

    func toggleCompletion(id: UUID) async throws -> TaskItem {
        try await client.patch("api/tasks/\(id.uuidString)/toggle")
    }
}
