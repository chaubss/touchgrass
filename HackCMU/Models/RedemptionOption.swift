import Foundation

enum RedemptionCategory: String, CaseIterable, Identifiable, Hashable {
    case dining, merch, charity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dining:   return "Dining"
        case .merch:    return "Merch"
        case .charity:  return "Give it away"
        }
    }

    var blurb: String {
        switch self {
        case .dining:   return "Meals and coffee on campus"
        case .merch:    return "Credit at the CMU store"
        case .charity:  return "One karma gives about two cents"
        }
    }
}

struct RedemptionOption: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let cost: Int
    let category: RedemptionCategory
    let symbol: String
    let imageName: String?
    var remaining: Int?
    /// Charity options let the giver pick the amount instead of a fixed price.
    var isOpenAmount: Bool = false

    init(id: UUID = UUID(), title: String, detail: String, cost: Int,
         category: RedemptionCategory, symbol: String,
         imageName: String? = nil, remaining: Int? = nil,
         isOpenAmount: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.cost = cost
        self.category = category
        self.symbol = symbol
        self.imageName = imageName
        self.remaining = remaining
        self.isOpenAmount = isOpenAmount
    }
}
