import Foundation
import Observation

@Observable
final class KarmaStore {

    // MARK: - State

    var students: [Student]
    var grants: [KarmaGrant]
    var events: [CampusEvent]
    var catalog: [RedemptionOption]
    var ledger: [LedgerEntry]
    var charityTotal: Int
    let currentUserID: Student.ID

    init(students: [Student], grants: [KarmaGrant], events: [CampusEvent],
         catalog: [RedemptionOption], ledger: [LedgerEntry],
         charityTotal: Int, currentUserID: Student.ID) {
        self.students = students
        self.grants = grants
        self.events = events
        self.catalog = catalog
        self.ledger = ledger
        self.charityTotal = charityTotal
        self.currentUserID = currentUserID
    }

    // MARK: - Lookups

    var currentUser: Student {
        students.first { $0.id == currentUserID } ?? students[0]
    }

    func student(_ id: Student.ID) -> Student? {
        students.first { $0.id == id }
    }

    func student(andrewID: String) -> Student? {
        students.first { $0.andrewID == andrewID }
    }

    func name(_ id: Student.ID) -> String {
        student(id)?.fullName ?? "Someone"
    }

    var publicGrants: [KarmaGrant] {
        grants.filter(\.isPublic).sorted { $0.createdAt > $1.createdAt }
    }

    var venues: [Venue] {
        var seen = Set<String>()
        return events.compactMap { event in
            guard !seen.contains(event.venue.id) else { return nil }
            seen.insert(event.venue.id)
            return event.venue
        }
    }

    func events(at venue: Venue) -> [CampusEvent] {
        events.filter { $0.venue.id == venue.id }.sorted { $0.start < $1.start }
    }

    // MARK: - Giving

    enum GiveBlock: Equatable {
        case isYou
        case cooldown(String)

        var message: String {
            switch self {
            case .isYou: return "You can't give karma to yourself."
            case .cooldown(let name):
                return "You've already recognised \(name) three times this week. Give it a few days."
            }
        }
    }

    /// Returns nil when this recipient is allowed, or the reason they aren't.
    func giveBlock(for recipient: Student.ID) -> GiveBlock? {
        if recipient == currentUserID { return .isYou }
        let cutoff = Date().addingTimeInterval(-KarmaRules.repeatWindow)
        let recent = grants.filter {
            $0.from == currentUserID && $0.to == recipient && $0.createdAt > cutoff
        }
        if recent.count >= KarmaRules.repeatLimit {
            let first = student(recipient)?.fullName.split(separator: " ").first.map(String.init) ?? "them"
            return .cooldown(first)
        }
        return nil
    }

    func canAfford(amount: Int) -> Bool {
        amount <= currentUser.allowanceRemaining
    }

    @discardableResult
    func give(to recipient: Student.ID, amount: Int, category: KarmaCategory,
              reason: String, isPublic: Bool) -> Bool {
        guard giveBlock(for: recipient) == nil,
              (KarmaRules.minGrant...KarmaRules.maxGrant).contains(amount),
              canAfford(amount: amount),
              KarmaRules.reasonRange.contains(reason.trimmingCharacters(in: .whitespacesAndNewlines).count)
        else { return false }

        let grant = KarmaGrant(from: currentUserID, to: recipient, amount: amount,
                               category: category, reason: reason,
                               isPublic: isPublic, createdAt: Date())
        grants.insert(grant, at: 0)

        mutate(currentUserID) { $0.allowanceRemaining -= amount }
        mutate(recipient) { $0.wallet += amount }

        ledger.insert(
            LedgerEntry(delta: 0, allowanceDelta: -amount,
                        title: "You recognised \(name(recipient))",
                        subtitle: reason, date: grant.createdAt, kind: .given),
            at: 0
        )
        return true
    }

    func toggleCheer(_ grantID: KarmaGrant.ID) {
        guard let i = grants.firstIndex(where: { $0.id == grantID }) else { return }
        grants[i].cheeredByMe.toggle()
        grants[i].cheers += grants[i].cheeredByMe ? 1 : -1
    }

    // MARK: - Events

    enum CheckInBlock: Equatable {
        case alreadyIn
        case tooEarly(Date)
        case over
        case tooFar(Int)

        var message: String {
            switch self {
            case .alreadyIn: return "You're checked in."
            case .tooEarly(let opens):
                return "Check in opens at \(opens.formatted(date: .omitted, time: .shortened))."
            case .over: return "This event has ended."
            case .tooFar(let metres): return "You're \(metres) m away. Get closer to check in."
            }
        }
    }

