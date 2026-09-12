import Foundation

struct LedgerEntry: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case received, given, event, redeemed

        var symbol: String {
            switch self {
            case .received: return "arrow.down.left"
            case .given:    return "arrow.up.right"
            case .event:    return "calendar"
            case .redeemed: return "gift"
            }
        }
    }

    let id: UUID
    /// Signed against the wallet. Giving spends allowance, not wallet, so a
    /// `.given` entry carries a delta of 0 and is shown for history only.
    let delta: Int
    let allowanceDelta: Int
    let title: String
    let subtitle: String?
    let date: Date
    let kind: Kind

    init(id: UUID = UUID(), delta: Int, allowanceDelta: Int = 0, title: String,
         subtitle: String? = nil, date: Date, kind: Kind) {
        self.id = id
        self.delta = delta
        self.allowanceDelta = allowanceDelta
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.kind = kind
    }
}
