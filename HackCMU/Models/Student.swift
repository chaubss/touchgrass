import Foundation

struct Student: Identifiable, Hashable {
    let id: UUID
    let andrewID: String
    let fullName: String
    let program: String
    var followers: Int
    var following: Int
    var wallet: Int
    var allowanceRemaining: Int

    var initials: String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return (first + last).uppercased()
    }

    init(id: UUID = UUID(), andrewID: String, fullName: String, program: String,
         followers: Int, following: Int = 0, wallet: Int, allowanceRemaining: Int = KarmaRules.monthlyAllowance) {
        self.id = id
        self.andrewID = andrewID
        self.fullName = fullName
        self.program = program
        self.followers = followers
        self.following = following
        self.wallet = wallet
        self.allowanceRemaining = allowanceRemaining
    }
}
