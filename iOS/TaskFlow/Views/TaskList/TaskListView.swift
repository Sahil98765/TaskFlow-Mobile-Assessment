import SwiftUI

struct TaskListView: View {
    @Bindable var viewModel: TaskListViewModel
    @State private var addTaskViewModel: AddTaskViewModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("TaskFlow")
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .top, spacing: 0) {
                    TaskFilterBar(filter: $viewModel.filter)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if viewModel.loadState == .loading && !viewModel.visibleTasks.isEmpty {
                            ProgressView()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Task", systemImage: "plus", action: presentAddTask)
                    }
                }
                .navigationDestination(for: TaskItem.ID.self) { taskID in
                    TaskDetailView(taskID: taskID, viewModel: viewModel)
                }
                .task(id: viewModel.filter) {
                    await viewModel.loadIfNeeded()
                }
                .sheet(item: $addTaskViewModel) { formViewModel in
                    AddTaskView(viewModel: formViewModel, onCreated: viewModel.insert)
                }
        }
        .alert("Something Went Wrong", isPresented: isShowingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .sensoryFeedback(.error, trigger: viewModel.alertMessage) { _, newValue in newValue != nil }
    }

    @ViewBuilder
    private var content: some View {
        let tasks = viewModel.visibleTasks
        if case let .failed(message) = viewModel.loadState {
            ErrorStateView(message: message) {
                Task { await viewModel.reload() }
            }
        } else if tasks.isEmpty {
            if viewModel.loadState == .loaded {
                EmptyTasksView(
                    filter: viewModel.filter,
                    clearFilters: viewModel.resetFilters,
                    addTask: presentAddTask
                )
            } else {
                LoadingStateView()
            }
        } else {
            List(tasks) { task in
                NavigationLink(value: task.id) {
                    TaskRowView(
                        task: task,
                        isUpdating: viewModel.isUpdating(task.id),
                        onToggleCompletion: { toggle(task) }
                    )
                }
                .swipeActions(edge: .leading) {
                    Button(task.completed ? "Reopen" : "Complete", systemImage: task.completed ? "arrow.uturn.backward" : "checkmark") {
                        toggle(task)
                    }
                    .tint(task.completed ? .gray : .green)
                    .disabled(viewModel.isUpdating(task.id))
                }
            }
            .listStyle(.plain)
            .animation(.default, value: tasks)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.alertMessage = nil }
            }
        )
    }

    private func presentAddTask() {
        addTaskViewModel = viewModel.makeAddTaskViewModel()
    }

    private func toggle(_ task: TaskItem) {
        Task { await viewModel.toggleCompletion(of: task.id) }
    }
}

#if DEBUG
#Preview("Task List") {
    TaskListView(viewModel: TaskListViewModel(service: PreviewTaskService()))
}

#Preview("Load Error") {
    TaskListView(viewModel: TaskListViewModel(service: PreviewTaskService(fails: true)))
}
#endif
