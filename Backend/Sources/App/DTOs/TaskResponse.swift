import Vapor

struct TaskResponse: Content, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let dueDate: String?
    let priority: TaskPriority
    let assigneeId: Assignee
    let completed: Bool

    init(_ model: TaskModel) throws {
        self.id = try model.requireID()
        self.title = model.title
        self.description = model.details
        self.dueDate = model.dueDate
        self.priority = model.priority
        self.assigneeId = model.assigneeId
        self.completed = model.completed
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encode(priority, forKey: .priority)
        try container.encode(assigneeId, forKey: .assigneeId)
        try container.encode(completed, forKey: .completed)
    }
}
