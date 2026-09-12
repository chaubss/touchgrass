import Foundation

enum ElevenLabsConfiguration {
    // Demo only: paste your key here and rebuild. Keep production keys on a backend.
    static let apiKey = ""

    static var configuredKey: String? {
        let value = (Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String ?? apiKey)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || value == "PASTE_ELEVENLABS_API_KEY_HERE" ? nil : value
    }
}
