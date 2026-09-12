import AVFoundation

/// Reads the weekly digest aloud in an xAI voice.
///
/// xAI's public voice-synthesis endpoint wasn't finalized when this was
/// written, so the request below is a best guess at the shape of an
/// OpenAI-compatible `/v1/audio/speech` call — check it against xAI's docs
/// once real credentials are in hand, and adjust the path/body/response
/// handling to match. Until `XAI_API_KEY` is set in Info.plist, or if the
/// call fails for any reason, this falls back to the on-device voice so the
/// button never just does nothing.
final class XAIVoiceService: NSObject, SpeechService, AVAudioPlayerDelegate {
    var apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "XAI_API_KEY") as? String
    var model = "grok-voice"
    var fallback: SpeechService = SystemSpeechService()

    private var player: AVAudioPlayer?
    private var onFinish: (() -> Void)?

    func speak(_ text: String, onFinish: @escaping () -> Void) {
        guard let apiKey, !apiKey.isEmpty, !text.isEmpty else {
            fallback.speak(text, onFinish: onFinish)
            return
        }
        self.onFinish = onFinish
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.x.ai/v1/audio/speech")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 20
                request.httpBody = try JSONSerialization.data(withJSONObject: [
                    "model": model,
                    "input": text
                ])

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    await MainActor.run { self.fallback.speak(text, onFinish: onFinish) }
                    return
                }

                await MainActor.run {
                    self.player = try? AVAudioPlayer(data: data)
                    guard let player = self.player else {
                        self.fallback.speak(text, onFinish: onFinish)
                        return
                    }
                    player.delegate = self
                    player.play()
                }
            } catch {
                await MainActor.run { self.fallback.speak(text, onFinish: onFinish) }
            }
        }
    }

    func stop() {
        player?.stop()
        fallback.stop()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
