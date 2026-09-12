import SwiftUI

/// One moving gradient over a skeleton. Not a per-card idle effect.
struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(0.6)
        } else {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, Palette.surface.opacity(0.9), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.55)
                        .offset(x: phase * geo.size.width * 1.6)
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1.1
                    }
                }
        }
    }
}

extension View {
    func shimmering() -> some View { modifier(Shimmer()) }
}

struct SkeletonBar: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(Palette.rule)
            .frame(width: width, height: height)
    }
}
