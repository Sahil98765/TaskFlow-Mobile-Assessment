import Foundation
import Observation

@MainActor
@Observable
final class TaskListViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var filter = TaskFilter()
    var alertMessage: String?
    private(set) var tasks: [TaskItem] = []
    private(set) var loadState: LoadState = .idle
    private(set) var pendingToggleIDs: Set<UUID> = []

    private let service: any TaskServicing
    private var loadedFilter: TaskFilter?

    init(service: any TaskServicing) {
        self.service = service
    }

    var visibleTasks: [TaskItem] {
        tasks.filter(filter.matches)
    }

    func task(withID id: UUID) -> TaskItem? {
        tasks.first { $0.id == id }
    }

    func isUpdating(_ id: UUID) -> Bool {
        pendingToggleIDs.contains(id)
    }

    func resetFilters() {
        filter = TaskFilter()
    }

    func makeAddTaskViewModel() -> AddTaskViewModel {
        AddTaskViewModel(service: service, defaultAssignee: filter.assignee)
    }

    func loadIfNeeded() async {
        guard loadState != .loaded || loadedFilter != filter else { return }
        loadState = .loading
        await fetchTasks(keepingVisibleTasksOnFailure: false)
    }

    func reload() async {
        loadState = .loading
        await fetchTasks(keepingVisibleTasksOnFailure: false)
    }

    func refresh() async {
        await fetchTasks(keepingVisibleTasksOnFailure: loadedFilter == filter)
    }

    func insert(_ task: TaskItem) {
        tasks.append(task)
        tasks.sort(by: TaskItem.listOrder)
    }

    func toggleCompletion(of id: UUID) async {
        guard !pendingToggleIDs.contains(id), let index = index(of: id) else { return }

        let previousValue = tasks[index].completed
        tasks[index].completed.toggle()
        pendingToggleIDs.insert(id)
        defer { pendingToggleIDs.remove(id) }

        do {
            let updated = try await service.toggleCompletion(id: id)
            if let index = self.index(of: id) {
                tasks[index] = updated
            }
        } catch {
            guard let index = self.index(of: id) else { return }
            tasks[index].completed = previousValue
            alertMessage = "Couldn't update \"\(tasks[index].title)\". \(error.localizedDescription)"
        }
    }

    private func fetchTasks(keepingVisibleTasksOnFailure: Bool) async {
        let requestedFilter = filter
        do {
            let fetched = try await service.fetchTasks(filter: requestedFilter)
            guard requestedFilter == filter else { return }
            tasks = mergingPendingToggles(into: fetched).sorted(by: TaskItem.listOrder)
            loadedFilter = requestedFilter
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard requestedFilter == filter else { return }
            if keepingVisibleTasksOnFailure {
                loadState = .loaded
                alertMessage = error.localizedDescription
            } else {
                tasks = []
                loadedFilter = nil
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    private func mergingPendingToggles(into fetched: [TaskItem]) -> [TaskItem] {
        guard !pendingToggleIDs.isEmpty else { return fetched }
        return fetched.map { task in
            guard pendingToggleIDs.contains(task.id), let local = self.task(withID: task.id) else { return task }
            var merged = task
            merged.completed = local.completed
            return merged
        }
    }

    private func index(of id: UUID) -> Int? {
        tasks.firstIndex { $0.id == id }
    }
}
