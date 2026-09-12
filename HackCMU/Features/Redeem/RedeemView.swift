import SwiftUI

struct RedeemView: View {
    @Environment(KarmaStore.self) private var store

    @State private var selected: RedemptionOption?
    @State private var toast: Toast?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    header

                    ForEach(RedemptionCategory.allCases) { category in
                        let options = store.catalog.filter { $0.category == category }
                        if !options.isEmpty {
                            shelf(category: category, options: options)
                        }
                    }

                    charityNote
                }
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .paperBackground()
            .navigationTitle("Redeem")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toast($toast)
        .sheet(item: $selected) { option in
            RedeemConfirmSheet(option: option) { message in
                toast = Toast(message: message, symbol: "gift")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("You have")
                .font(.uiLabel)
                .foregroundStyle(Palette.ash)
            KarmaAmountText(value: store.currentUser.wallet, size: 34)
            Text("Earned karma only. Your monthly giving allowance stays separate.")
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
                .padding(.top, 2)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 8)
    }

    private func shelf(category: RedemptionCategory, options: [RedemptionOption]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                SectionHeader(title: category.label)
                Text(category.blurb)
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }
            .padding(.horizontal, Metrics.gutter)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                    ForEach(options) { option in
                        Button {
                            selected = option
                        } label: {
                            RedemptionCard(
                                option: option,
                                shortfall: store.shortfall(for: option.cost)
                            )
                        }
                        .buttonStyle(.plain)
                    }
            }
            .padding(.horizontal, Metrics.gutter)
        }
    }

    private var charityNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Students have donated \(store.charityTotal.formatted()) karma this term.")
                .font(.uiLabel)
                .foregroundStyle(Palette.ink)
            Text("Every karma is valued at about two cents.")
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .padding(.horizontal, Metrics.gutter)
    }
}

struct RedemptionCard: View {
    let option: RedemptionOption
    let shortfall: Int

    private var affordable: Bool { shortfall == 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(1.6, contentMode: .fit)
                .overlay {
                if let imageName = option.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(affordable ? Palette.tartan.opacity(0.08) : Palette.rule.opacity(0.45))
                    Image(systemName: option.symbol)
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(affordable ? Palette.tartan : Palette.ash)
                }
            }
            .background(Palette.paper)
            .clipped()
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(option.title)
                    .font(.serif(17, .medium))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(option.detail)
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(option.isOpenAmount ? "Any amount" : "\(option.cost.formatted())")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Palette.ink)
                    if !option.isOpenAmount {
                        Text("karma")
                            .font(.uiCaption)
                            .foregroundStyle(Palette.ash)
                    }
                }
                .padding(.top, 8)

                if !affordable {
                    Text("You need \(shortfall.formatted()) more")
                        .font(.uiCaption)
                        .foregroundStyle(Palette.tartan)
                } else if let remaining = option.remaining, remaining <= 15 {
                    Text("\(remaining) left")
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Palette.surface)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .stroke(Palette.rule, lineWidth: 1)
        )
    }
}
