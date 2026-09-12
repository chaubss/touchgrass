import SwiftUI

/// Each category maps to one stock photo. Cards show it over `AsyncImage`;
/// the duotone wash below is the loading state and the fallback if the
/// network fails, so a dead connection degrades to the old look instead of
/// breaking the demo.
extension EventCategory {
    var imageURL: URL? {
        switch self {
        case .talk:
            return URL(string: "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=900&q=60&auto=format&fit=crop")
        case .social:
            return URL(string: "https://images.unsplash.com/photo-1543269865-cbf427effbad?w=900&q=60&auto=format&fit=crop")
        case .service:
            return URL(string: "https://images.unsplash.com/photo-1593113630400-ea4288922497?w=900&q=60&auto=format&fit=crop")
        case .career:
            return URL(string: "https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=900&q=60&auto=format&fit=crop")
        case .wellness:
            return URL(string: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=900&q=60&auto=format&fit=crop")
        }
    }
}

/// Photo for an event's category, with the duotone wash as placeholder/fallback
/// and a bottom scrim so the icon and status badge stay legible over any photo.
struct EventImage: View {
    let event: CampusEvent
    var height: CGFloat

    var body: some View {
        AsyncImage(url: event.category.imageURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                event.wash
            }
        }
        .frame(height: height)
        .clipped()
        .overlay(
            LinearGradient(
                colors: [.clear, .black.opacity(0.32)],
                startPoint: .center, endPoint: .bottom
            )
        )
    }
}

/// Each card also keeps a duotone wash picked deterministically from its
/// title, so the list looks varied and stable while photos load (or if they
/// fail to load).
extension CampusEvent {
    private static let washes: [(Color, Color)] = [
        (Color(red: 0.42, green: 0.30, blue: 0.26), Color(red: 0.78, green: 0.58, blue: 0.44)),
        (Color(red: 0.20, green: 0.28, blue: 0.32), Color(red: 0.52, green: 0.64, blue: 0.66)),
        (Color(red: 0.36, green: 0.22, blue: 0.30), Color(red: 0.72, green: 0.50, blue: 0.54)),
        (Color(red: 0.24, green: 0.30, blue: 0.22), Color(red: 0.58, green: 0.66, blue: 0.48)),
        (Color(red: 0.44, green: 0.26, blue: 0.20), Color(red: 0.82, green: 0.54, blue: 0.36)),
        (Color(red: 0.26, green: 0.24, blue: 0.36), Color(red: 0.56, green: 0.54, blue: 0.72))
    ]

    var wash: LinearGradient {
        let seed = title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let pair = Self.washes[seed % Self.washes.count]
        return LinearGradient(colors: [pair.0, pair.1],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var timeLabel: String {
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(start) { day = "Today" }
        else if calendar.isDateInTomorrow(start) { day = "Tomorrow" }
        else { day = start.formatted(.dateTime.weekday(.wide)) }
        return "\(day), \(start.formatted(date: .omitted, time: .shortened))"
    }

    var statusLabel: String? {
        if checkedIn { return "Checked in" }
        if isLive { return "Happening now" }
        if hasEnded { return "Ended" }
        if isFull { return "Full" }
        return nil
    }
}
