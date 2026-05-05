## Context

The backend currently exposes JSON HTTP APIs and LiveView, but it does not expose any custom Phoenix socket endpoint or channel. This change introduces a small real-time subsystem for the fishing game, where all state is ephemeral and scoped to the currently connected clients.

The frontend is a separate React application, so the websocket contract must be explicit and stable. There is no account system for this feature, and the backend must not reuse the existing user database or authentication flow. The only state to track is the connected fisher's chosen display name, avatar selections, game mode, backend-assigned UUID, and short-lived emote events.

## Goals / Non-Goals

**Goals:**
- Expose a websocket endpoint at `/fishing/socket` that the React client can use independently of Phoenix HTML.
- Validate incoming fisher metadata and assign a backend UUID for each connection.
- Moderate candidate fisher names through OpenAI before the fisher is admitted to the lobby.
- Produce a frontend-consumable `docs/SOCKET_SPEC.md` that documents Phoenix client setup and the socket protocol.
- Return the connecting fisher ID and the current online fisher list on join.
- Broadcast refreshed fisher lists on join and disconnect.
- Broadcast only supported emotes from a strict allowlist.
- Keep the implementation fully in memory and OTP-managed.

**Non-Goals:**
- Persist fishers, emotes, scores, or session history.
- Add user registration, login, or any coupling to the existing user schema.
- Implement gameplay simulation or browser-side fishing logic on the backend.
- Add matchmaking, room persistence, or historical presence analytics.

## Decisions

### Use a dedicated Phoenix socket and channel
The system will add a dedicated socket endpoint at `/fishing/socket` and a single channel for fishing multiplayer events. This keeps the contract isolated from LiveView and existing HTTP APIs while still using Phoenix's mature websocket stack.

The channel protocol will use one shared topic and one state-shaped server message flow for roster updates so the React client can consume a single payload shape and update state with minimal branching.

The implementation will use the Phoenix channel protocol directly, with one lobby topic for the initial version.

Alternative considered:
- Plain raw websocket handling. Rejected because Phoenix channels already provide transport lifecycle handling, topic-based messaging, and test support with less custom code.

### Treat the initial fisher payload as channel join parameters
The frontend will connect to `/fishing/socket` and join the fishing channel with `name`, avatar selections, and `game`. The backend will trim and validate the payload, run the candidate name through a moderation step, generate the fisher UUID only after approval, and return it in the join reply payload along with the current list of fishers.

This matches the requested response shape while avoiding trust in any client-supplied `id`. It also gives the server a clear validation boundary before the fisher becomes visible to others.

Alternative considered:
- Accepting the fisher payload during the low-level socket `connect/3` callback. Rejected because Phoenix channel join replies are a cleaner place to return the initial fisher list and generated UUID.

### Gate lobby admission with a dedicated `Fishing.NameCheck` module
The join flow will call a new `Fishing.NameCheck` module before adding the fisher to the in-memory roster. That module will use the existing `Req` client to call OpenAI over REST with a small system prompt describing disallowed names and the trimmed candidate username as plain input data.

The moderation request should use a small, fast model and require a JSON response that reduces the decision to a boolean allow-or-reject outcome. The channel can then either continue the join or reject it with `%{reason: "NAME"}`. User input must never be interpolated into the system prompt itself; it should only be passed as untrusted content in the request body.

If the moderation request times out or the API returns an error, the backend should reject the join with `%{reason: "SERVER_ERROR"}` rather than admitting the fisher or collapsing the failure into a normal name-rejection response.

Alternative considered:
- Pure local word-list filtering only. Rejected because the requested policy includes contextual categories like bullying, sexual content, and references to other players that are better handled by a moderation model.

### Use one shared lobby and one simple event surface
The multiplayer experience will use one global lobby because concurrent player counts are expected to remain very small. The backend will not segment players by map, room, or game instance in the first version.

Server-to-client updates for presence changes will keep the same roster-oriented shape so the React app can handle them through one update path. Emote broadcasts will continue using the requested payload shape, with `current_fisher_id` included and `emote` populated when applicable.

Implementation should also ship a `docs/SOCKET_SPEC.md` document that explains how the frontend installs the Phoenix client library, connects to the socket, joins the lobby topic, handles join failures, and consumes the join / roster / emote payloads.

Alternative considered:
- Multiple lobbies or per-mode channels. Rejected because the feature is intentionally small and expected concurrency does not justify the added routing complexity.

