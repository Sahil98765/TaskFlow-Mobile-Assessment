import Foundation
import Testing
@testable import TaskFlow

@MainActor
struct TaskListViewModelTests {
    @Test func loadsTasksForTheSelectedFilter() async {
        let task = TaskItem.fixture(assignee: .rohan)
        let service = MockTaskService(fetchHandler: { filter in
            filter.assignee == .rohan ? [task] : []
        })
        let viewModel = TaskListViewModel(service: service)
        viewModel.filter.assignee = .rohan

        await viewModel.loadIfNeeded()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.visibleTasks == [task])
    }

    @Test func showsErrorStateWhenInitialLoadFails() async {
        let service = MockTaskService(fetchHandler: { _ in throw APIError.network(.cannotConnectToHost) })
        let viewModel = TaskListViewModel(service: service)

        await viewModel.loadIfNeeded()

        guard case .failed = viewModel.loadState else {
            Issue.record("Expected failed state, got \(viewModel.loadState)")
            return
        }
        #expect(viewModel.tasks.isEmpty)
    }

    @Test func keepsTasksAndShowsAlertWhenRefreshFails() async {
        let task = TaskItem.fixture()
        let shouldFail = LockedFlag()
        let service = MockTaskService(fetchHandler: { _ in
            if shouldFail.value { throw APIError.network(.timedOut) }
            return [task]
        })
        let viewModel = TaskListViewModel(service: service)
        await viewModel.loadIfNeeded()

        shouldFail.value = true
        await viewModel.refresh()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.tasks == [task])
        #expect(viewModel.alertMessage != nil)
    }

    @Test func toggleKeepsServerResultOnSuccess() async {
        let task = TaskItem.fixture(completed: false)
        let completedTask = task.togglingCompletion()
        let service = MockTaskService(
            fetchHandler: { _ in [task] },
            toggleHandler: { _ in completedTask }
        )
        let viewModel = TaskListViewModel(service: service)
        await viewModel.loadIfNeeded()

        await viewModel.toggleCompletion(of: task.id)

        #expect(viewModel.task(withID: task.id)?.completed == true)
        #expect(!viewModel.isUpdating(task.id))
        #expect(viewModel.alertMessage == nil)
    }

    @Test func toggleRollsBackWhenServerRejects() async {
        let task = TaskItem.fixture(completed: false)
        let service = MockTaskService(
            fetchHandler: { _ in [task] },
            toggleHandler: { _ in throw APIError.server(statusCode: 500, reason: "Something went wrong.", fieldErrors: [:]) }
        )
        let viewModel = TaskListViewModel(service: service)
        await viewModel.loadIfNeeded()

        await viewModel.toggleCompletion(of: task.id)

        #expect(viewModel.task(withID: task.id)?.completed == false)
        #expect(viewModel.alertMessage != nil)
    }

    @Test func completedTaskLeavesActiveFilterButStaysAvailableForDetail() async {
        let task = TaskItem.fixture(completed: false)
        let completedTask = task.togglingCompletion()
        let service = MockTaskService(
            fetchHandler: { _ in [task] },
            toggleHandler: { _ in completedTask }
        )
        let viewModel = TaskListViewModel(service: service)
        viewModel.filter.status = .active
        await viewModel.loadIfNeeded()

        await viewModel.toggleCompletion(of: task.id)

        #expect(viewModel.visibleTasks.isEmpty)
        #expect(viewModel.task(withID: task.id)?.completed == true)
    }

    @Test func insertedTaskIsSortedByDueDate() async {
        let existing = TaskItem.fixture(title: "Later", dueDate: "2026-12-10")
        let viewModel = TaskListViewModel(service: MockTaskService(fetchHandler: { _ in [existing] }))
        await viewModel.loadIfNeeded()

        viewModel.insert(.fixture(title: "Sooner", dueDate: "2026-12-01"))

        #expect(viewModel.visibleTasks.map(\.title) == ["Sooner", "Later"])
    }
}

final class LockedFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = false

    var value: Bool {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }
}
