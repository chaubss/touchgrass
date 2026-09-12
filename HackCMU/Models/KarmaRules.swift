import Foundation

enum KarmaRules {
    static let monthlyAllowance = 500
    static let minGrant = 1
    static let maxGrant = 100
    static let quickAmounts = [10, 25, 50, 100]
    static let reasonRange = 10...140
    /// Repeat grants to the same person inside a rolling week.
    static let repeatLimit = 3
    static let repeatWindow: TimeInterval = 7 * 24 * 3600
    /// Metres you must be within to check in to an event.
    static let checkInRadius: Double = 150
}
