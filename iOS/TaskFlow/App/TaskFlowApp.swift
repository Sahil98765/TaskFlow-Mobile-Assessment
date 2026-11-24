import SwiftUI

@main
struct TaskFlowApp: App {
    @State private var taskListViewModel = TaskListViewModel(
        service: TaskService(client: APIClient(baseURL: AppConfiguration.apiBaseURL))
    )

    var body: some Scene {
        WindowGroup {
            TaskListView(viewModel: taskListViewModel)
        }
    }
}
