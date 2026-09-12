import SwiftUI

protocol AISummaryService {
    func weeklyDigest(_ context: DigestContext) async throws -> WeeklyDigest
}

/// Ships enabled. The delay exists so the loading state is actually visible
/// during a demo rather than flashing past.
struct SampleSummaryService: AISummaryService {
    func weeklyDigest(_ context: DigestContext) async throws -> WeeklyDigest {
        try await Task.sleep(for: .milliseconds(1200))

        let total = context.grants.reduce(0) { $0 + $1.amount }
        let recipients = Set(context.grants.map(\.to)).count
        let teaching = context.grants.filter { $0.category == "teaching" }.count
        let attendance = context.events.reduce(0) { $0 + $1.attending }
        return WeeklyDigest(
            headline: "Small acts of support across campus",
            body: [
                "\(context.grants.count) recognitions shared \(total) karma with \(recipients) students this week.",
                "\(teaching) notes recognized teaching and study support. Other students thanked peers for project feedback, event setup, and everyday help.",
                "\(context.events.count) recent campus sessions recorded \(attendance) attendances. These include reading groups and student service activities."
            ],
            mostHelpfulAndrewID: nil, mostHelpfulNote: nil,
            topOrganizer: nil, topOrganizerNote: nil,
            generatedAt: Date(), source: .sample
        )
    }
}

/// Live implementation. The digest is the only thing in this app that talks to
/// a network.
///
/// Shipping an API key inside a client is unsafe — anyone can extract it from
/// the binary. In production this call belongs behind your own backend, which
/// holds the key and forwards the request. It's here so the demo can show a
/// real generation.
struct AnthropicSummaryService: AISummaryService {
    var apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String
    var model = "claude-sonnet-4-6"
    var fallback: AISummaryService = SampleSummaryService()

    private struct Payload: Decodable {
        let headline: String
        let body: [String]
        let mostHelpfulAndrewID: String?
        let mostHelpfulNote: String?
        let topOrganizer: String?
        let topOrganizerNote: String?
    }

    func weeklyDigest(_ context: DigestContext) async throws -> WeeklyDigest {
        guard let apiKey, !apiKey.isEmpty else {
            return try await fallback.weeklyDigest(context)
        }

        do {
            let contextJSON = String(
                data: try JSONEncoder().encode(context), encoding: .utf8
            ) ?? "{}"

            let system = """
            You summarise a week of peer recognition at Carnegie Mellon for a student app.
            Find the real pattern in the data — what kind of help was valued, what changed, \
            what is worth noticing — rather than restating counts. Name one person who was \
            most helpful (by Andrew ID) and one best event organiser (by full name), each \
            with a one-sentence reason drawn from the actual grant reasons.
            Write plainly. No exclamation marks, no hype, no emoji.
            Respond with JSON only, no markdown fences, matching exactly:
            {"headline": string, "body": [string, string, string],
             "mostHelpfulAndrewID": string, "mostHelpfulNote": string,
             "topOrganizer": string, "topOrganizerNote": string}
            """

            var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.timeoutInterval = 20
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": model,
                "max_tokens": 1000,
                "system": system,
                "messages": [["role": "user", "content": contextJSON]]
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return try await fallback.weeklyDigest(context)
            }

            // Concatenate every text block; ignore any other block types.
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let blocks = root?["content"] as? [[String: Any]] ?? []
            let text = blocks
                .filter { $0["type"] as? String == "text" }
                .compactMap { $0["text"] as? String }
                .joined()

            let cleaned = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let payloadData = cleaned.data(using: .utf8) else {
                return try await fallback.weeklyDigest(context)
            }
            let payload = try JSONDecoder().decode(Payload.self, from: payloadData)

            return WeeklyDigest(
                headline: payload.headline,
                body: payload.body,
                mostHelpfulAndrewID: payload.mostHelpfulAndrewID,
                mostHelpfulNote: payload.mostHelpfulNote,
                topOrganizer: payload.topOrganizer,
                topOrganizerNote: payload.topOrganizerNote,
                generatedAt: Date(), source: .live, provider: "Anthropic"
            )
        } catch {
            // Any failure degrades to the sample digest rather than an error state.
            return try await fallback.weeklyDigest(context)
        }
    }
}

/// Live implementation using xAI's Grok models over its OpenAI-compatible
/// chat-completions endpoint. Same shape as `AnthropicSummaryService` —
/// missing key or any failure degrades to the sample digest.
struct XAISummaryService: AISummaryService {
    var apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "XAI_API_KEY") as? String
    var model = "grok-4"
    var fallback: AISummaryService = SampleSummaryService()

    private struct Payload: Decodable {
        let headline: String
        let body: [String]
        let mostHelpfulAndrewID: String?
        let mostHelpfulNote: String?
        let topOrganizer: String?
        let topOrganizerNote: String?
    }

    func weeklyDigest(_ context: DigestContext) async throws -> WeeklyDigest {
        guard let apiKey, !apiKey.isEmpty else {
            return try await fallback.weeklyDigest(context)
        }

        do {
            let contextJSON = String(
                data: try JSONEncoder().encode(context), encoding: .utf8
            ) ?? "{}"

            let system = """
            You summarise a week of peer recognition at Carnegie Mellon for a student app.
            Find the real pattern in the data — what kind of help was valued, what changed, \
            what is worth noticing — rather than restating counts. Name one person who was \
            most helpful (by Andrew ID) and one best event organiser (by full name), each \
            with a one-sentence reason drawn from the actual grant reasons.
            Write plainly. No exclamation marks, no hype, no emoji.
            Respond with JSON only, no markdown fences, matching exactly:
            {"headline": string, "body": [string, string, string],
             "mostHelpfulAndrewID": string, "mostHelpfulNote": string,
             "topOrganizer": string, "topOrganizerNote": string}
            """

            var request = URLRequest(url: URL(string: "https://api.x.ai/v1/chat/completions")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 20
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": model,
                "messages": [
                    ["role": "system", "content": system],
                    ["role": "user", "content": contextJSON]
                ],
                "response_format": ["type": "json_object"]
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return try await fallback.weeklyDigest(context)
            }

            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let choices = root?["choices"] as? [[String: Any]] ?? []
            let text = (choices.first?["message"] as? [String: Any])?["content"] as? String ?? ""

            let cleaned = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let payloadData = cleaned.data(using: .utf8) else {
                return try await fallback.weeklyDigest(context)
            }
            let payload = try JSONDecoder().decode(Payload.self, from: payloadData)

            return WeeklyDigest(
                headline: payload.headline,
                body: payload.body,
                mostHelpfulAndrewID: payload.mostHelpfulAndrewID,
                mostHelpfulNote: payload.mostHelpfulNote,
                topOrganizer: payload.topOrganizer,
                topOrganizerNote: payload.topOrganizerNote,
                generatedAt: Date(), source: .live, provider: "xAI"
            )
        } catch {
            return try await fallback.weeklyDigest(context)
        }
    }
}

private struct SummaryServiceKey: EnvironmentKey {
    static let defaultValue: AISummaryService = SampleSummaryService()
}

extension EnvironmentValues {
    var summaryService: AISummaryService {
        get { self[SummaryServiceKey.self] }
        set { self[SummaryServiceKey.self] = newValue }
    }
}
