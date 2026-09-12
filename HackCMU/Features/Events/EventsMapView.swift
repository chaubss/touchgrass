import SwiftUI
import UIKit
import MapKit

struct EventsMapView: View {
    @Environment(KarmaStore.self) private var store
    @Environment(LocationManager.self) private var locations

    @Binding var selectedVenue: Venue?

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.4433, longitude: -79.9436),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
    )

    var body: some View {
        Map(position: $camera) {
            ForEach(store.venues) { venue in
                Annotation(venue.shortName, coordinate: venue.coordinate) {
                    VenuePin(
                        count: store.events(at: venue).count,
                        symbol: store.events(at: venue).first?.category.symbol ?? "mappin",
                        isSelected: selectedVenue?.id == venue.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedVenue = venue
                            camera = .region(
                                MKCoordinateRegion(
                                    center: venue.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.0035, longitudeDelta: 0.0035)
                                )
                            )
                        }
                    }
                }
                .annotationTitles(.hidden)
            }

            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .overlay(alignment: .top) {
            if locations.isDenied {
                permissionBanner
            }
        }
        .onAppear { locations.requestIfNeeded() }
        .onDisappear { locations.stop() }
    }

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash")
                .font(.system(size: 14))
            Text("Turn on location to see what's near you.")
                .font(.uiCaption)
            Spacer(minLength: 4)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.uiCaption.weight(.semibold))
            .foregroundStyle(Palette.tartan)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Palette.surface))
        .overlay(Capsule().stroke(Palette.rule, lineWidth: 1))
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 10)
    }
}

struct VenuePin: View {
    let count: Int
    let symbol: String
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Palette.tartan)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                )
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: Palette.ink.opacity(0.25), radius: isSelected ? 6 : 3, y: 2)

            if count > 1 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.tartan)
                    .frame(width: 17, height: 17)
                    .background(Circle().fill(.white))
                    .offset(x: 4, y: -4)
            }
        }
        .scaleEffect(isSelected ? 1.25 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

/// Slides up when a pin is chosen, listing what's on at that building.
struct VenueSheet: View {
    @Environment(KarmaStore.self) private var store
    @Environment(LocationManager.self) private var locations

    let venue: Venue
    let onDismiss: () -> Void
    let onSeeAll: () -> Void

    private var distanceLabel: String? {
        guard let metres = locations.distance(to: venue) else { return nil }
        if metres < 1000 { return "\(Int(metres.rounded())) m away" }
        return String(format: "%.1f km away", metres / 1000)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(venue.name)
                        .font(.sectionTitle)
                        .foregroundStyle(Palette.ink)
                    if let distanceLabel {
                        Text(distanceLabel)
                            .font(.uiCaption)
                            .foregroundStyle(Palette.ash)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.ash)
                        .padding(8)
                        .background(Circle().fill(Palette.rule.opacity(0.5)))
                }
            }

            let here = store.events(at: venue)
            VStack(spacing: 0) {
                ForEach(Array(here.enumerated()), id: \.element.id) { index, event in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.uiBody)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            Text(event.timeLabel)
                                .font(.uiCaption)
                                .foregroundStyle(Palette.ash)
                        }
                        Spacer()
                        KarmaChip(amount: event.karmaReward)
                    }
                    .padding(.vertical, 11)
                    if index < here.count - 1 { WovenRule() }
                }
            }

            Button("Show these in the list", action: onSeeAll)
                .buttonStyle(OutlinedButtonStyle())
        }
        .padding(Metrics.gutter)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Palette.rule, lineWidth: 1)
        )
        .shadow(color: Palette.ink.opacity(0.12), radius: 18, y: -2)
        .padding(Metrics.gutter)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
