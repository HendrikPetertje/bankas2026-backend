## 1. Fishing domain and runtime state

- [ ] 1.1 Create the `Fishing`, `Fishing.Fisher`, and `Fishing.NameCheck` modules to validate fisher payloads, trim names, enforce the 10-character name limit, supported game values, and encapsulate OpenAI-backed name moderation.
- [ ] 1.2 Add a supervised in-memory process for connected fishers that can register joins, remove disconnects, and return the normalized fisher roster.
- [ ] 1.3 Expose context functions for join, leave, roster lookup, validated name-check gating, and validated emote broadcasting payload construction.

## 2. Socket transport and channel behavior

- [ ] 2.1 Add a dedicated Phoenix socket endpoint at `/fishing/socket`, wire it into the endpoint configuration, and restrict `check_origin` to `https://lager.bankasviken.se` and `http://localhost:3000`.
- [ ] 2.2 Implement the fishing channel join flow so valid payloads pass OpenAI-backed name moderation, approved payloads receive `current_fisher_id` plus the current `fishers` list, rejected names return `%{reason: "NAME"}`, and moderation API failures return `%{reason: "SERVER_ERROR"}`.
- [ ] 2.3 Broadcast updated `fishers` lists on successful joins and disconnects, keeping `casual` and `timed` fishers in one shared roster.
- [ ] 2.4 Handle `{ emote: string }` messages by rebroadcasting only supported emotes and ignoring unsupported values.

## 3. Verification and integration confidence

- [ ] 3.1 Add channel and context tests for valid joins, invalid joins, moderated name rejection, generated fisher IDs, shared visibility across `casual` and `timed` fishers, allowed-origin socket access assumptions, and roster updates on disconnect.
- [ ] 3.2 Add tests for supported emotes, unsupported emotes, the OpenAI name-check integration boundary, prompt-injection-style usernames being treated as untrusted moderation input, boolean JSON parsing, and upstream API failure handling.
- [ ] 3.3 Add `docs/SOCKET_SPEC.md` documenting Phoenix client installation, socket connection setup, lobby join flow, join error reasons, and roster / emote message shapes for the frontend team.
- [ ] 3.4 Run `mix precommit` and fix any issues before considering the change complete.
