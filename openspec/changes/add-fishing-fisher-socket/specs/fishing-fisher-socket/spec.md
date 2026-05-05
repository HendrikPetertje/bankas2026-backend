## ADDED Requirements

### Requirement: Fishers can join the multiplayer fishing socket
The system SHALL expose a fishing multiplayer websocket at `/fishing/socket` that accepts a fisher join payload containing `name`, `hat`, `hair`, `skin`, `coat`, `shirt`, `pants`, and `game`, validates those fields, checks the trimmed candidate name through a `Fishing.NameCheck` OpenAI REST moderation step, generates a UUID for the connecting fisher only after approval, and returns the generated `current_fisher_id` together with the current `fishers` list.

#### Scenario: Valid fisher joins successfully
- **WHEN** a client connects to `/fishing/socket` and joins the fishing multiplayer channel with a valid fisher payload
- **THEN** the system checks the trimmed candidate name through the moderation step before adding the fisher to the roster
- **THEN** the system generates a UUID for that fisher instead of trusting any client-provided ID
- **THEN** the join reply includes `current_fisher_id`
- **THEN** the join reply includes a `fishers` list containing the newly joined fisher and all other currently connected fishers
- **THEN** each fisher in the list includes `id`, `name`, `hat`, `hair`, `skin`, `coat`, `shirt`, `pants`, and `game`

#### Scenario: Invalid fisher payload is rejected
- **WHEN** a client joins the fishing multiplayer channel with a blank name, a name longer than 10 characters after trimming, an out-of-range avatar option, or an unsupported `game` value
- **THEN** the system rejects the join request
- **THEN** the system returns a simple friendly error response without detailed validation hints
- **THEN** the invalid fisher does not appear in the online `fishers` list

#### Scenario: Names are trimmed before acceptance
- **WHEN** a client joins with a valid name containing leading or trailing whitespace
- **THEN** the system trims the name before storing and broadcasting the fisher

#### Scenario: Moderated name is rejected before presence admission
- **WHEN** the moderation step marks the trimmed name as sexual, bullying, player-targeting, offensive, or prompt-injection-style content
- **THEN** the system rejects the join request with `%{reason: "NAME"}`
- **THEN** the fisher is not added to the shared roster

### Requirement: The socket maintains a live online fisher roster
The system SHALL keep an in-memory roster of currently connected fishers and broadcast the updated `fishers` list to connected clients whenever membership changes. The roster SHALL include both `casual` and `timed` fishers together rather than segmenting visibility by game mode.

#### Scenario: Join broadcasts an updated roster
- **WHEN** a fisher joins successfully
- **THEN** the system broadcasts a message containing the updated `fishers` list to the connected fishing clients

#### Scenario: Disconnect broadcasts an updated roster
- **WHEN** a connected fisher disconnects or the socket terminates
- **THEN** the system removes that fisher from the in-memory roster
- **THEN** the system broadcasts a message containing the updated `fishers` list to the remaining connected fishing clients

#### Scenario: Casual and timed fishers are visible together
- **WHEN** one connected fisher is in `casual` mode and another connected fisher is in `timed` mode
- **THEN** the system includes both fishers in the shared `fishers` list payload
- **THEN** each fisher's `game` value remains available so clients can render mode-specific visuals

### Requirement: The multiplayer socket uses one shared lobby protocol
The system SHALL use one shared multiplayer lobby for all connected fishers in the first version and SHALL keep roster update messages in a single consistent server-to-client shape so the frontend can update presence state through one path.

#### Scenario: All fishers share one lobby
- **WHEN** multiple fishers connect to the multiplayer socket
- **THEN** the system places them in one shared visible roster rather than splitting them into separate lobbies or mode-specific channels

#### Scenario: Presence updates keep one roster shape
- **WHEN** the server broadcasts a join or disconnect update
- **THEN** the message includes the roster payload in the same `fishers` list shape used by the initial join reply

### Requirement: The multiplayer socket uses Phoenix channels with an origin allowlist
The system SHALL expose the multiplayer socket through the Phoenix channel protocol and SHALL accept cross-site socket connections only from the allowed origins `https://lager.bankasviken.se` and `http://localhost:3000`.

#### Scenario: Allowed origin can connect
- **WHEN** a client served from `https://lager.bankasviken.se` or `http://localhost:3000` opens the multiplayer socket
- **THEN** the system allows the socket connection to proceed

#### Scenario: Disallowed origin is rejected
- **WHEN** a client from any other origin attempts to open the multiplayer socket
- **THEN** the system rejects the socket connection before channel use

### Requirement: Name moderation uses a constrained OpenAI REST request
The system SHALL perform name moderation through a dedicated backend module that calls OpenAI over REST using the existing `Req` client, uses a small fast model, sends a fixed system instruction for acceptable fishing names, treats the candidate username as untrusted input data, and requires the model output to be JSON containing a boolean moderation decision.

#### Scenario: Candidate name is sent as untrusted input
- **WHEN** the backend evaluates a candidate username that contains prompt-injection attempts or instruction-like text
- **THEN** the backend sends that username only as untrusted moderation input rather than merging it into the system instruction
- **THEN** the moderation result still controls whether the join is accepted

#### Scenario: Moderation upstream failure raises an error
- **WHEN** the OpenAI moderation request times out or returns an API error
- **THEN** the backend rejects the join request with `%{reason: "SERVER_ERROR"}`
- **THEN** the backend does not add that fisher to the shared roster

### Requirement: The socket broadcasts only supported emotes
The system SHALL accept fisher emote messages in the shape `{ emote: string }`, rebroadcast only supported emotes, and ignore unsupported emote values.

#### Scenario: Supported emote is broadcast
- **WHEN** a connected fisher sends `{ emote: "wave" }` or another supported emote from the allowlist
- **THEN** the system broadcasts an `emote` payload containing the sender's `fisher_id` and the validated emote name

#### Scenario: Unsupported emote is ignored
- **WHEN** a connected fisher sends an emote outside `wave`, `thumbs_up`, `thumbs_down`, `laugh`, `sad`, and `catch_fish`
- **THEN** the system ignores the message
- **THEN** the system does not broadcast that unsupported emote to any client

### Requirement: Frontend teams receive a socket integration specification
The system SHALL include a `docs/SOCKET_SPEC.md` document for the frontend team that explains how to install and use the Phoenix socket client library and describes the socket path, topic, join payload, join error reasons, and server message shapes.

#### Scenario: Frontend team can implement the socket from documentation
- **WHEN** a frontend developer reads `docs/SOCKET_SPEC.md`
- **THEN** the document includes Phoenix client installation instructions
- **THEN** the document includes an example of connecting to `/fishing/socket` and joining the shared lobby topic
- **THEN** the document documents the join payload, `%{reason: "NAME"}`, `%{reason: "SERVER_ERROR"}`, roster update payloads, and emote payloads

### Requirement: The multiplayer socket does not create persistent user records
The system MUST treat fishing multiplayer connections as anonymous ephemeral sessions and MUST NOT create or update user account records, score records, or other persistent gameplay state.

#### Scenario: Fisher session ends without persistence
- **WHEN** a fisher disconnects from the multiplayer socket
- **THEN** the fisher is removed from in-memory runtime state
- **THEN** no user account or gameplay record is persisted because of that fishing session
