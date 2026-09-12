import Foundation

/// Fictional demo activity at real campus locations, not a live event calendar.
/// Balances, history, and summaries are derived from the same sample activity.
extension KarmaStore {

    enum Venues {
        static let gates    = Venue(id: "ghc",    name: "Gates Hillman Center",     shortName: "Gates",   latitude: 40.4433, longitude: -79.9448)
        static let cohon    = Venue(id: "cuc",    name: "Cohon University Center",  shortName: "Cohon",   latitude: 40.4438, longitude: -79.9420)
        static let tepper   = Venue(id: "tepper", name: "Tepper Quad",              shortName: "Tepper",  latitude: 40.4420, longitude: -79.9455)
        static let hunt     = Venue(id: "hunt",   name: "Hunt Library",             shortName: "Hunt",    latitude: 40.4415, longitude: -79.9435)
        static let wean     = Venue(id: "wean",   name: "Wean Hall",                shortName: "Wean",    latitude: 40.4426, longitude: -79.9459)
        static let purnell  = Venue(id: "pca",    name: "Purnell Center",           shortName: "Purnell", latitude: 40.4448, longitude: -79.9425)
        static let fence    = Venue(id: "fence",  name: "The Fence",                shortName: "Fence",   latitude: 40.4429, longitude: -79.9430)
        static let doherty  = Venue(id: "dh",     name: "Doherty Hall",             shortName: "Doherty", latitude: 40.4423, longitude: -79.9443)
    }

