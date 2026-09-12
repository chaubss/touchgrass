# Karma — setup

## Making it run

1. Xcode → new **iOS App**, SwiftUI interface, product name `KarmaCMU`. Set the
   deployment target to **iOS 17.0** or later.
2. Delete the generated `ContentView.swift` and the generated `*App.swift` —
   `App/KarmaApp.swift` here is the `@main` entry point.
3. Drag every folder in this directory into the target, with **Create groups**
   selected. No Swift Package dependencies, no asset catalog entries needed —
   everything besides event photos is SF Symbols and procedural gradients.
   Event cards pull one stock photo per category over `AsyncImage`
   (`Features/Events/EventStyle.swift`); no network falls back to the old
   duotone wash.
4. Add these keys to **Info.plist**:

   | Key | Value |
   |---|---|
   | `NSLocationWhenInUseUsageDescription` | Karma shows events happening near you on campus and confirms you're there when you check in. |
   | `NSMicrophoneUsageDescription` | Karma uses your microphone to dictate why you're giving karma. |

5. Build and run.

## Before you demo

**Set a simulator location.** Features → Location → Custom Location, latitude
`40.4433`, longitude `-79.9436`. Without it the blue dot lands in Cupertino and
every proximity check-in fails with "You're 3,700 km away."

The event nearest in time (*Distributed systems, unplugged*) is seeded to be
live right now, so check-in works the moment you open the app. The rest are
staggered across the next five days.

**Suggested run of play:** Home → Give karma to Priya → watch both numbers move
→ Earn karma → Events map → tap the Cohon pin → Show these in the list →
check in → Redeem a dining block → Explore for the digest.

## Turning on the live digest

The weekly digest in Explore runs through `AISummaryService`. `SampleSummaryService`
ships enabled and returns one of three written digests after a short delay.

To generate against a real model, add `ANTHROPIC_API_KEY` or `XAI_API_KEY` to
Info.plist and change one line in `App/KarmaApp.swift`:

```swift
private let summaries: AISummaryService = AnthropicSummaryService()
// or:
private let summaries: AISummaryService = XAISummaryService()
```

Any failure — missing key, no network, malformed JSON — degrades silently to the
sample digest, so the demo can't break on stage. The badge on the card tells you
which one you're looking at, and names the provider once it's live.

An API key inside a shipped client is extractable by anyone who downloads it. In
production this call belongs behind your own backend.

## Voice

Two independent voice features, both built to degrade to something that works
today rather than doing nothing without a key:

- **Digest read-aloud** (the speaker icon on the Explore card) is a
  `SpeechService`, wired through `\.digestVoiceService`. It ships pointed at
  `SystemSpeechService` (the on-device voice, no key needed). Swap in
  `XAIVoiceService()` and add `XAI_API_KEY` to Info.plist to read it back in
  an xAI voice instead — that service's request shape is a best guess at
  xAI's (still-unconfirmed) `/v1/audio/speech` endpoint, so check it against
  their docs before relying on it. Either way, any failure falls back to the
  on-device voice.
- **"Say why" dictate / read back** (on the Give Karma sheet) talks to
  ElevenLabs directly — `ElevenLabsDictationService` for speech-to-text and
  `ElevenLabsSpeechService` for text-to-speech, both in
  `Services/ElevenLabsService.swift`. Add `ELEVENLABS_API_KEY` to Info.plist
  to turn them on. Read-back falls back to the on-device voice with no key;
  dictation has no on-device equivalent, so it surfaces a toast asking for a
  key instead of failing silently.

## What's mocked

Everything. `Store/MockData.swift` holds 14 students, 22 grants, 9 events and 9
redemption options. State lives in memory and resets on launch — there is no
persistence layer and nothing to reset between demo runs.

## Swift 6

The app uses no Combine. `LocationManager` is `@Observable` like `KarmaStore`,
injected with `.environment(_:)` and read with `@Environment(LocationManager.self)`.
This matters under Swift 6, where `import SwiftUI` no longer exposes
`ObservableObject` and `@Published` transitively — code using them needs an
explicit `import Combine`.

## Two things worth knowing

**The zoom transition is iOS 18+.** Event card → detail uses
`.navigationTransition(.zoom(sourceID:in:))`, gated behind `#available`. On
iOS 17 you get a standard push. `matchedGeometryEffect` can't cross a
navigation boundary, and the workarounds all cost scroll position.

**Proximity check-in is enforced at 150 m** — but only when a location fix
exists. If permission is denied or there's no fix, the radius isn't applied and
check-in falls back to the event's time window, so a denied prompt never
dead-ends the flow.