    /// `distance` is nil when location is unavailable or denied — in that case
    /// proximity isn't enforced, so a denied permission never dead-ends the flow.
    func checkInBlock(for event: CampusEvent, distance: Double?) -> CheckInBlock? {
        if event.checkedIn { return .alreadyIn }
        let now = Date()
        if now < event.checkInWindow.lowerBound { return .tooEarly(event.checkInWindow.lowerBound) }
        if now > event.checkInWindow.upperBound { return .over }
        if let distance, distance > KarmaRules.checkInRadius {
            return .tooFar(Int(distance.rounded()))
        }
        return nil
    }

    @discardableResult
    func checkIn(_ event: CampusEvent, distance: Double?) -> Bool {
        guard checkInBlock(for: event, distance: distance) == nil,
              let i = events.firstIndex(where: { $0.id == event.id })
        else { return false }

        events[i].checkedIn = true
        events[i].attending += 1
        mutate(currentUserID) { $0.wallet += event.karmaReward }

        ledger.insert(
            LedgerEntry(delta: event.karmaReward, title: event.title,
                        subtitle: event.organizer, date: Date(), kind: .event),
            at: 0
        )
        return true
    }

    // MARK: - Redeeming

    func shortfall(for cost: Int) -> Int {
        max(0, cost - currentUser.wallet)
    }

    /// Returns a claim code, or nil when the redemption can't go through.
    /// Charity redemptions return nil by design — they produce a receipt, not a code.
    @discardableResult
    func redeem(_ option: RedemptionOption, amount: Int? = nil) -> String? {
        let cost = amount ?? option.cost
        guard cost > 0, currentUser.wallet >= cost else { return nil }
        if let remaining = option.remaining, remaining <= 0 { return nil }

        mutate(currentUserID) { $0.wallet -= cost }

        if let i = catalog.firstIndex(where: { $0.id == option.id }),
           let remaining = catalog[i].remaining {
            catalog[i].remaining = remaining - 1
        }

        if option.category == .charity {
            charityTotal += cost
            ledger.insert(
                LedgerEntry(delta: -cost, title: option.title,
                            subtitle: "Donated", date: Date(), kind: .redeemed),
                at: 0
            )
            return nil
        }

        let code = Self.makeCode()
        ledger.insert(
            LedgerEntry(delta: -cost, title: option.title,
                        subtitle: code, date: Date(), kind: .redeemed),
            at: 0
        )
        return code
    }

    private static func makeCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        func block() -> String { String((0..<4).map { _ in alphabet.randomElement()! }) }
        return "TRTN-\(block())-\(block())"
    }

    // MARK: - Derived views

    func history(kind: LedgerEntry.Kind) -> [LedgerEntry] {
        ledger.filter { $0.kind == kind }
    }

    var eventsAttended: Int { events.filter(\.checkedIn).count }
    var karmaGivenTotal: Int { grants.filter { $0.from == currentUserID }.reduce(0) { $0 + $1.amount } }
    var shoutoutsReceived: Int { grants.filter { $0.to == currentUserID && $0.isPublic }.count }

    /// Net wallet movement for each of the last seven days, oldest first.
    var weekSparkline: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return ledger
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.delta }
        }
    }

    func digestContext() -> DigestContext {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        let recentGrants = grants.filter { $0.createdAt > cutoff }.prefix(30).map {
            DigestContext.GrantLine(from: name($0.from), to: name($0.to),
                                    amount: $0.amount, category: $0.category.rawValue,
                                    reason: $0.reason)
        }
        let recentEvents = events.filter { $0.start > cutoff && $0.start < Date() }.prefix(10).map {
            DigestContext.EventLine(title: $0.title, organizer: $0.organizer,
                                    attending: $0.attending, capacity: $0.capacity,
                                    karma: $0.karmaReward)
        }
        return DigestContext(
            weekOf: Date().formatted(.dateTime.month(.wide).day()),
            grants: Array(recentGrants),
            events: Array(recentEvents)
        )
    }

    // MARK: - Helpers

    private func mutate(_ id: Student.ID, _ change: (inout Student) -> Void) {
        guard let i = students.firstIndex(where: { $0.id == id }) else { return }
        change(&students[i])
    }
}
