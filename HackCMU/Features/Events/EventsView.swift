import SwiftUI

struct EventsView: View {
    enum Mode: String, CaseIterable { case list, map }

    @Environment(KarmaStore.self) private var store
    @Binding var mode: Mode

    @Namespace private var namespace
    @State private var category: EventCategory?
    @State private var window: TimeWindow = .all
    @State private var selectedVenue: Venue?
    @State private var venueFilter: Venue?

    enum TimeWindow: String, CaseIterable {
        case today, week, all
        var label: String {
            switch self {
            case .today: return "Today"
            case .week:  return "This week"
            case .all:   return "All"
            }
        }
    }

    private var filtered: [CampusEvent] {
        store.events
            .filter { category == nil || $0.category == category }
            .filter { venueFilter == nil || $0.venue.id == venueFilter?.id }
            .filter { event in
                switch window {
                case .all:   return true
                case .today: return Calendar.current.isDateInToday(event.start)
                case .week:  return event.start < Date().addingTimeInterval(7 * 86400)
                }
            }
            .sorted { $0.start < $1.start }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                filters

                if mode == .list {
                    listContent
                } else {
                    mapContent
                }
            }
            .paperBackground()
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 5) {
                        Text("\(store.currentUser.wallet.formatted())")
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .monospacedDigit()
                        Image(systemName: "circle.hexagongrid")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Palette.ink)
                }
            }
            .navigationDestination(for: CampusEvent.self) { event in
                detailDestination(for: event)
            }
        }
    }

    /// iOS 18 gets a real hero zoom out of the card. iOS 17 gets the standard
    /// push — matchedGeometryEffect can't cross a navigation boundary, and
    /// faking it by tearing down the list costs scroll position.
    @ViewBuilder
    private func detailDestination(for event: CampusEvent) -> some View {
        if #available(iOS 18.0, *) {
            EventDetailView(event: event)
                .navigationTransition(.zoom(sourceID: event.id, in: namespace))
        } else {
            EventDetailView(event: event)
        }
    }

    private var modePicker: some View {
        Picker("View", selection: $mode.animation(.easeInOut(duration: 0.22))) {
            Text("Map").tag(Mode.map)
            Text("List").tag(Mode.list)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 12)
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeWindow.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { window = option }
                    } label: {
                        Chip(title: option.label, isSelected: window == option)
                    }
                    .buttonStyle(.plain)
                }

                Rectangle()
                    .fill(Palette.rule)
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 2)

                ForEach(EventCategory.allCases) { option in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            category = (category == option) ? nil : option
                        }
                    } label: {
                        Chip(title: option.label, isSelected: category == option)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Metrics.gutter)
        }
        .padding(.bottom, 12)
    }

    private var listContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let venueFilter {
                    HStack(spacing: 8) {
                        Text("At \(venueFilter.name)")
                            .font(.uiLabel)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Button("Clear") {
                            withAnimation(.easeOut(duration: 0.2)) { self.venueFilter = nil }
                        }
                        .font(.uiLabel)
                        .foregroundStyle(Palette.tartan)
                    }
                    .padding(.horizontal, 2)
                }

                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Text("Nothing here yet")
                            .font(.sectionTitle)
                            .foregroundStyle(Palette.ink)
                        Text("Widen the filters, or check the map for what's on elsewhere on campus.")
                            .font(.uiLabel)
                            .foregroundStyle(Palette.ash)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filtered) { event in
                        NavigationLink(value: event) {
                            cardWithTransitionSource(event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private func cardWithTransitionSource(_ event: CampusEvent) -> some View {
        if #available(iOS 18.0, *) {
            EventListCard(event: event)
                .matchedTransitionSource(id: event.id, in: namespace)
        } else {
            EventListCard(event: event)
        }
    }

    private var mapContent: some View {
        EventsMapView(selectedVenue: $selectedVenue)
            .overlay(alignment: .bottom) {
                if let venue = selectedVenue {
                    VenueSheet(
                        venue: venue,
                        onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedVenue = nil
                            }
                        },
                        onSeeAll: {
                            venueFilter = venue
                            selectedVenue = nil
                            withAnimation(.easeInOut(duration: 0.25)) { mode = .list }
                        }
                    )
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedVenue)
    }
}
