import SwiftUI

struct EventListCard: View {
    let event: CampusEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                EventImage(event: event, height: 108)
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: event.category.symbol)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(14)
                    }

                if let status = event.statusLabel {
                    Text(status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.white.opacity(0.92)))
                        .padding(12)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Text(event.title)
                        .font(.serif(19, .medium))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    KarmaChip(amount: event.karmaReward)
                }

                Text(event.organizer)
                    .font(.uiLabel)
                    .foregroundStyle(Palette.ash)

                HStack(spacing: 14) {
                    Label(event.timeLabel, systemImage: "clock")
                    Label(event.venue.shortName, systemImage: "mappin")
                }
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
                .labelStyle(.titleAndIcon)
            }
            .padding(14)
        }
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .stroke(Palette.rule, lineWidth: 1)
        )
        .opacity(event.hasEnded ? 0.55 : 1)
    }
}
