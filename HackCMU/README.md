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

Explore uses the local, data-derived recap by default (no network or downloaded
language model). This demo calls `https://api.ifm.ai/v1/chat/completions` with Bearer
authentication and model `IFM/K2-Horizon-375B-A23B`, per the supplied IFM example.

The prompt lives in `Services/IFMSummaryService.swift`. Each generation receives
the latest rolling seven-day snapshot: up to 30 newest **public** recognitions
(including recipient Andrew IDs) and 10 newest past events. Private notes are
never sent. Sign-ups are explicitly distinguished from verified attendance.
The prompt asks for a short headline, three evidence-grounded paragraphs and
optional peer/organizer spotlights. Returned spotlight identifiers are checked
against the snapshot before display. Free-text input is treated as data, not
instructions. This is still demo data from the in-memory store, not a live CMU feed.

Explore loads a recap when its snapshot changes, on pull-to-refresh, or using the
refresh icon. Successful IFM recaps are stored in UserDefaults by date-range
string and reused for that range, including after relaunch and with IFM disabled.
These are saved snapshots: changes within a cached range do not regenerate it.
The newest 14 generated ranges are retained; local fallbacks are never cached.
Corrupt cache data is ignored. No API credentials are stored in the recap cache.
The card always shows `Powered by IFM` branding with a sparkles icon, with a tiny
`Cached` badge for saved IFM output or a `Local recap` source label for local text. Missing
keys, network errors, denied access, rate limits and invalid responses produce a
data-derived `Local recap` with an explanatory notice, never a fake AI success.
No API keys or provider response bodies are logged. Live requests need a valid
key and model access; offline checks do not establish provider availability.

An API key inside a shipped client is extractable. This placeholder is for local
demos only; production calls belong behind your authenticated backend, which
holds the key and enforces privacy, quotas and abuse controls.

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
  `Services/ElevenLabsService.swift`. Paste a demo key into
  `Services/ElevenLabsConfiguration.swift` (or set `ELEVENLABS_API_KEY` in Info.plist)
  and rebuild. Dictate → allow microphone → speak → Stop & transcribe uses
  `scribe_v2` and inserts editable text without changing the karma amount.
  Audio is sent to ElevenLabs; temporary local recordings are deleted after the
  request, on failure, or cancellation. Dismissing the sheet cancels dictation.
  Read-back falls back to the on-device voice with no key; dictation shows a
  configuration message and typing remains available.

Tone-based amount suggestions are deliberately not enabled. Scribe's documented
[transcription API](https://elevenlabs.io/docs/api-reference/speech-to-text/convert)
offers sound-event tagging, not an excitement score. ElevenAgents
[Expressive mode](https://elevenlabs.io/docs/eleven-agents/customization/voice/expressive-mode)
is a different conversational-agent integration. Laughter, loudness, or enthusiastic
words alone are not treated as evidence that the speaker wants to give more karma.


## Swift 6

The app uses no Combine. `LocationManager` is `@Observable` like `KarmaStore`,
injected with `.environment(_:)` and read with `@Environment(LocationManager.self)`.
This matters under Swift 6, where `import SwiftUI` no longer exposes
`ObservableObject` and `@Published` transitively — code using them needs an
explicit `import Combine`.
