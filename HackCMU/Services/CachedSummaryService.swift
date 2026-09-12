import Foundation

/// A successful IFM recap is a saved snapshot for its date range. Reopening or
/// refreshing that range reuses it, even when live IFM generation is disabled.
/// Local fallbacks are never cached, so they cannot block a later IFM request.
struct CachedSummaryService: AISummaryService {
    let upstream: AISummaryService
    var defaults: UserDefaults = .standard
    private let storageKey = "karma.ifmRecaps.v1"

    private struct Entry: Codable {
        let range: String
        let digest: WeeklyDigest
    }

    func weeklyDigest(_ context: DigestContext) async throws -> WeeklyDigest {
        try Task.checkCancellation()
        if let entry = entries().first(where: { $0.range == context.weekOf }) {
            var digest = entry.digest
            digest.isCached = true
            return digest
        }
        let digest = try await upstream.weeklyDigest(context)
        try Task.checkCancellation()
        if digest.source == .live, digest.provider == "IFM K2 Horizon" {
            var saved = entries().filter { $0.range != context.weekOf }
            saved.append(Entry(range: context.weekOf, digest: digest))
            // Keep only the 14 most recently generated ranges.
            saved.sort { $0.digest.generatedAt > $1.digest.generatedAt }
            if let data = try? JSONEncoder().encode(Array(saved.prefix(14))) {
                defaults.set(data, forKey: storageKey)
            }
        }
        return digest
    }

    private func entries() -> [Entry] {
        guard let data = defaults.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return saved.filter { $0.digest.source == .live && $0.digest.provider == "IFM K2 Horizon" }
    }
}
