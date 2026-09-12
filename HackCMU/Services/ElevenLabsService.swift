import AVFoundation

/// Voice for the "Say why" box on the Give Karma sheet: read a typed reason
/// back, or dictate one instead of typing it. Both degrade gracefully with
/// no `ELEVENLABS_API_KEY` set — read-back falls back to the on-device voice,
/// and dictation surfaces a toast rather than failing silently, since there's
/// no on-device transcription fallback wired up here.

/// Text-to-speech for the reason box. Falls back to `SystemSpeechService`
/// on any failure, same shape as `AnthropicSummaryService`.
final class ElevenLabsSpeechService: NSObject, SpeechService, AVAudioPlayerDelegate {
    var apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String
    /// ElevenLabs' default pre-made voice ("Rachel"). Swap for any voice ID
    /// from the account the key belongs to.
    var voiceID = "21m00Tcm4TlvDq8ikWAM"
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
                var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
                request.timeoutInterval = 20
                request.httpBody = try JSONSerialization.data(withJSONObject: [
                    "text": text,
                    "model_id": "eleven_multilingual_v2"
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

/// Speech-to-text for the reason box. Records to a temp file, then ships it
/// to ElevenLabs' Scribe model for transcription.
final class ElevenLabsDictationService: NSObject {
    enum DictationError: LocalizedError {
        case notConfigured, noRecording, requestFailed

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Add an ElevenLabs API key in Info.plist to transcribe recordings."
            case .noRecording:
                return "Nothing was recorded."
            case .requestFailed:
                return "ElevenLabs couldn't transcribe that. Try again."
            }
        }
    }

    var apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        self.recorder = recorder
        self.recordingURL = url
    }

    /// Stops recording and transcribes it. Throws `.notConfigured` when no
    /// key is set yet — callers should show that as a toast, not an error.
    func stopRecordingAndTranscribe() async throws -> String {
        recorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let apiKey, !apiKey.isEmpty else { throw DictationError.notConfigured }
        guard let recordingURL else { throw DictationError.noRecording }

        let audioData = try Data(contentsOf: recordingURL)
        try? FileManager.default.removeItem(at: recordingURL)

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/speech-to-text")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("scribe_v1\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"reason.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DictationError.requestFailed
        }

        struct Payload: Decodable { let text: String }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return payload.text
    }
}
