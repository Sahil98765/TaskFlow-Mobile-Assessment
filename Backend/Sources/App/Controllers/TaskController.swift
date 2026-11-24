import Fluent
import Vapor

struct TaskController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let tasks = routes.grouped("api", "tasks")
        tasks.get(use: index)
        tasks.post(use: create)
        tasks.patch(":taskID", "toggle", use: toggle)
    }

    @Sendable
    func index(req: Request) async throws -> [TaskResponse] {
        let filters = try req.query.decode(TaskListQuery.self).validated()

        let query = TaskModel.query(on: req.db)
        if let assignee = filters.assignee {
            query.filter(\.$assigneeId == assignee)
        }
        switch filters.status {
        case .all:
            break
        case .active:
            query.filter(\.$completed == false)
        case .completed:
            query.filter(\.$completed == true)
        }

        return try await query.all()
            .sorted(by: Self.listOrder)
            .map(TaskResponse.init)
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let task = try req.content.decode(CreateTaskRequest.self).validated()
        try await task.create(on: req.db)
        return try await TaskResponse(task).encodeResponse(status: .created, for: req)
    }

    @Sendable
    func toggle(req: Request) async throws -> TaskResponse {
        guard let id = req.parameters.get("taskID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Task id must be a valid UUID.")
        }
        guard let task = try await TaskModel.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Task not found.")
        }
        task.completed.toggle()
        try await task.save(on: req.db)
        return try TaskResponse(task)
    }

    private static func listOrder(_ lhs: TaskModel, _ rhs: TaskModel) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
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