### Restrict socket origins with an explicit allowlist
The socket will allow cross-site connections only from `https://lager.bankasviken.se` and `http://localhost:3000` through Phoenix `check_origin` configuration. No additional bot-specific rejection logic will be added in the first version beyond the origin allowlist.

Alternative considered:
- Adding join tokens or rate limiting in the first version. Rejected to keep the initial implementation simple while still avoiding fully open cross-site socket access.

### Keep connected fisher state in a supervised in-memory process
The system will introduce a supervised runtime process, likely a `GenServer`, owned by the new `Fishing` context. That process will hold the authoritative map of connected fishers keyed by channel process or generated fisher ID.

The channel will register join and leave events with the context, and the context will produce normalized fisher payloads for broadcast. This keeps validation and state mutation out of the transport layer and makes the logic testable without a browser client.

Alternative considered:
- Using only `Phoenix.Presence` metadata as the source of truth. Rejected for the first version because a small dedicated process is simpler for strict payload shaping and emote rules, while still leaving room to adopt `Phoenix.Presence` later if richer presence diffs are needed.

### Broadcast full fisher lists for membership changes
When a fisher joins or disconnects, the server will broadcast the full current `fishers` list together with the receiving client's `current_fisher_id` when relevant. Broadcasting the whole list keeps the frontend integration simple and directly matches the requested payload contract.

The roster will be shared across both game modes. Clients will use each fisher's `game` value to render the timed fishers as more active and the casual fishers as relaxed, but the backend will not split visibility by mode.

Alternative considered:
- Broadcasting incremental join/leave diffs. Rejected because the requested contract is list-based, and the active player count is expected to stay small.

### Validate avatar fields and emotes with explicit allowlists
The `Fishing.Fisher` domain model will validate:
- `name` as a trimmed non-empty string with a maximum length of 10 characters
- `hat` and `hair` as integers `0..7`
- `skin`, `coat`, `shirt`, and `pants` as integers `1..7`
- `game` as one of `casual` or `timed`

Incoming emote messages will only accept `wave`, `thumbs_up`, `thumbs_down`, `laugh`, `sad`, and `catch_fish`. Invalid emotes will be ignored and not rebroadcast.

Invalid join payloads will be rejected during channel join with a simple client-visible error response equivalent to a friendly `400`-style rejection, without exposing detailed validation guidance.

Names that fail moderation will also be rejected during join with `%{reason: "NAME"}` so the frontend can prompt the player to choose another name.

Alternative considered:
- Passing client payloads through without strict checks. Rejected because the backend is the multiplayer trust boundary and must prevent unsupported or unsafe values from being relayed.

### Rely on Phoenix websocket transport keepalive behavior
The backend will rely on Phoenix websocket lifecycle handling and transport heartbeats rather than designing a custom game-level keepalive message for the first version. Disconnect cleanup will happen when the channel process terminates.

Alternative considered:
- Defining custom ping/pong events in the channel protocol. Rejected as unnecessary unless the frontend proves it cannot rely on the normal Phoenix client transport behavior.

## Risks / Trade-offs

- [The React client may try to use a raw WebSocket instead of the Phoenix channel protocol] -> Document that `/fishing/socket` is a Phoenix socket endpoint and provide the event contract expected after channel join.
- [Full-list broadcasts are less efficient than diffs] -> Accept this trade-off for simplicity because the fisher population is expected to be small and non-persistent.
- [An in-memory registry loses all state on deploy or node restart] -> This is acceptable because the feature intentionally has no persistence and clients can reconnect.
- [Open sockets can carry malformed payloads] -> Centralize validation in the `Fishing.Fisher` and channel event handling layers, and ignore invalid emotes.
- [OpenAI moderation adds latency or outages to join flow] -> Keep the prompt and response contract minimal, use a small fast model, enforce short timeouts, and return a distinct server error reason on upstream failures.
- [Future multi-node deployment would require cross-node presence] -> Keep the first version node-local; revisit with Presence or PubSub-backed coordination only if deployment topology requires it.

## Migration Plan

1. Add the new socket endpoint and fishing channel modules.
2. Add the `Fishing` / `Fishing.Fisher` runtime state and validation layer under supervision.
3. Add channel tests for join, invalid join payloads, emote broadcasting, invalid emotes, and disconnect list refreshes.
4. Deploy without data migration requirements.
5. Roll back by removing the socket endpoint and supervised fishing process if needed.

## Open Questions

None.
