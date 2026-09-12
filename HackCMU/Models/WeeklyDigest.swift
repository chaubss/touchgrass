import Foundation

struct WeeklyDigest: Equatable {
    enum Source: String { case sample, live }

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
}

/// What the model is given. Built from the ledger, capped so the prompt stays small.
struct DigestContext: Encodable {
    struct GrantLine: Encodable {
        let from: String
        let to: String
        let amount: Int
        let category: String
        let reason: String
    }
    struct EventLine: Encodable {
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
