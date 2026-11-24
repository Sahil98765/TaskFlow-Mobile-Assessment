import SwiftUI

struct OverdueBadge: View {
    var body: some View {
        Text("Overdue")
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red, in: Capsule())
            .fixedSize()
    }
}