    static func demo() -> KarmaStore {
        let now = Date()
        let calendar = Calendar.current
        func scheduled(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let date = calendar.date(byAdding: .day, value: day, to: now)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        }
        func daysAgo(_ d: Double) -> Date { now.addingTimeInterval(-d * 24 * 3600) }

        // Current user is pre-loaded so the demo opens on a populated screen.
        let harsh   = Student(andrewID: "hgarg",    fullName: "Harsh Garg",       program: "MSE '27",  followers: 128, following: 96,  wallet: 1240, allowanceRemaining: 320)
        let priya   = Student(andrewID: "pnair",    fullName: "Priya Nair",       program: "MSCS '27", followers: 214, following: 140, wallet: 1890, allowanceRemaining: 150)
        let marcus  = Student(andrewID: "mokonkwo", fullName: "Marcus Okonkwo",   program: "MSE '27",  followers: 176, following: 88,  wallet: 2310, allowanceRemaining: 410)
        let leena   = Student(andrewID: "lzhao",    fullName: "Leena Zhao",       program: "MIIS '27", followers: 305, following: 212, wallet: 3020, allowanceRemaining: 60)
        let devon   = Student(andrewID: "dbrooks",  fullName: "Devon Brooks",     program: "MSIT '27", followers: 91,  following: 74,  wallet: 640,  allowanceRemaining: 500)
        let ana     = Student(andrewID: "asilva",   fullName: "Ana Silva",        program: "MSE '27",  followers: 143, following: 102, wallet: 1475, allowanceRemaining: 280)
        let jonah   = Student(andrewID: "jreyes",   fullName: "Jonah Reyes",      program: "ECE '27",  followers: 67,  following: 55,  wallet: 430,  allowanceRemaining: 500)
        let mei     = Student(andrewID: "mlin",     fullName: "Mei Lin",          program: "MSCS '27", followers: 258, following: 119, wallet: 2680, allowanceRemaining: 95)
        let tomas   = Student(andrewID: "tvargas",  fullName: "Tomás Vargas",     program: "MSE '27",  followers: 84,  following: 61,  wallet: 720,  allowanceRemaining: 445)
        let aisha   = Student(andrewID: "akhan",    fullName: "Aisha Khan",       program: "Heinz '27",followers: 192, following: 130, wallet: 1560, allowanceRemaining: 200)
        let ravi    = Student(andrewID: "rpatel",   fullName: "Ravi Patel",       program: "MSE '27",  followers: 110, following: 83,  wallet: 980,  allowanceRemaining: 375)
        let claire  = Student(andrewID: "cdubois",  fullName: "Claire Dubois",    program: "MIIS '27", followers: 149, following: 97,  wallet: 1320, allowanceRemaining: 240)
        let sam     = Student(andrewID: "sokafor",  fullName: "Sam Okafor",       program: "MSCS '27", followers: 73,  following: 64,  wallet: 510,  allowanceRemaining: 490)
        let yuki    = Student(andrewID: "ytanaka",  fullName: "Yuki Tanaka",      program: "MSE '27",  followers: 121, following: 90,  wallet: 1105, allowanceRemaining: 310)

        var students = [harsh, priya, marcus, leena, devon, ana, jonah, mei, tomas, aisha, ravi, claire, sam, yuki]

        let grants: [KarmaGrant] = [
            .init(from: priya.id,  to: harsh.id,  amount: 50, category: .debugging,
                  reason: "Helped me reproduce a concurrency bug and understand how to test the fix.",
                  isPublic: true, createdAt: daysAgo(0.2), cheers: 5),
            .init(from: marcus.id, to: leena.id,  amount: 75, category: .organizing,
                  reason: "Helped check in participants and set up tables for our student project showcase.",
                  isPublic: true, createdAt: daysAgo(0.5), cheers: 10),
            .init(from: harsh.id,  to: mei.id,    amount: 40, category: .teaching,
                  reason: "Explained consistent hashing during our distributed systems study group.",
                  isPublic: true, createdAt: daysAgo(0.8), cheers: 6),
            .init(from: ana.id,    to: priya.id,  amount: 60, category: .lifting,
                  reason: "Shared class notes and helped me catch up after I missed a studio session.",
                  isPublic: true, createdAt: daysAgo(1.1), cheers: 9),
            .init(from: devon.id,  to: harsh.id,  amount: 25, category: .kindness,
                  reason: "Picked up dinner for me while I was finishing a lab session in Wean.",
                  isPublic: true, createdAt: daysAgo(1.4), cheers: 3),
            .init(from: leena.id,  to: tomas.id,  amount: 30, category: .teaching,
                  reason: "Worked through a practice linear algebra problem with our study group.",
                  isPublic: true, createdAt: daysAgo(1.9), cheers: 4),
            .init(from: mei.id,    to: marcus.id, amount: 100, category: .organizing,
                  reason: "Coordinated room setup, refreshments, and cleanup for our graduate student mixer.",
                  isPublic: true, createdAt: daysAgo(2.3), cheers: 15),
            .init(from: aisha.id,  to: claire.id, amount: 45, category: .lifting,
                  reason: "Reviewed our project presentation and gave specific suggestions before the rehearsal.",
                  isPublic: true, createdAt: daysAgo(2.8), cheers: 5),
            .init(from: harsh.id,  to: jonah.id,  amount: 20, category: .kindness,
                  reason: "Returned the laptop charger I left in Wean after our study session.",
                  isPublic: true, createdAt: daysAgo(3.2), cheers: 3),
            .init(from: ravi.id,   to: priya.id,  amount: 55, category: .debugging,
                  reason: "Spotted a pagination issue during code review and suggested a regression test.",
                  isPublic: true, createdAt: daysAgo(3.7), cheers: 7),
            .init(from: sam.id,    to: leena.id,  amount: 35, category: .teaching,
                  reason: "Organized a small Swift study session and shared the example code afterward.",
                  isPublic: true, createdAt: daysAgo(4.1), cheers: 8),
            .init(from: yuki.id,   to: ana.id,    amount: 50, category: .lifting,
                  reason: "Covered my office hours while I attended an interview.",
                  isPublic: false, createdAt: daysAgo(4.6)),
            .init(from: claire.id, to: mei.id,    amount: 40, category: .debugging,
                  reason: "Helped profile our project and identify an unnecessary database query.",
                  isPublic: true, createdAt: daysAgo(5.0), cheers: 6),
            .init(from: tomas.id,  to: devon.id,  amount: 15, category: .kindness,
                  reason: "Shared seminar notes with me when I could not attend.",
                  isPublic: false, createdAt: daysAgo(5.5)),
            .init(from: priya.id,  to: marcus.id, amount: 65, category: .organizing,
                  reason: "Confirmed panelists and sent attendees the updated schedule for our career discussion.",
                  isPublic: true, createdAt: daysAgo(6.0), cheers: 10),
            .init(from: marcus.id, to: harsh.id,  amount: 30, category: .teaching,
                  reason: "Explained the replication lecture concepts during office hours.",
                  isPublic: true, createdAt: daysAgo(6.4), cheers: 4),
            .init(from: leena.id,  to: aisha.id,  amount: 70, category: .organizing,
                  reason: "Helped coordinate volunteers for a student organization networking event.",
                  isPublic: true, createdAt: daysAgo(6.9), cheers: 11),
            .init(from: jonah.id,  to: ravi.id,   amount: 25, category: .lifting,
                  reason: "Helped calibrate our robot sensors and document the setup for the next lab session.",
                  isPublic: true, createdAt: daysAgo(7.5), cheers: 5),
            .init(from: ana.id,    to: yuki.id,   amount: 35, category: .kindness,
                  reason: "Checked in with me and shared campus support resources during a difficult week.",
                  isPublic: true, createdAt: daysAgo(8.1), cheers: 7),
            .init(from: mei.id,    to: sam.id,    amount: 20, category: .debugging,
                  reason: "Walked me through the project setup so I could run the app on my phone.",
                  isPublic: false, createdAt: daysAgo(8.8)),
            .init(from: devon.id,  to: claire.id, amount: 30, category: .teaching,
                  reason: "Shared a well-organized review guide ahead of our midterm.",
                  isPublic: true, createdAt: daysAgo(9.3), cheers: 9),
            .init(from: harsh.id,  to: priya.id,  amount: 45, category: .lifting,
                  reason: "Covered my part of the project update while I was traveling.",
                  isPublic: true, createdAt: daysAgo(9.9), cheers: 6)
        ]

        let events: [CampusEvent] = [
            .init(title: "Distributed systems reading group", organizer: "SCS graduate students",
                  summary: "Discuss a paper on replicated storage. Read the abstract beforehand; all experience levels welcome.",
                  karmaReward: 50, start: scheduled(0, 13), end: scheduled(0, 14),
                  venue: Venues.gates, room: "Meet in the third-floor commons", category: .talk,
                  attending: 18, capacity: 30),
            .init(title: "Graduate student coffee hour", organizer: "Graduate Student Assembly",
                  summary: "Meet graduate students across departments over coffee and light refreshments. Drop in when you can.",
                  karmaReward: 25, start: scheduled(1, 16), end: scheduled(1, 17),
                  venue: Venues.cohon, room: "First-floor seating area", category: .social,
                  attending: 32, capacity: 60),
            .init(title: "Campus food collection", organizer: "Student pantry volunteers",
                  summary: "Collect unopened, shelf-stable food for the CMU Pantry. Volunteers help sort donations and check expiration dates.",
                  karmaReward: 100, start: scheduled(2, 10), end: scheduled(2, 12),
                  venue: Venues.cohon, room: "Meet at the information desk", category: .service,
                  attending: 9, capacity: 16, isPantryVolunteerEvent: true),
            .init(title: "Resume review workshop", organizer: "Graduate student career volunteers",
                  summary: "Bring a draft resume for peer feedback on structure, project descriptions, and internship applications.",
                  karmaReward: 50, start: scheduled(2, 17), end: scheduled(2, 18, 30),
                  venue: Venues.tepper, room: "Meet in the main lobby", category: .career,
                  attending: 24, capacity: 35),
            .init(title: "Morning stretch on the Cut", organizer: "Student wellness group",
                  summary: "A relaxed outdoor stretching session. Bring a mat or towel and water; canceled in heavy rain.",
                  karmaReward: 25, start: scheduled(3, 8), end: scheduled(3, 8, 45),
                  venue: Venues.fence, room: "Lawn beside the Fence", category: .wellness,
                  attending: 12, capacity: 25),
            .init(title: "Graduate writing group", organizer: "Graduate student writing circle",
                  summary: "Two focused writing blocks with a short break. Bring your own paper, proposal, or application to work on.",
                  karmaReward: 25, start: scheduled(3, 18), end: scheduled(3, 20),
                  venue: Venues.hunt, room: "Meet at the first-floor entrance", category: .social,
                  attending: 14, capacity: 20),
            .init(title: "Student project build night", organizer: "Student developer community",
                  summary: "Work on a personal or team project, ask for debugging help, and share a short progress update at the end.",
                  karmaReward: 75, start: scheduled(4, 18), end: scheduled(4, 21),
                  venue: Venues.wean, room: "Meet in the fifth-floor lobby", category: .career,
                  attending: 27, capacity: 40),
            .init(title: "Student performance discussion", organizer: "Drama student volunteers",
                  summary: "Join an informal conversation about student work, rehearsal processes, and collaborating across disciplines.",
                  karmaReward: 25, start: scheduled(5, 17), end: scheduled(5, 18),
                  venue: Venues.purnell, room: "Main lobby", category: .social,
                  attending: 16, capacity: 30),
            .init(title: "Peer math study session", organizer: "Student study group",
                  summary: "Review linear algebra concepts with classmates. Bring practice problems and questions from lecture.",
                  karmaReward: 50, start: scheduled(6, 16), end: scheduled(6, 17, 30),
                  venue: Venues.doherty, room: "Meet at the main entrance", category: .talk,
                  attending: 11, capacity: 20),
            .init(title: "Campus food collection", organizer: "Student pantry volunteers",
                  summary: "Volunteers sorted shelf-stable donations for the campus pantry.",
                  karmaReward: 100, start: scheduled(-5, 10), end: scheduled(-5, 12),
                  venue: Venues.cohon, room: "Information desk", category: .service,
                  attending: 12, capacity: 16, checkedIn: true, isPantryVolunteerEvent: true),
            .init(title: "Machine learning reading group", organizer: "SCS graduate students",
                  summary: "A student discussion of model evaluation and experimental design.",
                  karmaReward: 50, start: scheduled(-2, 15), end: scheduled(-2, 16),
                  venue: Venues.gates, room: "Third-floor commons", category: .talk,
                  attending: 22, capacity: 30, checkedIn: true)
        ]

        let catalog: [RedemptionOption] = [
            .init(title: "Dining block", detail: "An entrée, side, and drink at a participating campus counter", cost: 600, category: .dining, symbol: "fork.knife", imageName: "dining-block", remaining: 40),
            .init(title: "Entropy+ snack credit", detail: "Five dollars at Entropy in the Cohon Center", cost: 250, category: .dining, symbol: "cart", imageName: "entropy", remaining: 60),
            .init(title: "La Prima coffee", detail: "Five dollars toward coffee at any campus counter", cost: 250, category: .dining, symbol: "cup.and.saucer", imageName: "la-prima", remaining: 120),
            .init(title: "CMU Store credit", detail: "Twenty-five dollars at the University Store", cost: 1_250, category: .merch, symbol: "bag", imageName: "cmu-store", remaining: 12),
            .init(title: "Scottie sticker pair", detail: "Two CMU Scottie decals for your laptop or water bottle", cost: 300, category: .merch, symbol: "seal", imageName: "cmu-stickers", remaining: 45),
            .init(title: "CMU Food Pantry", detail: "Support groceries and essentials for CMU students", cost: 50, category: .charity, symbol: "heart.text.square", imageName: "cmu-pantry", isOpenAmount: true),
            .init(title: "Greater Pittsburgh Community Food Bank", detail: "Help provide meals to neighbors across southwestern Pennsylvania", cost: 50, category: .charity, symbol: "heart", imageName: "pittsburgh-food-bank", isOpenAmount: true)
        ]

        // One source of truth: the wallet and history reconcile with the sample actions.
        var ledger: [LedgerEntry] = [
            .init(delta: 2_000, title: "Earlier earned karma", subtitle: "Recognition and participation before this activity period",
                  date: scheduled(-14, 12), kind: .received),
            .init(delta: -600, title: "Dining block", subtitle: "TRTN-8H4K-P2QM", date: scheduled(-1, 12, 15), kind: .redeemed),
            .init(delta: -250, title: "La Prima coffee", subtitle: "TRTN-3C9V-XK7B", date: scheduled(-4, 9, 30), kind: .redeemed)
        ]
        for grant in grants where grant.from == harsh.id || grant.to == harsh.id {
            let received = grant.to == harsh.id
            let peer = students.first { $0.id == (received ? grant.from : grant.to) }!
            ledger.append(.init(delta: received ? grant.amount : -grant.amount,
                                allowanceDelta: received ? 0 : -grant.amount,
                                title: received ? "\(peer.fullName) recognised you" : "You recognised \(peer.fullName)",
                                subtitle: grant.reason, date: grant.createdAt,
                                kind: received ? .received : .given))
        }
        for event in events where event.checkedIn {
            ledger.append(.init(delta: event.karmaReward, title: event.title,
                                subtitle: event.organizer, date: event.start, kind: .event))
        }
        ledger.sort { $0.date > $1.date }
        for index in students.indices {
            let id = students[index].id
            let givenThisMonth = grants.filter {
                $0.from == id && calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month)
            }.reduce(0) { $0 + $1.amount }
            students[index].allowanceRemaining = KarmaRules.monthlyAllowance - givenThisMonth
            students[index].followers = max(12, students[index].followers / 3)
            students[index].following = max(10, students[index].following / 2)
        }
        students[0].wallet = ledger.reduce(0) { $0 + $1.delta }

        return KarmaStore(students: students, grants: grants, events: events,
                          catalog: catalog, ledger: ledger,
                          charityTotal: 18_450, currentUserID: harsh.id)
    }
}
