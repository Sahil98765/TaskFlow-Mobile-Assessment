import SwiftUI

struct AddTaskView: View {
    @Bindable var viewModel: AddTaskViewModel
    let onCreated: (TaskItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: AddTaskViewModel.Field?

    private static let assigneeOptions: [Assignee?] = Assignee.allCases.map(Optional.some)

    var body: some View {
        NavigationStack {
            Form {
                if let banner = viewModel.bannerMessage {
                    Section {
                        Label(banner, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section {
                    TextField("What needs to be done?", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .description }
                } header: {
                    Text("Title")
                } footer: {
                    FieldErrorText(message: viewModel.errorMessage(for: .title))
                }

                Section {
                    TextField("Optional", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .description)
                } header: {
                    Text("Description")
                } footer: {
                    FieldErrorText(message: viewModel.errorMessage(for: .description))
                }

                Section {
                    Toggle("Set a due date", isOn: $viewModel.hasDueDate.animation())
                    if viewModel.hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $viewModel.dueDate,
                            in: viewModel.earliestDueDate...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                } header: {
                    Text("Due Date")
                } footer: {
                    FieldErrorText(message: viewModel.errorMessage(for: .dueDate))
                }

                Section {
                    ChipPicker(
                        title: "Priority",
                        options: Priority.allCases,
                        selection: $viewModel.priority,
                        label: \.title,
                        symbol: \.symbolName,
                        tint: \.color
                    )
                } header: {
                    Text("Priority")
                } footer: {
                    FieldErrorText(message: viewModel.errorMessage(for: .priority))
                }

                Section {
                    ChipPicker(
                        title: "Assignee",
                        options: Self.assigneeOptions,
                        selection: $viewModel.assignee,
                        label: { $0?.name ?? "" },
                        tint: { $0?.color ?? .accentColor }
                    )
                } header: {
                    Text("Assignee")
                } footer: {
                    if let message = viewModel.errorMessage(for: .assigneeId) {
                        FieldErrorText(message: message)
                    } else if viewModel.assignee == nil {
                        Text("Choose who this task is for.")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(viewModel.isSubmitting)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task { await submit() }
                        }
                        .disabled(!viewModel.canSubmit)
                    }
                }
            }
            .onChange(of: viewModel.title) { viewModel.fieldDidChange(.title) }
            .onChange(of: viewModel.description) { viewModel.fieldDidChange(.description) }
            .onChange(of: viewModel.hasDueDate) { viewModel.fieldDidChange(.dueDate) }
            .onChange(of: viewModel.dueDate) { viewModel.fieldDidChange(.dueDate) }
            .onChange(of: viewModel.priority) { viewModel.fieldDidChange(.priority) }
            .onChange(of: viewModel.assignee) { viewModel.fieldDidChange(.assigneeId) }
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
    }

    private func submit() async {
        guard let task = await viewModel.submit() else { return }
        onCreated(task)
        dismiss()
    }
}

private struct FieldErrorText: View {
    let message: String?

    var body: some View {
        if let message {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

#if DEBUG
#Preview {
    AddTaskView(viewModel: AddTaskViewModel(service: PreviewTaskService()), onCreated: { _ in })
}
#endif
