import Foundation

struct CreateTaskRequest: Encodable, Equatable, Sendable {
    let title: String
    let description: String?
    let dueDate: String?
    let priority: Priority
    let assigneeId: Assignee
}
