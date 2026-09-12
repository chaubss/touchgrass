import SwiftUI

/// A quiet divider for lists and grouped rows.
struct WovenRule: View {
    var body: some View {
        Rectangle()
            .fill(Palette.rule)
            .frame(height: 1)
        .accessibilityHidden(true)
    }
}
