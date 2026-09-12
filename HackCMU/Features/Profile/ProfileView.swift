import SwiftUI

struct ProfileView: View {
    @Environment(KarmaStore.self) private var store

    /// nil means the signed-in user's own profile.
    var student: Student? = nil

    @State private var segment: LedgerEntry.Kind = .received
    @State private var isFollowing = false

    private var person: Student { student ?? store.currentUser }
    private var isMe: Bool { person.id == store.currentUserID }

    var body: some View {
        Group {
            if isMe {
                NavigationStack { content }
            } else {
                content
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                identity
                karmaBlock
                stats
                if isMe { ProfileBadgesView() }
                if isMe { history } else { theirShoutouts }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .paperBackground()
        .navigationTitle(isMe ? "Profile" : person.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                AvatarView(initials: person.initials, size: 72, isCurrentUser: isMe)

                VStack(alignment: .leading, spacing: 4) {
                    Text(person.fullName)
                        .font(.serif(24, .medium))
                        .foregroundStyle(Palette.ink)
                    Text(person.andrewID)
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ash)
                    Text(person.program)
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 20) {
                countLabel(person.followers, "followers")
                countLabel(person.following, "following")
                Spacer()
                if !isMe {
                    Button(isFollowing ? "Following" : "Follow") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isFollowing.toggle()
                        }
                    }
                    .font(.uiLabel.weight(.semibold))
                    .foregroundStyle(isFollowing ? Palette.ash : Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(isFollowing ? Color.clear : Palette.tartan)
                    )
                    .overlay(
                        Capsule().stroke(isFollowing ? Palette.rule : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func countLabel(_ value: Int, _ label: String) -> some View {
        HStack(spacing: 5) {
            Text(value.formatted())
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
        }
    }

    private var karmaBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isMe ? "Your karma" : "Karma")
                    .font(.uiLabel)
                    .foregroundStyle(Palette.ash)
                KarmaAmountText(value: person.wallet, size: 38)
            }

            if isMe {
                SparklineView(values: store.weekSparkline)
                Text("Last seven days")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat(isMe ? store.karmaGivenTotal : 0, "karma given")
            divider
            stat(isMe ? store.eventsAttended : 0, "events attended")
            divider
            stat(isMe ? store.shoutoutsReceived : receivedCount, "shout-outs")
        }
    }

    private var receivedCount: Int {
        store.grants.filter { $0.to == person.id && $0.isPublic }.count
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(value.formatted())
                .font(.serif(22, .medium))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(.uiCaption)
                .foregroundStyle(Palette.ash)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Palette.rule).frame(width: 1, height: 34)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("History", selection: $segment.animation(.easeOut(duration: 0.2))) {
                Text("Received").tag(LedgerEntry.Kind.received)
                Text("Given").tag(LedgerEntry.Kind.given)
                Text("Events").tag(LedgerEntry.Kind.event)
                Text("Redeemed").tag(LedgerEntry.Kind.redeemed)
            }
            .pickerStyle(.segmented)

            let entries = store.history(kind: segment)
            if entries.isEmpty {
                Text(emptyMessage(for: segment))
                    .font(.uiLabel)
                    .foregroundStyle(Palette.ash)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 28)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        LedgerRow(entry: entry)
                        if index < entries.count - 1 { WovenRule() }
                    }
                }
            }
        }
    }

    private func emptyMessage(for kind: LedgerEntry.Kind) -> String {
        switch kind {
        case .received: return "No one has recognised you yet. Do something helpful — it travels."
        case .given:    return "You haven't given any karma. You have \(store.currentUser.allowanceRemaining) waiting."
        case .event:    return "No events yet. Check the map for what's on near you."
        case .redeemed: return "Nothing redeemed yet."
        }
    }

    private var theirShoutouts: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "Recognised for")
                .padding(.bottom, 4)

            let theirs = store.grants
                .filter { $0.to == person.id && $0.isPublic }
                .sorted { $0.createdAt > $1.createdAt }

            if theirs.isEmpty {
                Text("Nothing public yet.")
                    .font(.uiLabel)
                    .foregroundStyle(Palette.ash)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(theirs.enumerated()), id: \.element.id) { index, grant in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(grant.reason)
                            .font(.uiBody)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            Text("from \(store.name(grant.from))")
                                .font(.uiCaption)
                                .foregroundStyle(Palette.ash)
                            Spacer()
                            KarmaChip(amount: grant.amount)
                        }
                    }
                    .padding(.vertical, 14)
                    if index < theirs.count - 1 { WovenRule() }
                }
            }
        }
    }
}
