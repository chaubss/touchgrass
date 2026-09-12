import SwiftUI

/// Seven thin bars, no axes, no labels. It answers one question — was this a
/// busy week or a quiet one — and nothing else.
struct SparklineView: View {
    let values: [Int]

    private var scale: Int {
        max(values.map(abs).max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(value >= 0 ? Palette.tartan : Palette.ash.opacity(0.5))
                        .frame(height: max(3, CGFloat(abs(value)) / CGFloat(scale) * 44))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 48)
        .accessibilityLabel("Karma movement over the last seven days")
    }
}
