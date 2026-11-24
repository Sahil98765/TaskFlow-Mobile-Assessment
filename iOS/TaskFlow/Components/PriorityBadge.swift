import SwiftUI

struct PriorityBadge: View {
    let priority: Priority

    var body: some View {
        Label(priority.title, systemImage: priority.symbolName)
            .labelStyle(.compact)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(priority.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priority.color.opacity(0.15), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(priority.title) priority")
    }
}
