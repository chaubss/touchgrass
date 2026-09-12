import Foundation

// Standalone checks; compile with Models/*.swift, Store/*.swift,
// Services/{AISummaryService,IFMSummaryService,IFMConfiguration}.swift.
final class RecapStub: URLProtocol, @unchecked Sendable {
    static var status = 200
    static var responseData = Data()
    static var requests = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests += 1
        precondition(request.url == IFMConfiguration.endpoint)
        precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        precondition(request.httpMethod == "POST")
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(contentsOf: buffer.prefix(count))
            }
        }
        let body = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        precondition(body["model"] as? String == IFMConfiguration.model)
        precondition((body["messages"] as? [[String: String]])?.count == 2)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status,
            httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct IFMRecapChecks {
    static func main() async throws {
        precondition((IFMConfiguration.summaryService(enabled: false) as? CachedSummaryService)?.upstream is SampleSummaryService)
        precondition((IFMConfiguration.summaryService(enabled: true) as? CachedSummaryService)?.upstream is IFMSummaryService)
        let store = KarmaStore.demo()
        let context = store.digestContext()
        precondition(context.grants.allSatisfy { !$0.toAndrewID.isEmpty })
        let oldContext = context
        let privateGrant = KarmaGrant(from: store.students[0].id, to: store.students[1].id,
            amount: 10, category: .kindness, reason: "PRIVATE_SENTINEL", isPublic: false, createdAt: Date())
        store.grants.insert(privateGrant, at: 0)
        precondition(store.digestContext() == oldContext)
        store.grants.insert(KarmaGrant(from: store.students[0].id, to: store.students[1].id,
            amount: 10, category: .kindness, reason: "Public help", isPublic: true, createdAt: Date()), at: 0)
        precondition(store.digestContext() != oldContext)
        let encodedContext = try JSONEncoder().encode(store.digestContext())
        precondition(!String(decoding: encodedContext, as: UTF8.self).contains("PRIVATE_SENTINEL"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RecapStub.self]
        var service = IFMSummaryService(apiKey: "test-key", session: URLSession(configuration: config))
        let payload: [String: Any] = ["headline": "Peers making space for learning", "body": ["One.", "Two.", "Three."],
            "mostHelpfulAndrewID": "not-in-data", "mostHelpfulNote": "Invented.",
            "topOrganizer": "not-in-data", "topOrganizerNote": "Invented."]
        let text = String(decoding: try JSONSerialization.data(withJSONObject: payload), as: UTF8.self)
        RecapStub.responseData = try JSONSerialization.data(withJSONObject: ["choices": [
            ["finish_reason": "stop", "message": ["content": "```json\n" + text + "\n```", "reasoning_content": "Not for display"]]
        ]])
        let live = try await service.weeklyDigest(context)
        precondition(live.source == .live && live.provider == "IFM K2 Horizon")
        precondition(live.mostHelpfulAndrewID == nil && live.topOrganizer == nil)
        let suite = "IFMRecapChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let cachedService = CachedSummaryService(upstream: service, defaults: defaults)
        let first = try await cachedService.weeklyDigest(context)
        precondition(first.source == .live && !first.isCached)
        let requestCount = RecapStub.requests
        // Recreate the service and defaults to simulate reopening the app with IFM off.
        let reopened = CachedSummaryService(upstream: SampleSummaryService(), defaults: UserDefaults(suiteName: suite)!)
        let saved = try await reopened.weeklyDigest(context)
        precondition(saved.isCached && saved.headline == first.headline && saved.generatedAt == first.generatedAt)
        precondition(RecapStub.requests == requestCount)
        let otherRange = DigestContext(weekOf: "another range", grants: [], events: [])
        let local = try await reopened.weeklyDigest(otherRange)
        precondition(!local.isCached && local.source == .sample)
        let upgraded = try await cachedService.weeklyDigest(otherRange)
        precondition(!upgraded.isCached && upgraded.source == .live)
        // Corrupt storage is ignored rather than crashing or blocking generation.
        defaults.set(Data("broken".utf8), forKey: "karma.ifmRecaps.v1")
        let recovered = try await cachedService.weeklyDigest(context)
        precondition(!recovered.isCached && recovered.source == .live)
        for status in [401, 429, 500] {
            RecapStub.status = status
            let fallback = try await service.weeklyDigest(context)
            precondition(fallback.source == .sample && fallback.notice != nil)
        }
        RecapStub.status = 200
        RecapStub.responseData = Data("malformed".utf8)
        let malformed = try await service.weeklyDigest(context)
        precondition(malformed.source == .sample && malformed.notice != nil)
        let requests = RecapStub.requests
        service.apiKey = "PASTE_IFM_API_KEY_HERE"
        let noKey = try await service.weeklyDigest(context)
        precondition(noKey.source == .sample && noKey.notice != nil && RecapStub.requests == requests)
        print("PASS: IFM request, decoding, private-data exclusion, feature flag, cache persistence, range misses, uncached local fallback, corrupt cache, HTTP errors and no-key fallback")
    }
}
