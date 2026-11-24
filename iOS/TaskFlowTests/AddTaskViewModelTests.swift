import Foundation
import Testing
@testable import TaskFlow

@MainActor
struct AddTaskViewModelTests {
    @Test func cannotSubmitWithoutTitleOrAssignee() {
        let viewModel = AddTaskViewModel(service: MockTaskService())
        #expect(!viewModel.canSubmit)

        viewModel.title = "   "
        viewModel.assignee = .priya
        #expect(!viewModel.canSubmit)

        viewModel.title = "Write tests"
        #expect(viewModel.canSubmit)
    }

    @Test func buildsRequestWithTrimmedValuesAndLocalDueDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let lateEvening = try #require(ISO8601DateFormatter().date(from: "2026-12-02T06:30:00Z"))
        let viewModel = AddTaskViewModel(service: MockTaskService(), defaultAssignee: .rohan, calendar: calendar, now: lateEvening)
        viewModel.title = "  Ship release  "
        viewModel.description = "   "
        viewModel.hasDueDate = true
        viewModel.priority = .high

        let request = try #require(viewModel.makeRequest())

        #expect(request == CreateTaskRequest(
            title: "Ship release",
            description: nil,
            dueDate: "2026-12-01",
            priority: .high,
            assigneeId: .rohan
        ))
    }

    @Test func mapsServerValidationErrorsToFields() async {
        let service = MockTaskService(createHandler: { _ in
            throw APIError.server(
                statusCode: 400,
                reason: "Validation failed.",
                fieldErrors: ["title": "Title must be 120 characters or fewer.", "priority": "Priority must be one of: low, medium, high."]
            )
        })
        let viewModel = AddTaskViewModel(service: service, defaultAssignee: .aarav)
        viewModel.title = "Task"

        let created = await viewModel.submit()

        #expect(created == nil)
        #expect(viewModel.errorMessage(for: .title) == "Title must be 120 characters or fewer.")
        #expect(viewModel.errorMessage(for: .priority) == "Priority must be one of: low, medium, high.")
        #expect(viewModel.bannerMessage != nil)
        #expect(!viewModel.isSubmitting)
    }

    @Test func editingAFieldClearsItsServerError() async {
        let service = MockTaskService(createHandler: { _ in
            throw APIError.server(statusCode: 400, reason: "Validation failed.", fieldErrors: ["title": "Too long."])
        })
        let viewModel = AddTaskViewModel(service: service, defaultAssignee: .aarav)
        viewModel.title = "Task"
        _ = await viewModel.submit()

        viewModel.title = "Shorter"
        viewModel.fieldDidChange(.title)

        #expect(viewModel.errorMessage(for: .title) == nil)
        #expect(viewModel.bannerMessage == nil)
    }

    @Test func keepsServerMessagesThatDoNotMatchAField() async {
        let service = MockTaskService(createHandler: { _ in
            throw APIError.server(statusCode: 400, reason: "Validation failed.", fieldErrors: ["completed": "completed must be a boolean."])
        })
        let viewModel = AddTaskViewModel(service: service, defaultAssignee: .aarav)
        viewModel.title = "Task"

        _ = await viewModel.submit()

        #expect(viewModel.bannerMessage == "completed must be a boolean.")
    }

    @Test func showsGeneralMessageForNetworkFailures() async {
        let service = MockTaskService(createHandler: { _ in throw APIError.network(.cannotConnectToHost) })
        let viewModel = AddTaskViewModel(service: service, defaultAssignee: .aarav)
        viewModel.title = "Task"

        _ = await viewModel.submit()

        #expect(viewModel.bannerMessage == APIError.network(.cannotConnectToHost).localizedDescription)
    }
}
