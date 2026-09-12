import SwiftUI

@main
struct KarmaApp: App {
    @State private var store = KarmaStore.demo()
    @State private var locations = LocationManager()

    /// Local by default; IFMConfiguration.isEnabled opts into network generation.
    private let summaries: AISummaryService = IFMConfiguration.summaryService()

    /// Swap point for the digest read-aloud button in Explore. Replace with
    /// XAIVoiceService() and add XAI_API_KEY to Info.plist once xAI's voice
    /// endpoint is confirmed — see the note in Services/XAIVoiceService.swift.
    private let digestVoice: SpeechService = SystemSpeechService()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(locations)
                .environment(\.summaryService, summaries)
                .environment(\.digestVoiceService, digestVoice)
                .tint(Palette.tartan)
        }
    }
}
