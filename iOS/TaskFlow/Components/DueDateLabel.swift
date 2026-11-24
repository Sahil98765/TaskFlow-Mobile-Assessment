import SwiftUI

struct DueDateLabel: View {
    let task: TaskItem
    var showsOverdueBadge = true

    var body: some View {
        let isOverdue = task.isOverdue()
        HStack(spacing: 6) {
            Label(task.dueDateText, systemImage: task.dueDay == nil ? "calendar.badge.minus" : "calendar")
                .labelStyle(.compact)
                .lineLimit(1)
                .foregroundStyle(isOverdue ? Color.red : Color.secondary)
            if isOverdue && showsOverdueBadge {
                OverdueBadge()
            }
        }
        .accessibilityElement(children: .combine)
    }
}
