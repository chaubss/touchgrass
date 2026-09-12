import Foundation

enum KarmaBadge: String, CaseIterable, Identifiable {
    case firstRipple, clutchScotty, bugWhisperer, touchGrass, pantryPal, fullCircle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstRipple: return "First Ripple"
        case .clutchScotty: return "Clutch Scotty"
        case .bugWhisperer: return "Bug Whisperer"
        case .touchGrass: return "Touch Grass"
        case .pantryPal: return "Pantry Pal"
        case .fullCircle: return "Full Circle"
        }
    }

    var requirement: String {
        switch self {
        case .firstRipple: return "Give your first karma recognition."
        case .clutchScotty: return "Receive 5 recognitions for carrying the team."
        case .bugWhisperer: return "Receive 5 debugging recognitions."
        case .touchGrass: return "Check in to 5 wellness events."
        case .pantryPal: return "Check in to 3 pantry volunteer events."
        case .fullCircle: return "Earn karma at an event, give recognition, and redeem a reward."
        }
    }

    var target: Int {
        switch self {
        case .firstRipple: return 1
        case .clutchScotty, .bugWhisperer, .touchGrass: return 5
        case .pantryPal, .fullCircle: return 3
        }
    }
}

struct BadgeProgress: Identifiable {
    let badge: KarmaBadge
    let count: Int
    let nextStep: String
    var id: KarmaBadge { badge }
    var earned: Bool { count >= badge.target }
    var completed: Int { min(count, badge.target) }
    var fraction: Double { Double(completed) / Double(badge.target) }
}

extension KarmaStore {
    /// Derived from recorded actions so milestones update immediately and never spend karma.
    var badgeProgress: [BadgeProgress] {
        let given = grants.filter { $0.from == currentUserID }
        let received = grants.filter { $0.to == currentUserID }
        let attended = events.filter(\.checkedIn)
        let earnedAtEvent = ledger.contains { $0.kind == .event && $0.delta > 0 }
        let redeemed = ledger.contains { $0.kind == .redeemed && $0.delta < 0 }

        return KarmaBadge.allCases.map { badge in
            let count: Int
            let nextStep: String
            switch badge {
            case .firstRipple:
                count = given.count
                nextStep = "Thank someone using Give karma on Home."
            case .clutchScotty:
                count = received.filter { $0.category == .lifting }.count
                nextStep = "Receive \(max(0, 5 - count)) more ‘Carried the team’ recognitions from peers."
            case .bugWhisperer:
                count = received.filter { $0.category == .debugging }.count
                nextStep = "Receive \(max(0, 5 - count)) more ‘Unblocked me’ recognitions for debugging help."
            case .touchGrass:
                count = attended.filter { $0.category == .wellness }.count
                nextStep = "Check in to \(max(0, 5 - count)) more events in the Wellness category."
            case .pantryPal:
                count = attended.filter(\.isPantryVolunteerEvent).count
                nextStep = "Complete \(max(0, 3 - count)) more pantry volunteer check-ins. Look for campus food collections in Events."
            case .fullCircle:
                count = [earnedAtEvent, !given.isEmpty, redeemed].filter { $0 }.count
                var remaining: [String] = []
                if !earnedAtEvent { remaining.append("check in to an event") }
                if given.isEmpty { remaining.append("give karma to someone") }
                if !redeemed { remaining.append("redeem a reward or donate") }
                nextStep = remaining.isEmpty ? "You've completed the circle." : "Next: " + remaining.joined(separator: ", ") + "."
            }
            return BadgeProgress(badge: badge, count: count, nextStep: nextStep)
        }
    }
}
