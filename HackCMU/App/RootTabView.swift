import SwiftUI

enum Tab: Hashable { case home, events, redeem, explore, profile }

struct RootTabView: View {
    @State private var selection: Tab = .home
    /// Set when Home sends you to Events, so Events can open on the list.
    @State private var eventsMode: EventsView.Mode = .list

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onEarnKarma: {
                eventsMode = .list
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    selection = .events
                }
            })
            .tabItem { Label("Home", systemImage: "circle.grid.2x2") }
            .tag(Tab.home)

            EventsView(mode: $eventsMode)
                .tabItem { Label("Events", systemImage: "calendar") }
                .tag(Tab.events)

            RedeemView()
                .tabItem { Label("Redeem", systemImage: "gift") }
                .tag(Tab.redeem)

            ExploreView()
                .tabItem { Label("Explore", systemImage: "sparkles") }
                .tag(Tab.explore)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(Tab.profile)
        }
        .toolbarBackground(Palette.paper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
