import SwiftUI

struct FilledButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.uiButton)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: Metrics.controlHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled ? (configuration.isPressed ? Palette.tartanDeep : Palette.tartan)
                                    : Palette.ash.opacity(0.35))
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.uiButton)
            .foregroundStyle(isEnabled ? Palette.ink : Palette.ash)
            .frame(maxWidth: .infinity, minHeight: Metrics.controlHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(configuration.isPressed ? Palette.rule.opacity(0.5) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isEnabled ? Palette.ink : Palette.rule, lineWidth: 1.2)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct Chip: View {
    let title: String
    var isSelected: Bool = false
    var isEnabled: Bool = true

    var body: some View {
        Text(title)
            .font(.uiLabel.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.white : (isEnabled ? Palette.ink : Palette.ash.opacity(0.6)))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous)
                    .fill(isSelected ? Palette.tartan : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous)
                    .stroke(isSelected ? Color.clear : Palette.rule, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.55)
    }
}

/// Small tartan badge for karma attached to an object (an event, a grant).
struct KarmaChip: View {
    let amount: Int
    var body: some View {
        Text("+\(amount.formatted())")
            .font(.system(size: 14, weight: .semibold, design: .serif))
            .monospacedDigit()
            .foregroundStyle(Palette.tartan)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Palette.tartan.opacity(0.09)))
    }
}
