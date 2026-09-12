import SwiftUI

struct ProfileBadgesView: View {
    @Environment(KarmaStore.self) private var store

    private var earned: [BadgeProgress] { store.badgeProgress.filter(\.earned) }
    private var pending: [BadgeProgress] {
        store.badgeProgress.filter { !$0.earned }.sorted {
            if $0.fraction == $1.fraction { return $0.id.rawValue < $1.id.rawValue }
            return $0.fraction > $1.fraction
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Your badges", trailing: "\(earned.count) of \(KarmaBadge.allCases.count) earned")
                Text("Little milestones. Real impact.")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)

                if earned.isEmpty {
                    Text("Your collection starts with one kind act. Give someone karma to earn First Ripple.")
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ash)
                        .padding(16)
                        .cardSurface()
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12, alignment: .top)], spacing: 12) {
                        ForEach(earned) { progress in
                            VStack(spacing: 10) {
                                BadgeEmblem(badge: progress.badge, earned: true)
                                    .frame(width: 78, height: 86)
                                Text(progress.badge.title)
                                    .font(.serif(17, .medium))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text(progress.badge.requirement)
                                    .font(.uiCaption)
                                    .foregroundStyle(Palette.ash)
                                    .lineLimit(2)
                                    .frame(height: 34, alignment: .top)
                                Spacer(minLength: 0)
                                Label("Earned", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Palette.tartan)
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .padding(16)
                            .cardSurface()
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "In progress", trailing: "\(pending.count) to unlock")
                if pending.isEmpty {
                    Text("Collection complete. You've earned every badge!")
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ash)
                }
                if !pending.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(pending) { progress in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 12) {
                                        BadgeEmblem(badge: progress.badge, earned: false)
                                            .frame(width: 40, height: 44)
                                        Text(progress.badge.title)
                                            .font(.serif(18, .medium))
                                            .foregroundStyle(Palette.ink)
                                            .lineLimit(1)
                                    }
                                    HStack(spacing: 12) {
                                        ProgressView(value: progress.fraction)
                                            .tint(Palette.tartan)
                                        Text("\(progress.completed) / \(progress.badge.target)")
                                            .font(.uiCaption.monospacedDigit())
                                            .foregroundStyle(Palette.ink)
                                            .fixedSize()
                                    }
                                    Text(progress.nextStep)
                                        .font(.uiCaption)
                                        .foregroundStyle(Palette.ash)
                                        .lineLimit(3)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer(minLength: 0)
                                }
                                .padding(16)
                                .frame(height: 174)
                                .containerRelativeFrame(.horizontal) { width, _ in
                                    min(320, width * 0.88)
                                }
                                .cardSurface()
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(progress.badge.title). \(progress.badge.requirement) \(progress.completed) of \(progress.badge.target). \(progress.nextStep)")
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.vertical, 1)
                    }
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                }
            }
        }
    }
}

/// Enamel-pin styling built with native shapes, crisp at every display size.
private struct BadgeEmblem: View {
    let badge: KarmaBadge
    let earned: Bool

    private var symbol: String {
        switch badge {
        case .firstRipple: return "water.waves"
        case .clutchScotty: return "dog.fill"
        case .bugWhisperer: return "ladybug.fill"
        case .touchGrass: return "shoeprints.fill"
        case .pantryPal: return "basket.fill"
        case .fullCircle: return "arrow.triangle.2.circlepath"
        }
    }

    private var accent: Color {
        guard earned else { return Palette.ash }
        switch badge {
        case .touchGrass, .pantryPal: return Color(red: 0.24, green: 0.43, blue: 0.34)
        case .firstRipple: return Color(red: 0.25, green: 0.43, blue: 0.57)
        case .fullCircle: return Color(red: 0.62, green: 0.39, blue: 0.14)
        default: return Palette.tartan
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                RoundedRectangle(cornerRadius: width * 0.32)
                    .fill(earned ? accent.opacity(0.12) : Palette.paper)
                RoundedRectangle(cornerRadius: width * 0.32)
                    .strokeBorder(accent.opacity(earned ? 0.65 : 0.25), lineWidth: 2)
                RoundedRectangle(cornerRadius: width * 0.25)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1)
                    .padding(5)
                Image(systemName: symbol)
                    .font(.system(size: width * 0.38, weight: .medium))
                    .foregroundStyle(accent)
                Image(systemName: earned ? "sparkle" : "lock.fill")
                    .font(.system(size: width * 0.14, weight: .semibold))
                    .foregroundStyle(accent)
                    .offset(y: width * 0.34)
            }
        }
        .accessibilityHidden(true)
    }
}
