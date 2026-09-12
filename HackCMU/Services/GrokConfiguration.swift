import Foundation

/// Local demo configuration. Production provider secrets belong on the backend.
enum GrokConfiguration {
    // Preserves the previously enabled recap feature. Set false for local-only generation.
    static let isEnabled = true
    static let apiKey = "PASTE_GROK_API_KEY_HERE"
    static let endpoint = URL(string: "https://api.x.ai/v1/chat/completions")!
    static let model = "grok-4.3"

    static func summaryService(enabled: Bool = isEnabled) -> AISummaryService {
        let upstream: AISummaryService = enabled ? GrokSummaryService() : SampleSummaryService()
        return CachedSummaryService(upstream: upstream)
    }
}
