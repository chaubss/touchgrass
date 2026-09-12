import SwiftUI

struct AllowanceMeter: View {
    let remaining: Int
    let total: Int
    var onTap: () -> Void = {}

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(remaining) / Double(total)))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.rule)
                        Capsule()
                            .fill(Palette.tartan)
                            .frame(width: max(6, geo.size.width * fraction))
                    }
                }
                .frame(height: 6)
                .animation(.easeInOut(duration: 0.6), value: remaining)

                HStack(spacing: 6) {
                    Text("\(remaining.formatted()) of \(total.formatted()) left to give this month")
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ash)
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.ash.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Allowance. \(remaining) of \(total) karma left to give this month. Tap to learn how this works.")
    }
}
