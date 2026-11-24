import SwiftUI

struct CompletionToggle: View {
    let isCompleted: Bool
    let isUpdating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isCompleted ? Color.green : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .disabled(isUpdating)
        .sensoryFeedback(.success, trigger: isCompleted) { _, newValue in newValue }
        .accessibilityLabel(isCompleted ? "Mark as incomplete" : "Mark as complete")
    }
}
