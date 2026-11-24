import Fluent

struct CreateTask: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(TaskModel.schema)
            .id()
            .field("title", .string, .required)
            .field("description", .string)
            .field("due_date", .string)
            .field("priority", .string, .required)
            .field("assignee_id", .string, .required)
            .field("completed", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(TaskModel.schema).delete()
    }
}
