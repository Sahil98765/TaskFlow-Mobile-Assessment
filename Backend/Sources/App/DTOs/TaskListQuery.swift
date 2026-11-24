import Vapor

struct TaskListQuery: Content {
    let assignee: String?
    let status: String?

    func validated() throws -> (assignee: Assignee?, status: TaskStatusFilter) {
        var errors: [String: String] = [:]

        let assigneeValue = assignee.flatMap { $0.isEmpty ? nil : $0 }
        let parsedAssignee = assigneeValue.flatMap(Assignee.init(rawValue:))
        if assigneeValue != nil, parsedAssignee == nil {
            errors["assignee"] = "Assignee must be one of: \(Assignee.allowedValuesDescription)."
        }

        let statusValue = status.flatMap { $0.isEmpty ? nil : $0 }
        let parsedStatus = statusValue == nil ? .all : statusValue.flatMap(TaskStatusFilter.init(rawValue:))
        if parsedStatus == nil {
            errors["status"] = "Status must be one of: \(TaskStatusFilter.allowedValuesDescription)."
        }

        guard errors.isEmpty, let parsedStatus else {
            throw ValidationFailure(reason: "Invalid query parameters.", fieldErrors: errors)
        }
        return (parsedAssignee, parsedStatus)
    }
}
