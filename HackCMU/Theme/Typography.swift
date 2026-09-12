import SwiftUI

/// New York (serif) carries the numbers and section headlines — karma is a
/// currency, and currency reads as serif. SF Pro Text does everything else.
/// Both ship with iOS, so there are no font files to bundle.
extension Font {
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let heroNumber   = Font.serif(44, .semibold)
    static let bigNumber    = Font.serif(28, .semibold)
    static let sectionTitle = Font.serif(20, .medium)
    static let digestLead   = Font.serif(22, .medium)

    static let uiBody       = Font.system(size: 17)
    static let uiBodyMedium = Font.system(size: 17, weight: .medium)
    static let uiLabel      = Font.system(size: 15)
    static let uiCaption    = Font.system(size: 13)
    static let uiButton     = Font.system(size: 17, weight: .semibold)
}

/// Sentence case everywhere. No all-caps eyebrows.
struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.sectionTitle)
                .foregroundStyle(Palette.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }
        }
    }
}
