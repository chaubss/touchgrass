import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(KarmaStore.self) private var store
    let onEarnKarma: () -> Void

    @State private var showGiveSheet = false
    @State private var showExplainer = false
    @State private var toast: Toast?
    @State private var freshEntryID: LedgerEntry.ID?

    private var recent: [LedgerEntry] { Array(store.ledger.prefix(6)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    greeting
                    balance
                    buttons
                    allowance
                    recentSection
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 32)
            }
            .paperBackground()
            .navigationTitle("Karma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AvatarView(initials: store.currentUser.initials, size: 30, isCurrentUser: true)
                }
            }
        }
        .toast($toast)
        .sheet(isPresented: $showGiveSheet) {
            GiveKarmaSheet { recipientName in
                toast = Toast(message: "Karma given to \(recipientName)")
                freshEntryID = store.ledger.first?.id
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    withAnimation(.easeOut(duration: 0.5)) { freshEntryID = nil }
                }
            }
        }
        .sheet(isPresented: $showExplainer) { AllowanceExplainer() }
    }

    private var greeting: some View {
        HStack {
            Text("Hello, \(store.currentUser.fullName.split(separator: " ").first.map(String.init) ?? "there")")
                .font(.uiLabel)
                .foregroundStyle(Palette.ash)
            Spacer()
            Text(Date(), format: .dateTime.month(.abbreviated).day())
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var balance: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Good comes\naround.")
                        .font(.serif(30, .medium))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("A little kindness. A lasting ripple.")
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                KarmaBloom()
                    .frame(width: 116, height: 130)
            }

            Rectangle().fill(Palette.tartan.opacity(0.16)).frame(height: 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your earned karma")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    KarmaAmountText(value: store.currentUser.wallet, size: 44)
                        .accessibilityLabel("\(store.currentUser.wallet) karma in your wallet")
                    Text("karma")
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ash)
                }
            }
        }
        .padding(22)
        .background(
            LinearGradient(colors: [Color(red: 0.97, green: 0.89, blue: 0.85),
                                    Color(red: 0.98, green: 0.94, blue: 0.87)],
                           startPoint: .topTrailing, endPoint: .bottomLeading)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Palette.tartan.opacity(0.1), lineWidth: 1))
        .padding(.bottom, 14)
    }

    private var buttons: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { showGiveSheet = true } label: {
                actionLabel("Give karma", subtitle: "Make someone's day", symbol: "heart", isPrimary: true)
            }
                .disabled(!store.canAfford(amount: KarmaRules.minGrant))

            Button(action: onEarnKarma) {
                actionLabel("Earn karma", subtitle: "Find your next event", symbol: "arrow.up.right", isPrimary: false)
            }
        }
        .buttonStyle(HomeActionStyle())
        .padding(.bottom, 20)
    }

    private func actionLabel(_ title: String, subtitle: String, symbol: String, isPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.uiButton)
                Text(subtitle).font(.system(size: 11))
                    .opacity(0.8)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .padding(16)
        .foregroundStyle(isPrimary ? Color.white : Palette.ink)
        .background(isPrimary ? Palette.tartan : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isPrimary ? Color.clear : Palette.rule, lineWidth: 1))
    }

    private var allowance: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift")
                    .foregroundStyle(Palette.tartan)
                Text("Kindness to share")
                    .font(.serif(18, .medium))
                    .foregroundStyle(Palette.ink)
            }
            AllowanceMeter(remaining: store.currentUser.allowanceRemaining,
                           total: KarmaRules.monthlyAllowance) { showExplainer = true }
        }
        .padding(16)
        .cardSurface(radius: 20)
        .padding(.bottom, 28)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "Your ripple effect", trailing: "Recent activity")
                .padding(.bottom, 6)

            if recent.isEmpty {
                Text("Nothing yet. Recognise someone and it shows up here.")
                    .font(.uiLabel)
                    .foregroundStyle(Palette.ash)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, entry in
                    LedgerRow(entry: entry, isFresh: entry.id == freshEntryID)
                    if index < recent.count - 1 { WovenRule() }
                }
            }
        }
    }
}

/// Native vector artwork: overlapping loops echo the cycle of giving and receiving.
private struct KarmaBloom: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for index in 0..<12 {
                var petal = context
                petal.translateBy(x: center.x, y: center.y)
                petal.rotate(by: .degrees(Double(index) * 30))
                let shape = Path(ellipseIn: CGRect(x: -18, y: -55, width: 36, height: 70))
                petal.fill(shape, with: .color(Palette.tartan.opacity(0.035)))
                petal.stroke(shape, with: .color(Palette.tartan.opacity(0.7)), lineWidth: 0.8)
            }
            let core = Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20))
            context.fill(core, with: .color(Palette.tartan))
        }
        .accessibilityHidden(true)
    }
}

private struct HomeActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AllowanceExplainer: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How giving works")
                .font(.sectionTitle)
                .foregroundStyle(Palette.ink)

            Text("Your balance is karma you've received or earned at events. Giving karma transfers it from your balance to another student. You can also spend your balance in Redeem.")
                .font(.uiBody)
                .foregroundStyle(Palette.ink)

            Text("You can give up to \(KarmaRules.monthlyAllowance) karma each month, with a limit of \(KarmaRules.maxGrant) per recognition. Each gift reduces both your balance and your remaining monthly allowance. You can never give more than you have.")
                .font(.uiBody)
                .foregroundStyle(Palette.ink)

            Text("The giving allowance resets on the first of each month and doesn't roll over. Resetting it doesn't add karma to your balance.")
                .font(.uiLabel)
                .foregroundStyle(Palette.ash)

            Spacer()

            Button("Got it") { dismiss() }
                .buttonStyle(FilledButtonStyle())
        }
        .padding(Metrics.gutter)
        .paperBackground()
        .presentationDetents([.height(400)])
    }
}
