import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        ["status": "ok"]
    }

    try app.register(collection: TaskController())
}
