import SwiftUI

struct DigestCard: View {
    @Environment(KarmaStore.self) private var store
    @Environment(\.digestVoiceService) private var voice

    let digest: WeeklyDigest?
    let isLoading: Bool
    let onRegenerate: () -> Void

    @State private var isSpeaking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading || digest == nil {
                skeleton
            } else if let digest {
                loaded(digest)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: 14) {
            SkeletonBar(width: 120, height: 10)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(height: 20)
                SkeletonBar(width: 210, height: 20)
            }
            VStack(alignment: .leading, spacing: 7) {
                SkeletonBar(height: 11)
                SkeletonBar(height: 11)
                SkeletonBar(width: 180, height: 11)
            }
        }
        .shimmering()
        .accessibilityLabel("Writing this week's summary")
    }

    private func loaded(_ digest: WeeklyDigest) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("This week on campus")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
                Spacer()
                Button(action: { toggleSpeech(digest) }) {
                    Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.tartan)
                }
                .accessibilityLabel(isSpeaking ? "Stop reading" : "Read digest aloud")
                Button(action: {
                    voice.stop()
                    isSpeaking = false
                    onRegenerate()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.tartan)
                }
                .accessibilityLabel("Regenerate recap")
            }

            HStack(spacing: 6) {
                Label("Powered by IFM", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.tartan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Palette.rule.opacity(0.6)))
                if digest.isCached {
                    Text("Cached")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Palette.ash)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().stroke(Palette.rule, lineWidth: 1))
                        .accessibilityLabel("Saved IFM recap, generated \(digest.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                } else if digest.source == .sample {
                    Text("Local recap")
                        .font(.system(size: 9))
                        .foregroundStyle(Palette.ash)
                }
            }

            if let notice = digest.notice {
                Text(notice)
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }

            Text(digest.headline)
                .font(.digestLead)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(digest.body.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.uiLabel)
                        .foregroundStyle(Palette.ink.opacity(0.82))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 0) {
                if let andrewID = digest.mostHelpfulAndrewID,
                   let student = store.student(andrewID: andrewID) {
                    pullout(label: "Peer spotlight",
                            name: student.fullName,
                            initials: student.initials,
                            note: digest.mostHelpfulNote)
                    WovenRule()
                }
                if let organizer = digest.topOrganizer {
                    pullout(label: "Organizer spotlight",
                            name: organizer,
                            initials: initials(of: organizer),
                            note: digest.topOrganizerNote)
                }
            }
            .padding(.top, 2)
        }
    }

    private func toggleSpeech(_ digest: WeeklyDigest) {
        if isSpeaking {
            voice.stop()
            isSpeaking = false
        } else {
            isSpeaking = true
            let text = ([digest.headline] + digest.body).joined(separator: ". ")
            voice.speak(text) { isSpeaking = false }
        }
    }

    private func pullout(label: String, name: String, initials: String, note: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(initials: initials, size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
                Text(name)
                    .font(.uiBodyMedium)
                    .foregroundStyle(Palette.ink)
                if let note {
                    Text(note)
                        .font(.uiCaption)
                        .foregroundStyle(Palette.ash)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return (first + last).uppercased()
    }
}
