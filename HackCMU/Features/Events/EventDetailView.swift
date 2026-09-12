import SwiftUI
import UIKit

struct EventDetailView: View {
    @Environment(KarmaStore.self) private var store
    @Environment(LocationManager.self) private var locations

    @Environment(\.dismiss) private var dismiss

    let event: CampusEvent

    @State private var celebrating = false
    @State private var toast: Toast?

    /// Read live from the store so the button flips the moment we check in.
    private var current: CampusEvent {
        store.events.first { $0.id == event.id } ?? event
    }

    private var distance: Double? { locations.distance(to: current.venue) }

    private var block: KarmaStore.CheckInBlock? {
        store.checkInBlock(for: current, distance: distance)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EventImage(event: current, height: 240)
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: current.category.symbol)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(20)
                    }

                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text(current.title)
                                .font(.serif(27, .medium))
                                .foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            KarmaChip(amount: current.karmaReward)
                        }
                        Text(current.organizer)
                            .font(.uiLabel)
                            .foregroundStyle(Palette.ash)
                    }

                    Text(current.summary)
                        .font(.uiBody)
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    facts
                    attendance
                    checkInButton
                }
                .padding(Metrics.gutter)
                .padding(.bottom, 40)
            }
        }
        .background(Palette.paper.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) { closeButton }
        .overlay(ConfettiView(isActive: celebrating))
        .toast($toast)
        .navigationBarBackButtonHidden()
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(.white.opacity(0.92)))
        }
        .padding(.leading, Metrics.gutter)
        .padding(.top, 8)
    }

    private var facts: some View {
        VStack(spacing: 0) {
            factRow("When", "\(current.timeLabel) to \(current.end.formatted(date: .omitted, time: .shortened))")
            WovenRule()
            factRow("Where", "\(current.venue.name), \(current.room)")
            WovenRule()
            factRow("Worth", "\(current.karmaReward) karma on check-in")
        }
    }

    private func factRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.uiLabel)
                .foregroundStyle(Palette.ash)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .font(.uiBody)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private var attendance: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(current.attending) going")
                    .font(.uiBodyMedium)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(max(0, current.capacity - current.attending)) spots left")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.rule)
                    Capsule()
                        .fill(Palette.tartan)
                        .frame(width: geo.size.width * min(1, Double(current.attending) / Double(current.capacity)))
                }
            }
            .frame(height: 6)
        }
    }

    private var checkInButton: some View {
        VStack(spacing: 10) {
            Button(current.checkedIn ? "Checked in" : "Check in") {
                guard store.checkIn(current, distance: distance) else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.easeIn(duration: 0.2)) { celebrating = true }
                toast = Toast(message: "\(current.karmaReward) karma added")
                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation(.easeOut(duration: 0.4)) { celebrating = false }
                }
            }
            .buttonStyle(FilledButtonStyle())
            .disabled(block != nil)

            if let block {
                Text(block.message)
                    .font(.uiCaption)
                    .foregroundStyle(block == .alreadyIn ? Palette.ash : Palette.tartan)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else if locations.isDenied {
                Text("Location is off, so we'll take your word for it.")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
}
