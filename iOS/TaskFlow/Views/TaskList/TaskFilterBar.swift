import SwiftUI

struct TaskFilterBar: View {
    @Binding var filter: TaskFilter

    private static let assigneeOptions: [Assignee?] = [nil] + Assignee.allCases.map(Optional.some)

    var body: some View {
        VStack(spacing: 10) {
            ChipPicker(
                title: "Assignee",
                options: Self.assigneeOptions,
                selection: $filter.assignee,
                label: { $0?.name ?? "All" },
                symbol: { $0 == nil ? "person.2" : nil },
                tint: { $0?.color ?? .accentColor }
            )

            Picker("Status", selection: $filter.status) {
                ForEach(StatusFilter.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
