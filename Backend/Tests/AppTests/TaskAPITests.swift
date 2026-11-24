@testable import App
import XCTVapor

final class TaskAPITests: XCTestCase {
    private var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
        try await configure(app)
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    // MARK: - GET /api/tasks

    func testListReturnsAllSeededTasks() async throws {
        let tasks = try await fetchTasks()
        XCTAssertEqual(tasks.count, 15)
        XCTAssertEqual(Set(tasks.map(\.assigneeId)), [.aarav, .priya, .rohan])
        XCTAssertEqual(Set(tasks.map(\.priority)), [.low, .medium, .high])
    }

    func testTaskWithoutDueDateIsEncodedAsNullAndSortedLast() async throws {
        try await app.test(.GET, "api/tasks") { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains(#""dueDate":null"#))
            let tasks = try res.content.decode([TaskResponse].self)
            XCTAssertEqual(tasks.last?.title, "Update portfolio website")
            XCTAssertNil(tasks.last?.dueDate)
        }
    }

    func testFiltersByAssignee() async throws {
        let tasks = try await fetchTasks(query: "assignee=aarav")
        XCTAssertEqual(tasks.count, 4)
        XCTAssertTrue(tasks.allSatisfy { $0.assigneeId == .aarav })
    }

    func testFiltersByStatus() async throws {
        let active = try await fetchTasks(query: "status=active")
        let completed = try await fetchTasks(query: "status=completed")
        XCTAssertEqual(active.count, 11)
        XCTAssertEqual(completed.count, 4)
        XCTAssertTrue(active.allSatisfy { !$0.completed })
        XCTAssertTrue(completed.allSatisfy(\.completed))
    }

    func testCombinesAssigneeAndStatusFilters() async throws {
        let tasks = try await fetchTasks(query: "assignee=rohan&status=completed")
        XCTAssertEqual(tasks.map(\.title).sorted(), ["Optimise database queries", "Review pull requests"])
    }

    func testCombinedFiltersWithNoMatchesReturnEmptyList() async throws {
        let aaravCompleted = try await fetchTasks(query: "assignee=aarav&status=completed")
        XCTAssertEqual(aaravCompleted.count, 1)

        try await toggle(id: aaravCompleted[0].id)

        let afterToggle = try await fetchTasks(query: "assignee=aarav&status=completed")
        XCTAssertEqual(afterToggle, [])
    }

    func testRejectsUnknownFilterValues() async throws {
        try await app.test(.GET, "api/tasks?assignee=bob&status=done") { res async throws in
            XCTAssertEqual(res.status, .badRequest)
            let error = try res.content.decode(APIErrorResponse.self)
            XCTAssertNotNil(error.fieldErrors?["assignee"])
            XCTAssertNotNil(error.fieldErrors?["status"])
        }
    }

    // MARK: - POST /api/tasks

    func testCreatesTaskWithDefaults() async throws {
        let body = #"{"title":"  Ship build  ","priority":"high","assigneeId":"priya","dueDate":"2026-12-01"}"#
        try await app.test(.POST, "api/tasks", headers: jsonHeaders, body: ByteBuffer(string: body)) { res async throws in
            XCTAssertEqual(res.status, .created)
            let task = try res.content.decode(TaskResponse.self)
            XCTAssertEqual(task.title, "Ship build")
            XCTAssertEqual(task.dueDate, "2026-12-01")
            XCTAssertNil(task.description)
            XCTAssertFalse(task.completed)
        }
        let tasks = try await fetchTasks(query: "assignee=priya")
        XCTAssertEqual(tasks.count, 6)
    }

    func testRejectsMissingTitle() async throws {
        let error = try await createExpectingValidationError(#"{"priority":"low","assigneeId":"aarav"}"#)
        XCTAssertEqual(error.fieldErrors?["title"], "Title is required.")
    }

    func testRejectsWhitespaceOnlyTitle() async throws {
        let error = try await createExpectingValidationError(#"{"title":"   ","priority":"low","assigneeId":"aarav"}"#)
        XCTAssertEqual(error.fieldErrors?["title"], "Title is required.")
    }

    func testRejectsTitleThatIsTooLong() async throws {
        let title = String(repeating: "a", count: CreateTaskRequest.maxTitleLength + 1)
        let error = try await createExpectingValidationError(#"{"title":"\#(title)","priority":"low","assigneeId":"aarav"}"#)
        XCTAssertNotNil(error.fieldErrors?["title"])
    }

    func testRejectsInvalidPriority() async throws {
        let error = try await createExpectingValidationError(#"{"title":"Task","priority":"urgent","assigneeId":"aarav"}"#)
        XCTAssertEqual(error.fieldErrors?["priority"], "Priority must be one of: low, medium, high.")
    }

    func testRejectsInvalidDueDateAndAssignee() async throws {
        let error = try await createExpectingValidationError(#"{"title":"Task","priority":"low","assigneeId":"bob","dueDate":"2026-02-30"}"#)
        XCTAssertNotNil(error.fieldErrors?["dueDate"])
        XCTAssertNotNil(error.fieldErrors?["assigneeId"])
        XCTAssertNil(error.fieldErrors?["title"])
    }

    func testRejectsWrongFieldTypes() async throws {
        let error = try await createExpectingValidationError(#"{"title":42,"priority":"low","assigneeId":"aarav","completed":"yes"}"#)
        XCTAssertNotNil(error.fieldErrors?["title"])
        XCTAssertNotNil(error.fieldErrors?["completed"])
    }

    func testRejectsMalformedJSON() async throws {
        try await app.test(.POST, "api/tasks", headers: jsonHeaders, body: ByteBuffer(string: "{not json")) { res async throws in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertTrue(try res.content.decode(APIErrorResponse.self).error)
        }
    }

    // MARK: - PATCH /api/tasks/:id/toggle

    func testToggleFlipsCompletionBothWays() async throws {
        let activeTasks = try await fetchTasks(query: "assignee=aarav&status=active")
        let task = try XCTUnwrap(activeTasks.first)

        let completed = try await toggle(id: task.id)
        XCTAssertTrue(completed.completed)

        let reopened = try await toggle(id: task.id)
        XCTAssertFalse(reopened.completed)
    }

    func testToggleUnknownTaskReturnsNotFound() async throws {
        try await app.test(.PATCH, "api/tasks/\(UUID())/toggle") { res async in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testToggleInvalidIDReturnsBadRequest() async throws {
        try await app.test(.PATCH, "api/tasks/not-a-uuid/toggle") { res async in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    // MARK: - Helpers

    private var jsonHeaders: HTTPHeaders {
        ["Content-Type": "application/json"]
    }

    private func fetchTasks(query: String? = nil) async throws -> [TaskResponse] {
        var tasks: [TaskResponse] = []
        let path = query.map { "api/tasks?\($0)" } ?? "api/tasks"
        try await app.test(.GET, path) { res async throws in
            XCTAssertEqual(res.status, .ok)
            tasks = try res.content.decode([TaskResponse].self)
        }
        return tasks
    }

    @discardableResult
    private func toggle(id: UUID) async throws -> TaskResponse {
        var task: TaskResponse?
        try await app.test(.PATCH, "api/tasks/\(id)/toggle") { res async throws in
            XCTAssertEqual(res.status, .ok)
            task = try res.content.decode(TaskResponse.self)
        }
        return try XCTUnwrap(task)
    }

    private func createExpectingValidationError(_ body: String) async throws -> APIErrorResponse {
        var error: APIErrorResponse?
        try await app.test(.POST, "api/tasks", headers: jsonHeaders, body: ByteBuffer(string: body)) { res async throws in
            XCTAssertEqual(res.status, .badRequest)
            error = try res.content.decode(APIErrorResponse.self)
        }
        return try XCTUnwrap(error)
    }
}
