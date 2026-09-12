# Optional Karma backend

Standalone FastAPI + MongoDB development backend. **No Swift, Xcode, UI, or
frontend configuration is changed.** The existing app still uses its in-memory
store and existing providers. Starting this backend does not connect the app to
it. A future, separately authorized client-adapter change is required for that.

## Start (Docker only)

Docker Desktop/Engine and Compose must already be available. No host Python,
pip, MongoDB or other package installation is needed. From `backend/`:

1. Copy `.env.example` to `.env` in your editor.
2. To enable the demo set `BACKEND_ENABLED=true`, `DEMO_AUTH_ENABLED=true`,
   `SEED_DEMO_DATA=true` and a random `DEMO_TOKEN` of at least 24 characters.
   You can generate a token inside a container:
   `docker compose run --rm --no-deps api python -c 'import secrets; print(secrets.token_urlsafe(32))'`
3. Run `docker compose up --build -d`.
4. Open `http://localhost:8000/docs` for the API contract. Add an
   `Authorization: Bearer YOUR_DEMO_TOKEN` header to protected requests.

If your machine uses Docker Desktop's named context, prefix commands with
`docker --context desktop-linux compose` instead of `docker compose`.

## Switches and shutdown

| Variable | Default | Behavior |
|---|---|---|
| `BACKEND_ENABLED` | `false` | Master switch. `/v1/*` returns 503 with `backend_disabled`; no MongoDB connection or provider call from API. |
| `DEMO_AUTH_ENABLED` | `false` | Enables a single seeded demo identity, only with a token of 24+ characters. |
| `SEED_DEMO_DATA` | `false` | Inserts missing fictional demo records; never overwrites existing records or balances. |
| `IFM_ENABLED` | `false` | Allows IFM recap generation using `IFM_API_KEY`. Cached recaps can still be read when off. |
| `ELEVENLABS_ENABLED` | `false` | Allows Scribe v2 transcription using `ELEVENLABS_API_KEY`. |
| `BACKEND_PORT` | `8000` | API host port, bound to 127.0.0.1 only. |

After changing `.env`, run `docker compose up -d --force-recreate api`.
Disabling the flag preserves database contents and leaves health/docs available.
`docker compose down` stops the entire backend and preserves the MongoDB volume.
Do **not** add `-v` unless you intend to delete the database. Containers can still
run with the master flag off; use `down` when you want no backend processes.

## API coverage

| Route | Purpose |
|---|---|
| `GET /health/live`, `/health/ready` | Process/database health; usable with backend off |
| `GET /v1/config` | Non-secret feature-flag status |
| `GET /v1/me` | Own wallet and monthly allowance |
| `GET /v1/students?q=` | Public profile search (no other students' balances) |
| `GET /v1/me/ledger` | Own transaction history; `limit` and `offset` |
| `GET /v1/grants` | Public and own private recognitions; `limit` and `offset` |
| `POST /v1/grants` | Give karma, debit sender, credit recipient |
| `PUT /v1/grants/{id}/cheer?active=true` | Retry-safe desired cheer state |
| `GET /v1/events` | Events with per-user check-in status |
| `POST /v1/events/{id}/check-in` | Check-in and award karma once |
| `GET /v1/catalog` | Redemption catalog, existing frontend image asset names |
| `POST /v1/redemptions` | Reward claim or donation receipt (demo, no actual fulfillment) |
| `GET /v1/me/badges` | Six badges derived from persisted actions |
| `GET /v1/recap` | Rolling seven-day public-activity recap, local by default |
| `POST /v1/transcriptions` | Multipart `file`, Scribe v2, independently gated |

All mutations that affect balances require `Idempotency-Key` (8–128 characters).
Use a new UUID for a new user action; reuse the **same** key and body after a
timeout. Reusing a key with a different body returns 409. MongoDB transactions
make transfers, inventory, ledger entries and receipts atomic. The single-node
replica set is needed for transactions; it is not high availability.

Example (substitute your token):

```sh
curl http://localhost:8000/v1/grants \
  -H 'Authorization: Bearer YOUR_DEMO_TOKEN' \
  -H 'Idempotency-Key: a-unique-action-uuid' \
  -H 'Content-Type: application/json' \
  -d '{"to":"22222222-2222-4222-8222-222222222222","amount":25,"category":"teaching","reason":"Helped explain the assignment","isPublic":true}'
```

Giving enforces 1–100 karma, a 10–140 character trimmed reason, a sufficient
wallet and 500/month giving allowance, no self-gifts, and at most three gifts
to the same recipient in a rolling seven days. Monthly allowances reset lazily
at **UTC calendar month** boundaries without adding wallet funds. Check-in opens
30 minutes before an event and closes at its end; supplied coordinates must be
within 150 m. Missing coordinates retain the current app's permissive fallback.
Fixed reward prices come from the server, never from caller-supplied amounts.

## Persistence and security boundary

Collections: students, grants, ledger, events, checkins, catalog, redemptions,
cheers, operations (idempotency results), recaps. Dates use UTC ISO-8601 JSON,
fields generally follow the Swift camelCase names. Most IDs are UUID strings;
catalog IDs are stable slugs, so this is an API contract, **not** automatic Swift
Codable compatibility. No import/export of the current local app state is done.

This is **local development only**, not production-ready authentication. The
single bearer token maps to Demo Student; clients cannot select an arbitrary
actor. MongoDB has no host port but is unauthenticated inside the dedicated
Compose network. Before public deployment add real identity verification,
MongoDB authentication/TLS, secrets management, rate limits, request-body limits
at the ingress, backups, abuse-resistant attendance, monitoring and fulfillment.
No permissive CORS middleware is installed. No secrets are baked into the image.
Never copy existing Swift keys into source; configure new keys only in `.env`.

IFM receives at most 30 public grants and 10 past events, never private reasons.
Successful IFM JSON recaps are cached per UTC date range for 14 days; local
fallbacks are not cached. AI failures return an explicitly local recap. Core
database failures return 503 and never pretend a transfer succeeded. Transcribed
audio is forwarded to ElevenLabs and not stored in MongoDB; framework temporary
upload files are request-scoped. This is speech-to-text, not tone detection.

The seeded event times are set once on initial creation and are not advanced on
restart. Expired demo events remain expired. No automatic data reset is performed.

## Tests (real MongoDB, entirely in containers)

```sh
docker compose --profile test run --build --rm tests
```

For older Compose versions without `run --build`, use:

```sh
docker compose --profile test build
docker compose --profile test run --rm tests
```

Each integration test creates and removes only its unique `karma_test_*`
database. Tests cover the master off switch without MongoDB, authentication,
wallet/allowance rules, retry idempotency, concurrent duplicate gifts, atomic
rollback, private recap exclusion and provider flags. Tests never call paid APIs.

Reference: [FastAPI containers](https://fastapi.tiangolo.com/deployment/docker/),
[MongoDB transactions](https://www.mongodb.com/docs/languages/python/pymongo-driver/current/crud/transactions/).
