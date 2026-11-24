import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isUpdating: Bool
    let onToggleCompletion: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            CompletionToggle(
                isCompleted: task.completed,
                isUpdating: isUpdating,
                action: onToggleCompletion
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.body.weight(.medium))
                    .strikethrough(task.completed)
                    .foregroundStyle(task.completed ? Color.secondary : Color.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    DueDateLabel(task: task)
                    Spacer(minLength: 4)
                    PriorityBadge(priority: task.priority)
                }
                .font(.caption)

                Label(task.assigneeId.name, systemImage: "person")
                    .labelStyle(.compact)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    List(PreviewTaskService.sampleTasks) { task in
        TaskRowView(task: task, isUpdating: false, onToggleCompletion: {})
    }
    .listStyle(.plain)
}
#endif
