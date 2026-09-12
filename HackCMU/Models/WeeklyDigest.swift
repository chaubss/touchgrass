import Foundation

struct WeeklyDigest: Equatable, Codable {
    enum Source: String, Codable { case sample, live }

    let headline: String
    let body: [String]
    let mostHelpfulAndrewID: String?
    let mostHelpfulNote: String?
    let topOrganizer: String?
    let topOrganizerNote: String?
    let generatedAt: Date
    let source: Source
    /// Which model wrote it, shown next to the "Live digest" badge.
    var provider: String = "Sample"
    var notice: String? = nil
    var isCached: Bool = false
}

/// What the model is given. Built from the ledger, capped so the prompt stays small.
struct DigestContext: Encodable, Hashable {
    struct GrantLine: Encodable, Hashable {
        let from: String
        let to: String
        let amount: Int
        let category: String
        let reason: String
        var toAndrewID: String = ""
    }
    struct EventLine: Encodable, Hashable {
        let title: String
        let organizer: String
        let attending: Int
        let capacity: Int
        let karma: Int
    }

    let weekOf: String
    let grants: [GrantLine]
    let events: [EventLine]
}
