import SwiftUI
import AVFoundation

/// Reads text aloud. Conformers report completion through `onFinish` so a
/// button can flip itself back from "Stop" without polling.
protocol SpeechService: AnyObject {
    func speak(_ text: String, onFinish: @escaping () -> Void)
    func stop()
}

/// On-device fallback — no API key, no network, works the moment the app
/// launches. Every other `SpeechService` degrades to this one on failure,
/// same shape as `AISummaryService` falling back to `SampleSummaryService`.
final class SystemSpeechService: NSObject, SpeechService, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, onFinish: @escaping () -> Void) {
        guard !text.isEmpty else { onFinish(); return }
        self.onFinish = onFinish
        synthesizer.speak(AVSpeechUtterance(string: text))
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
    }
}

/// Voice for the weekly digest in Explore. Ships pointed at the on-device
/// voice; swap in `XAIVoiceService()` once a key is added to read the same
/// digest back in an xAI voice instead.
private struct DigestVoiceServiceKey: EnvironmentKey {
    static let defaultValue: SpeechService = SystemSpeechService()
}

extension EnvironmentValues {
    var digestVoiceService: SpeechService {
        get { self[DigestVoiceServiceKey.self] }
        set { self[DigestVoiceServiceKey.self] = newValue }
    }
}
