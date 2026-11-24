import Vapor

struct CreateTaskRequest: Decodable {
    static let maxTitleLength = 120
    static let maxDescriptionLength = 1000

    let title: String?
    let description: String?
    let dueDate: String?
    let priority: String?
    let assigneeId: String?
    let completed: Bool?
    let typeErrors: [String: String]

    private enum CodingKeys: String, CodingKey {
        case title, description, dueDate, priority, assigneeId, completed
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var typeErrors: [String: String] = [:]

        func decodeField<Value: Decodable>(_ key: CodingKeys, as type: Value.Type, expected: String) -> Value? {
            guard container.contains(key), (try? container.decodeNil(forKey: key)) == false else {
                return nil
            }
            if let value = try? container.decode(Value.self, forKey: key) {
                return value
            }
            typeErrors[key.stringValue] = "\(key.stringValue) must be \(expected)."
            return nil
        }

        title = decodeField(.title, as: String.self, expected: "a string")
        description = decodeField(.description, as: String.self, expected: "a string")
        dueDate = decodeField(.dueDate, as: String.self, expected: "a date string in YYYY-MM-DD format or null")
        priority = decodeField(.priority, as: String.self, expected: "a string")
        assigneeId = decodeField(.assigneeId, as: String.self, expected: "a string")
        completed = decodeField(.completed, as: Bool.self, expected: "a boolean")
        self.typeErrors = typeErrors
    }

    func validated() throws -> TaskModel {
        var errors = typeErrors

        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if errors["title"] == nil {
            if trimmedTitle.isEmpty {
                errors["title"] = "Title is required."
            } else if trimmedTitle.count > Self.maxTitleLength {
                errors["title"] = "Title must be \(Self.maxTitleLength) characters or fewer."
            }
        }

        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedDescription, trimmedDescription.count > Self.maxDescriptionLength {
            errors["description"] = "Description must be \(Self.maxDescriptionLength) characters or fewer."
        }

        if let dueDate, !DueDate.isValid(dueDate) {
            errors["dueDate"] = "Due date must be a valid date in YYYY-MM-DD format."
        }

        let parsedPriority = priority.flatMap(TaskPriority.init(rawValue:))
        if errors["priority"] == nil, parsedPriority == nil {
            errors["priority"] = priority == nil
                ? "Priority is required."
                : "Priority must be one of: \(TaskPriority.allowedValuesDescription)."
        }

        let parsedAssignee = assigneeId.flatMap(Assignee.init(rawValue:))
        if errors["assigneeId"] == nil, parsedAssignee == nil {
            errors["assigneeId"] = assigneeId == nil
                ? "Assignee is required."
                : "Assignee must be one of: \(Assignee.allowedValuesDescription)."
        }

        guard errors.isEmpty, let parsedPriority, let parsedAssignee else {
            throw ValidationFailure(fieldErrors: errors)
        }

        return TaskModel(
            title: trimmedTitle,
            details: trimmedDescription?.isEmpty == false ? trimmedDescription : nil,
            dueDate: dueDate,
            priority: parsedPriority,
            assigneeId: parsedAssignee,
            completed: completed ?? false
        )
    }
}
