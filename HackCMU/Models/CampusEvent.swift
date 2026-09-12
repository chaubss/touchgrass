import Foundation
import CoreLocation

/// CLLocationCoordinate2D isn't Equatable, so venues carry plain doubles and
/// hand back a coordinate on demand. This keeps CampusEvent Hashable.
struct Venue: Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
}

enum EventCategory: String, CaseIterable, Identifiable, Hashable {
    case talk, social, service, career, wellness

    var id: String { rawValue }

    var label: String {
        switch self {
        case .talk:     return "Talks"
        case .social:   return "Social"
        case .service:  return "Service"
        case .career:   return "Career"
        case .wellness: return "Wellness"
        }
    }

    var symbol: String {
        switch self {
        case .talk:     return "mic"
        case .social:   return "person.2"
        case .service:  return "hands.sparkles"
        case .career:   return "briefcase"
        case .wellness: return "leaf"
        }
    }
}

struct CampusEvent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let organizer: String
    let summary: String
    let karmaReward: Int
    let start: Date
    let end: Date
    let venue: Venue
    let room: String
    let category: EventCategory
    var attending: Int
    let capacity: Int
    var checkedIn: Bool
    let isPantryVolunteerEvent: Bool

    var isFull: Bool { attending >= capacity }
    var hasEnded: Bool { end < Date() }
    var isLive: Bool { (start...end).contains(Date()) }

    /// Check-in opens 30 minutes before doors.
    var checkInWindow: ClosedRange<Date> { start.addingTimeInterval(-1800)...end }

    init(id: UUID = UUID(), title: String, organizer: String, summary: String,
         karmaReward: Int, start: Date, end: Date, venue: Venue, room: String,
         category: EventCategory, attending: Int, capacity: Int, checkedIn: Bool = false,
         isPantryVolunteerEvent: Bool = false) {
        self.id = id
        self.title = title
        self.organizer = organizer
        self.summary = summary
        self.karmaReward = karmaReward
        self.start = start
        self.end = end
        self.venue = venue
        self.room = room
        self.category = category
        self.attending = attending
        self.capacity = capacity
        self.checkedIn = checkedIn
        self.isPantryVolunteerEvent = isPantryVolunteerEvent
    }
}
