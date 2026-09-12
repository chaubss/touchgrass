import Foundation

/// Demo-only configuration. Never ship a provider secret in an iOS app;
/// production requests should go through your own authenticated backend.
enum IFMConfiguration {
    /// Off by default: use the on-device, data-derived recap without API calls.
    /// Set to true and rebuild to enable IFM generation.
    static let isEnabled = true

    static func summaryService(enabled: Bool = isEnabled) -> AISummaryService {
        let upstream: AISummaryService = enabled ? IFMSummaryService() : SampleSummaryService()
        return CachedSummaryService(upstream: upstream)
    }

    // Paste a NEW (rotated) IFM key here, then rebuild. Do not commit real keys.
    static let apiKey = ""
    static let endpoint = URL(string: "https://api.ifm.ai/v1/chat/completions")!
    static let model = "IFM/K2-Horizon-375B-A23B"
}
