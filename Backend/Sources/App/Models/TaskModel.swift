import Fluent
import Foundation

final class TaskModel: Model, @unchecked Sendable {
    static let schema = "tasks"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @OptionalField(key: "description")
    var details: String?

    @OptionalField(key: "due_date")
    var dueDate: String?

    @Field(key: "priority")
    var priority: TaskPriority

    @Field(key: "assignee_id")
    var assigneeId: Assignee

    @Field(key: "completed")
    var completed: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        title: String,
        details: String?,
        dueDate: String?,
        priority: TaskPriority,
        assigneeId: Assignee,
        completed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.priority = priority
        self.assigneeId = assigneeId
        self.completed = completed
    }
}
