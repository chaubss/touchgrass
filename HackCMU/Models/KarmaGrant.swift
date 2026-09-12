import Foundation

enum KarmaCategory: String, CaseIterable, Identifiable, Hashable {
    case debugging, teaching, lifting, organizing, kindness

    var id: String { rawValue }

    /// Sentence case, written from the giver's point of view.
    var label: String {
        switch self {
        case .debugging:  return "Unblocked me"
        case .teaching:   return "Taught me something"
        case .lifting:    return "Carried the team"
        case .organizing: return "Made it happen"
        case .kindness:   return "Just kind"
        }
    }

    var symbol: String {
        switch self {
        case .debugging:  return "ant"
        case .teaching:   return "book"
        case .lifting:    return "figure.strengthtraining.traditional"
        case .organizing: return "flag"
        case .kindness:   return "heart"
        }
    }
}

struct KarmaGrant: Identifiable, Hashable {
    let id: UUID
    let from: Student.ID
    let to: Student.ID
    let amount: Int
    let category: KarmaCategory
    let reason: String
    let isPublic: Bool
    let createdAt: Date
    var cheers: Int
    var cheeredByMe: Bool

    init(id: UUID = UUID(), from: Student.ID, to: Student.ID, amount: Int,
         category: KarmaCategory, reason: String, isPublic: Bool,
         createdAt: Date, cheers: Int = 0, cheeredByMe: Bool = false) {
        self.id = id
        self.from = from
        self.to = to
        self.amount = amount
        self.category = category
        self.reason = reason
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.cheers = cheers
        self.cheeredByMe = cheeredByMe
    }
}
