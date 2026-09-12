import SwiftUI

/// Any number that can change is tabular, so it doesn't jitter while it rolls.
struct KarmaAmountText: View {
    let value: Int
    var size: CGFloat = 44
    var weight: Font.Weight = .semibold
    var signed: Bool = false
    var color: Color = Palette.ink

    private var text: String {
        let magnitude = abs(value).formatted(.number.grouping(.automatic))
        guard signed else { return magnitude }
        return (value < 0 ? "\u{2212}" : "+") + magnitude
    }

    var body: some View {
        Text(text)
            .font(.serif(size, weight))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
    }
}
