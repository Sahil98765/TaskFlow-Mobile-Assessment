import Foundation
import Observation

@MainActor
@Observable
final class AddTaskViewModel: Identifiable {
    enum Field: String, CaseIterable {
        case title
        case description
        case dueDate
        case priority
        case assigneeId
    }

    var title = ""
    var description = ""
    var hasDueDate = false
    var dueDate: Date
    var priority: Priority = .medium
    var assignee: Assignee?

    private(set) var isSubmitting = false
    private(set) var fieldErrors: [Field: String] = [:]
    private(set) var requestErrorMessage: String?
    private(set) var hasEditedTitle = false

    let earliestDueDate: Date
    private let service: any TaskServicing
    private let calendar: Calendar

    init(
        service: any TaskServicing,
        defaultAssignee: Assignee? = nil,
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.service = service
        self.assignee = defaultAssignee
        self.calendar = calendar
        self.earliestDueDate = calendar.startOfDay(for: now)
        self.dueDate = now
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty && assignee != nil && !isSubmitting
    }

    var bannerMessage: String? {
        let fieldSummary = fieldErrors.isEmpty ? nil : "The server couldn't save this task. Fix the highlighted fields and try again."
        let messages = [fieldSummary, requestErrorMessage].compactMap { $0 }
        return messages.isEmpty ? nil : messages.joined(separator: " ")
    }

    func errorMessage(for field: Field) -> String? {
        if let serverMessage = fieldErrors[field] {
            return serverMessage
        }
        if field == .title, hasEditedTitle, trimmedTitle.isEmpty {
            return "Title is required."
        }
        return nil
    }

    func fieldDidChange(_ field: Field) {
        if field == .title {
            hasEditedTitle = true
        }
        fieldErrors[field] = nil
    }

    func makeRequest() -> CreateTaskRequest? {
        guard let assignee, !trimmedTitle.isEmpty else { return nil }
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return CreateTaskRequest(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            dueDate: hasDueDate ? CalendarDay(date: dueDate, calendar: calendar).isoString : nil,
            priority: priority,
            assigneeId: assignee
        )
    }

    func submit() async -> TaskItem? {
        guard canSubmit, let request = makeRequest() else {
            hasEditedTitle = true
            return nil
        }

        isSubmitting = true
        fieldErrors = [:]
        requestErrorMessage = nil
        defer { isSubmitting = false }

        do {
            return try await service.createTask(request)
        } catch {
            apply(error)
            return nil
        }
    }

    private func apply(_ error: any Error) {
        guard let apiError = error as? APIError else {
            requestErrorMessage = error.localizedDescription
            return
        }

        var unmatchedMessages: [String] = []
        for (key, message) in apiError.fieldErrors.sorted(by: { $0.key < $1.key }) {
            if let field = Field(rawValue: key) {
                fieldErrors[field] = message
            } else {
                unmatchedMessages.append(message)
            }
        }
        if apiError.fieldErrors.isEmpty {
            requestErrorMessage = apiError.localizedDescription
        } else if !unmatchedMessages.isEmpty {
            requestErrorMessage = unmatchedMessages.joined(separator: " ")
        }
    }
}
