import SwiftUI

/// The app has exactly one accent. If something needs emphasis and isn't the
/// accent, it gets there with weight or space instead of a second hue.
enum Palette {
    static let paper       = Color(red: 0.973, green: 0.961, blue: 0.937) // #F8F5EF
    static let surface     = Color.white
    static let ink         = Color(red: 0.110, green: 0.094, blue: 0.078) // #1C1814
    static let ash         = Color(red: 0.478, green: 0.451, blue: 0.416) // #7A736A
    static let rule        = Color(red: 0.890, green: 0.863, blue: 0.820) // #E3DCD1
    static let tartan      = Color(red: 0.769, green: 0.071, blue: 0.188) // #C41230
    static let tartanDeep  = Color(red: 0.549, green: 0.047, blue: 0.133) // #8C0C22
}

enum Metrics {
    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 10
    static let controlHeight: CGFloat = 52
}

extension View {
    /// Page background. Applied once per tab root, never nested.
    func paperBackground() -> some View {
        self.background(Palette.paper.ignoresSafeArea())
    }

    func cardSurface(radius: CGFloat = Metrics.cardRadius) -> some View {
        self
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.rule, lineWidth: 1)
            )
    }
}
