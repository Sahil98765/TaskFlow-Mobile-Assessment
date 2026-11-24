import SwiftUI

struct ChipPicker<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var symbol: (Option) -> String? = { _ in nil }
    var tint: (Option) -> Color = { _ in .accentColor }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                chip(for: option)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(for option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            selection = option
        } label: {
            HStack(spacing: 4) {
                if let symbolName = symbol(option) {
                    Image(systemName: symbolName)
                        .imageScale(.small)
                }
                Text(label(option))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(isSelected ? tint(option) : Color(.tertiarySystemFill), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
