## Why

The website needs a lightweight multiplayer layer for the browser fishing game so players can see who else is currently fishing and share simple reactions in real time. This change adds that presence-style backend support without introducing accounts, persisted game state, or database-backed player records.

## What Changes

- Add a new `Fishing.Fisher` domain context to model connected fishers and validate their avatar and game selections.
- Add a websocket entrypoint at `/fishing/socket` for the decoupled React frontend.
- Add a `Fishing.NameCheck` moderation step that calls OpenAI over REST before a fisher is admitted to the shared lobby.
- Return the connecting fisher's backend-generated UUID together with the full list of currently connected fishers.
- Broadcast updated fisher lists when players join or disconnect.
- Accept and rebroadcast only a strict allowlist of emotes: `wave`, `thumbs_up`, `thumbs_down`, `laugh`, `sad`, and `catch_fish`.
- Ignore invalid emote payloads instead of relaying arbitrary client strings.
- Reject offensive, bullying, sexual, player-targeting, or prompt-injection-style names before they reach the presence roster.
- Add `docs/SOCKET_SPEC.md` with frontend-facing Phoenix socket setup instructions, connection examples, and message contracts.
- Keep all multiplayer state in memory only, with no user accounts, scores, or persisted session history.

## Capabilities

### New Capabilities
- `fishing-fisher-socket`: Real-time multiplayer fishing presence and emote broadcasting over `/fishing/socket`.

### Modified Capabilities

None.

## Impact

- Affected code: Phoenix socket endpoint and channel/socket modules, new `Fishing`, `Fishing.Fisher`, and `Fishing.NameCheck` domain modules, supervision/runtime state management, OpenAI REST integration via `Req`, docs for frontend integration, and tests for websocket behavior and validation.
- APIs: Adds a new websocket API at `/fishing/socket` with join, presence list, disconnect refresh, and emote broadcast behavior.
- Dependencies: No new package dependencies expected; implementation should use Phoenix, Elixir, OTP primitives, and the already available `Req` HTTP client for the OpenAI moderation request.
- Systems: In-memory connected-player tracking only; no changes to the existing user database or authentication flows.
