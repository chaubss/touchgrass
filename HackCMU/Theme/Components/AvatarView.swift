import SwiftUI

struct AvatarView: View {
    let initials: String
    var size: CGFloat = 40
    var isCurrentUser: Bool = false

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .medium, design: .serif))
            .foregroundStyle(isCurrentUser ? Color.white : Palette.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(isCurrentUser ? Palette.tartan : Palette.surface))
            .overlay(Circle().stroke(isCurrentUser ? Color.clear : Palette.rule, lineWidth: 1))
    }
}
