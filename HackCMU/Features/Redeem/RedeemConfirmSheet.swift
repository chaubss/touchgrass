import SwiftUI
import UIKit

struct RedeemConfirmSheet: View {
    @Environment(KarmaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let option: RedemptionOption
    let onRedeemed: (String) -> Void

    @State private var donation = 100
    @State private var code: String?
    @State private var donated = false
    @State private var celebrating = false
    @State private var copied = false

    private var cost: Int { option.isOpenAmount ? donation : option.cost }
    private var resulting: Int { store.currentUser.wallet - cost }
    private var affordable: Bool { resulting >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let code {
                codeState(code)
            } else if donated {
                donatedState
            } else {
                confirmState
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
        .overlay(ConfettiView(isActive: celebrating))
        .presentationDetents([.height(option.isOpenAmount ? 470 : 420)])
    }

    // MARK: - States

    private var confirmState: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: option.symbol)
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Palette.tartan)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Palette.tartan.opacity(0.08)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.sectionTitle)
                        .foregroundStyle(Palette.ink)
                    Text(option.detail)
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if option.isOpenAmount {
                VStack(alignment: .leading, spacing: 10) {
                    Text("How much")
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ash)
                    HStack(spacing: 8) {
                        ForEach([50, 100, 250, 500], id: \.self) { value in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    donation = value
                                }
                            } label: {
                                Chip(title: value.formatted(),
                                     isSelected: donation == value,
                                     isEnabled: value <= store.currentUser.wallet)
                            }
                            .buttonStyle(.plain)
                            .disabled(value > store.currentUser.wallet)
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                balanceRow("Now", store.currentUser.wallet)
                WovenRule()
                balanceRow("After", resulting)
            }

            Spacer(minLength: 0)

            Button(option.category == .charity ? "Donate \(cost) karma" : "Redeem for \(cost) karma") {
                let result = store.redeem(option, amount: option.isOpenAmount ? donation : nil)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.easeIn(duration: 0.2)) { celebrating = true }

                if option.category == .charity {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { donated = true }
                    onRedeemed("Donated to \(option.title)")
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { code = result }
                    onRedeemed("Redeemed \(option.title)")
                }

                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation(.easeOut(duration: 0.4)) { celebrating = false }
                }
            }
            .buttonStyle(FilledButtonStyle())
            .disabled(!affordable)

            if !affordable {
                Text("You need \(abs(resulting)) more karma.")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.tartan)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func codeState(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Redeemed")
                .font(.sectionTitle)
                .foregroundStyle(Palette.ink)

            Text("Show this at the counter. It's also in your profile history.")
                .font(.uiLabel)
                .foregroundStyle(Palette.ash)

            VStack(spacing: 10) {
                Text(code)
                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.ink)
                Text(option.title)
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .stroke(Palette.tartan.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            )

            Spacer(minLength: 0)

            Button(copied ? "Copied" : "Copy code") {
                UIPasteboard.general.string = code
                withAnimation(.easeOut(duration: 0.2)) { copied = true }
            }
            .buttonStyle(OutlinedButtonStyle())

            Button("Done") { dismiss() }
                .buttonStyle(FilledButtonStyle())
        }
    }

    private var donatedState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Thank you")
                .font(.sectionTitle)
                .foregroundStyle(Palette.ink)

            Text("\(cost) karma went to \(option.title). \(option.detail).")
                .font(.uiBody)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Campus total this term")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
                KarmaAmountText(value: store.charityTotal, size: 30)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Metrics.gutter)
            .cardSurface()

            Spacer(minLength: 0)

            Button("Done") { dismiss() }
                .buttonStyle(FilledButtonStyle())
        }
    }

    private func balanceRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
                .font(.uiLabel)
                .foregroundStyle(Palette.ash)
            Spacer()
            KarmaAmountText(value: value, size: 20, weight: .medium,
                            color: value < 0 ? Palette.tartan : Palette.ink)
        }
        .padding(.vertical, 11)
    }
}
