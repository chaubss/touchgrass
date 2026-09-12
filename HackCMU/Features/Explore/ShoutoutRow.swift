import SwiftUI
import UIKit

/// Not a card. Shout-outs are a woven list, so the feed reads as one continuous
/// wall rather than a stack of identical tiles.
struct ShoutoutRow: View {
    @Environment(KarmaStore.self) private var store
    let grant: KarmaGrant
    var onTapPerson: (Student.ID) -> Void

    private var giver: Student? { store.student(grant.from) }
    private var receiver: Student? { store.student(grant.to) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(initials: giver?.initials ?? "?", size: 40,
                       isCurrentUser: grant.from == store.currentUserID)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 0) {
                    Text(grant.from == store.currentUserID ? "You" : (giver?.fullName ?? "Someone"))
                        .font(.uiBodyMedium)
                        .foregroundStyle(Palette.ink)
                        .onTapGesture { onTapPerson(grant.from) }
                    Text(" recognised ")
                        .font(.uiBody)
                        .foregroundStyle(Palette.ash)
                    Text(grant.to == store.currentUserID ? "you" : (receiver?.fullName ?? "someone"))
                        .font(.uiBodyMedium)
                        .foregroundStyle(Palette.ink)
                        .onTapGesture { onTapPerson(grant.to) }
                }
                .lineLimit(2)

                Text(grant.reason)
                    .font(.uiBody)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                HStack(spacing: 10) {
                    Label(grant.category.label, systemImage: grant.category.symbol)
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)

                    Text(grant.createdAt.relativeShort)
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                        .monospacedDigit()

                    Spacer()

                    Button {
                        store.toggleCheer(grant.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: grant.cheeredByMe ? "hands.clap.fill" : "hands.clap")
                                .font(.system(size: 13))
                                .symbolEffect(.bounce, value: grant.cheeredByMe)
                            Text("\(grant.cheers)")
                                .font(.uiCaption)
                                .monospacedDigit()
                        }
                        .foregroundStyle(grant.cheeredByMe ? Palette.tartan : Palette.ash)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 1)
            }

            KarmaChip(amount: grant.amount)
        }
        .padding(.vertical, 15)
    }
}
