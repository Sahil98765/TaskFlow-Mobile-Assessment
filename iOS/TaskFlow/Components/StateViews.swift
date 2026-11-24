import SwiftUI

struct LoadingStateView: View {
    var body: some View {
        ProgressView("Loading tasks…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't Load Tasks", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct EmptyTasksView: View {
    let filter: TaskFilter
    let clearFilters: () -> Void
    let addTask: () -> Void

    var body: some View {
        if filter.isDefault {
            ContentUnavailableView {
                Label("No Tasks Yet", systemImage: "checklist")
            } description: {
                Text("Tasks you add will appear here.")
            } actions: {
                Button("Add Task", action: addTask)
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView {
                Label("No Matching Tasks", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text(description)
            } actions: {
                Button("Clear Filters", action: clearFilters)
                    .buttonStyle(.bordered)
            }
        }
    }

    private var description: String {
        let statusText = filter.status == .all ? "" : "\(filter.status.title.lowercased()) "
        if let assignee = filter.assignee {
            return "\(assignee.name) has no \(statusText)tasks."
        }
        return "There are no \(statusText)tasks."
    }
}
