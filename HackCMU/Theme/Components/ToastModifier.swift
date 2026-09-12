import SwiftUI

struct Toast: Equatable, Identifiable {
    let id = UUID()
    let message: String
    var symbol: String = "checkmark"

    static func == (l: Toast, r: Toast) -> Bool { l.id == r.id }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let current = toast {
                    HStack(spacing: 9) {
                        Image(systemName: current.symbol)
                            .font(.system(size: 14, weight: .semibold))
                        Text(current.message)
                            .font(.uiBodyMedium)
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Palette.ink))
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: current.id) {
                        try? await Task.sleep(for: .seconds(2.2))
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            toast = nil
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
