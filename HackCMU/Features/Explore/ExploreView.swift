import SwiftUI

struct ExploreView: View {
    @Environment(KarmaStore.self) private var store
    @Environment(\.summaryService) private var summaries

    @State private var digest: WeeklyDigest?
    @State private var isLoading = true
    @State private var selectedPerson: Student?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    DigestCard(digest: digest, isLoading: isLoading, onRegenerate: regenerate)
                        .padding(.bottom, 28)

                    SectionHeader(title: "Shout-outs",
                                  trailing: "\(store.publicGrants.count) shared")
                        .padding(.bottom, 4)

                    let feed = store.publicGrants
                    ForEach(Array(feed.enumerated()), id: \.element.id) { index, grant in
                        ShoutoutRow(grant: grant) { id in
                            selectedPerson = store.student(id)
                        }
                        if index < feed.count - 1 { WovenRule() }
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .paperBackground()
            .refreshable { await load() }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedPerson) { person in
                ProfileView(student: person)
            }
        }
        .task {
            guard digest == nil else { return }
            await load()
        }
    }

    private func regenerate() {
        Task { await load() }
    }

    private func load() async {
        withAnimation(.easeOut(duration: 0.2)) { isLoading = true }
        let result = try? await summaries.weeklyDigest(store.digestContext())
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            digest = result
            isLoading = false
        }
    }
}
