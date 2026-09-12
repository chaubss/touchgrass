import SwiftUI

struct LedgerRow: View {
    let entry: LedgerEntry
    /// Newly added rows glow briefly so you can see where your action landed.
    var isFresh: Bool = false

    private var amountText: String {
        if entry.kind == .given {
            return "\u{2212}\(abs(entry.allowanceDelta))"
        }
        return (entry.delta < 0 ? "\u{2212}" : "+") + abs(entry.delta).formatted()
    }

    private var amountColor: Color {
        // Direction is carried by the sign and by ink-vs-ash, never by hue.
        entry.delta > 0 ? Palette.ink : Palette.ash
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(amountText)
                .font(.system(size: 17, weight: .medium, design: .serif))
                .monospacedDigit()
                .foregroundStyle(amountColor)
                .frame(width: 58, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.uiBody)
                    .foregroundStyle(Palette.ink)
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(entry.date.relativeShort)
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Palette.tartan.opacity(isFresh ? 0.10 : 0))
        )
    }
}

extension Date {
    /// "4m", "3h", "2d" — short enough to sit at the end of a row.
    var relativeShort: String {
        let seconds = Date().timeIntervalSince(self)
        switch seconds {
        case ..<60:    return "now"
        case ..<3600:  return "\(Int(seconds / 60))m"
        case ..<86400: return "\(Int(seconds / 3600))h"
        default:       return "\(Int(seconds / 86400))d"
        }
    }
}
