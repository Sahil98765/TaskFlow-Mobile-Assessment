import SwiftUI

struct TaskDetailView: View {
    let taskID: UUID
    let viewModel: TaskListViewModel

    var body: some View {
        Group {
            if let task = viewModel.task(withID: taskID) {
                details(for: task)
            } else {
                ContentUnavailableView(
                    "Task Unavailable",
                    systemImage: "questionmark.circle",
                    description: Text("This task is no longer in the list.")
                )
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func details(for task: TaskItem) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(task.title)
                        .font(.title2.weight(.bold))
                        .strikethrough(task.completed)
                    TaskStatusBadge(task: task)
                }
                .padding(.vertical, 4)
            }

            Section("Description") {
                if let description = task.description, !description.isEmpty {
                    Text(description)
                } else {
                    Text("No description")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Details") {
                LabeledContent("Due date") {
                    DueDateLabel(task: task)
                }
                LabeledContent("Priority") {
                    PriorityBadge(priority: task.priority)
                }
                LabeledContent("Assignee", value: task.assigneeId.name)
                LabeledContent("Status", value: task.completed ? "Completed" : "Active")
            }
        }
        .safeAreaInset(edge: .bottom) {
            completionButton(for: task)
        }
    }

    private func completionButton(for task: TaskItem) -> some View {
        Button {
            Task { await viewModel.toggleCompletion(of: task.id) }
        } label: {
            Label(
                task.completed ? "Mark as Incomplete" : "Mark as Complete",
                systemImage: task.completed ? "arrow.uturn.backward.circle" : "checkmark.circle"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(task.completed ? .gray : .green)
        .disabled(viewModel.isUpdating(task.id))
        .sensoryFeedback(.success, trigger: task.completed) { _, newValue in newValue }
        .padding()
        .background(.bar)
    }
}

private struct TaskStatusBadge: View {
    let task: TaskItem

    var body: some View {
        let (text, color): (String, Color) = if task.completed {
            ("Completed", .green)
        } else if task.isOverdue() {
            ("Overdue", .red)
        } else {
            ("Active", .blue)
        }
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}

#if DEBUG
#Preview {
    let viewModel = TaskListViewModel(service: PreviewTaskService())
    NavigationStack {
        TaskDetailView(taskID: PreviewTaskService.sampleTasks[0].id, viewModel: viewModel)
    }
    .task { await viewModel.loadIfNeeded() }
}
#endif
