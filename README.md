# Karma

### Good comes around.

A campus community app built for HackCMU that makes everyday support visible.
Thank the classmate who helped debug your project, show up for a campus event,
and turn participation into rewards or support for the community.

**SwiftUI · IFM K2 Horizon · ElevenLabs · FastAPI · MongoDB · Docker**

## Recognition that feels personal

College communities run on small acts of generosity: explaining a difficult
concept, carrying a team through a deadline, or helping an event come together.
Karma gives those moments a place to live.

- **Give recognition.** Send karma with a specific reason, written or spoken.
- **Discover campus.** Explore events on a map, find nearby activities, and check in.
- **Celebrate progress.** Earn badges such as First Ripple, Bug Whisperer, Pantry Pal,
  and Full Circle, with clear progress toward the next milestone.
- **Put karma to use.** Explore campus dining and store rewards, or donation options
  featuring the CMU Food Pantry and Greater Pittsburgh Community Food Bank.
- **See the bigger picture.** Read a weekly recap of the help and participation
  shaping the community.

## IFM K2 Horizon — turning activity into a story

Our recap integration uses **IFM/K2-Horizon-375B-A23B** to turn a rolling seven-day
activity snapshot into a readable campus summary.

Instead of simply repeating a transaction list, the prompt asks the model to
identify patterns of peer support, explain concrete examples, and highlight
people and organizers when the data supports it. The response becomes a concise
headline, three short paragraphs, and optional spotlights.

The integration is designed around grounded output:

- Only public recognition notes enter the recap context.
- Event sign-ups are distinguished from verified attendance.
- Spotlight identifiers are checked against the supplied activity.
- Successful recaps are cached by date range for reuse.
- A data-derived local summary keeps the recap useful when generation is unavailable.

## ElevenLabs — say the thank-you out loud

**ElevenLabs Scribe v2** powers speech-to-text for the reason behind a karma gift.
Record a short message, transcribe it, then review and edit the text before sending.

The voice flow includes microphone permission handling, recording and transcription
states, cancellation, and temporary-recording cleanup. ElevenLabs text-to-speech
also supports reading a reason back, with an on-device voice fallback.

The student stays in control: dictation does not send a gift or change its amount.

## FastAPI + MongoDB — a foundation for persistence

The standalone **FastAPI** backend provides a documented REST API for profiles,
balances, recognitions, event check-ins, redemptions, badge progress, recaps, and
transcription. **Pydantic** validates incoming requests, while generated OpenAPI
documentation makes the API easy to explore.

**MongoDB** stores community activity and account history. Balance-changing
operations use transactions so wallet updates, ledger entries, and reward receipts
succeed or fail together. Retry-safe requests prevent a repeated submission from
issuing the same gift or reward twice.

**Docker Compose** packages the API, MongoDB replica set, and integration-test
environment. Dependencies run inside containers rather than requiring a local
Python or MongoDB installation.

## Native campus experience

The iOS app is built with **SwiftUI**, using **MapKit** and **Core Location** for
event discovery and the current-location indicator. **AVFoundation** handles audio
recording and playback. Campus photography, warm surfaces, and compact achievement
cards give the interface a familiar, student-centered feel.

| Technology | Role in Karma |
|---|---|
| SwiftUI | Native iOS screens and interactions |
| MapKit + Core Location | Campus map, location, and event proximity |
| IFM K2 Horizon | Evidence-grounded weekly community recaps |
| ElevenLabs Scribe v2 | Spoken recognition converted into editable text |
| ElevenLabs text-to-speech | Audio read-back of recognition reasons |
| FastAPI + Pydantic | REST endpoints, request validation, and API documentation |
| MongoDB + PyMongo | Persistent records and transactional balance updates |
| Docker Compose | Reproducible backend and test environment |
| pytest | Backend integration and concurrency checks |

## Built with care

The backend's integration suite covers giving limits, insufficient balances,
concurrent requests, duplicate submissions, redemption rollback, check-ins,
private-note exclusion, and recap caching. Tests run against a real MongoDB
instance in Docker, with external AI requests mocked.

## Project layout

```text
HackCMU/                Native iOS application
  App/                  App entry point and navigation
  Features/             Home, events, redemptions, explore, and profiles
  Models/               Karma, events, rewards, badges, and recaps
  Services/             Location, IFM, ElevenLabs, and local recap services
  Store/                In-app state and demonstration data
backend/                Standalone FastAPI service and Docker environment
  app/                  API routes, business rules, persistence, and AI integrations
  tests/                MongoDB-backed integration tests
Tests/                  Standalone Swift integration checks
HackCMU.xcodeproj/       Xcode project
```

## Hackathon prototype

Karma currently demonstrates the campus experience with fictional activity and
sample rewards. The iOS app and standalone backend are implemented separately;
client-to-backend wiring remains future work. Reward claims and donations are
demonstrations, not live fulfillment or official university partnerships.

**A little recognition can make a campus feel more connected.**
