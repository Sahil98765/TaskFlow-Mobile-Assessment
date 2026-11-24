import Fluent
import Foundation

struct SeedTasks: AsyncMigration {
    private struct SeedFile: Decodable {
        struct Task: Decodable {
            let title: String
            let description: String?
            let dueDate: String?
            let priority: TaskPriority
            let assigneeId: Assignee
            let completed: Bool
        }

        let tasks: [Task]
    }

    enum SeedError: Error {
        case missingSeedFile
    }

    func prepare(on database: any Database) async throws {
        guard let url = Bundle.module.url(forResource: "seed", withExtension: "json") else {
            throw SeedError.missingSeedFile
        }
        let seed = try JSONDecoder().decode(SeedFile.self, from: Data(contentsOf: url))
        let models = seed.tasks.map {
            TaskModel(
                title: $0.title,
                details: $0.description,
                dueDate: $0.dueDate,
                priority: $0.priority,
                assigneeId: $0.assigneeId,
                completed: $0.completed
            )
        }
        try await models.create(on: database)
    }

    func revert(on database: any Database) async throws {
        try await TaskModel.query(on: database).delete()
    }
}
