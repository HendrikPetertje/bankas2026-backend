## Context

The project now has a product outline for a shared account system, but the application still only contains the generated Phoenix defaults plus an unfinished farms context. The first implementation step is to establish a reusable account data layer that can create users, update usernames and PINs, verify a six-digit PIN, and resolve the current user from a signed JWT.

This change crosses several parts of the system:

- database schema and migrations
- Ecto schemas and context functions
- password hashing
- JWT signing and verification
- runtime configuration and local developer secrets

The codebase already depends on `joken`, but it does not yet have a JWT wrapper module, user persistence, or environment-backed JWT secret configuration. It also does not currently ignore `.env` files in git.

## Goals / Non-Goals

**Goals:**

- Introduce a shared `Accounts` context with a `User` schema.
- Persist users with UUID primary keys and case-insensitive unique usernames.
- Provide `create_user/1`, `update_user/2`, `authenticate_user/2`, and `get_user_from_jwt/1` as the initial public API for account access.
- Encapsulate JWT token creation and validation inside `Accounts.JWT`.
- Load the JWT signing secret from environment configuration and document local setup with `.env_example`.
- Establish the failed-login tracking fields needed by later login throttling work.

**Non-Goals:**

- Implement HTTP controllers, plugs, or routes for sign-up and login.
- Implement game-specific authorization for farms endpoints.
- Implement the full lockout policy behavior beyond storing the required fields and supporting the authentication flow.
- Build refresh tokens, token expiry, or token revocation.

## Decisions

### Use a dedicated `Accounts` context with `Accounts.User`

The change will create a new top-level `Accounts` context instead of attaching user auth to `Farms`. The account system is shared infrastructure and should stay independent from any single game domain.

Alternatives considered:

- Put auth inside `Farms`: rejected because the outline explicitly calls for reuse across other games.
- Store auth logic directly in controllers later: rejected because the core behavior needs a reusable domain API first.

### Use UUID primary keys for users

`Accounts.User` will use UUID primary keys to match the outline and keep identifiers opaque to clients. This also aligns with the future garden and plot design.

Alternatives considered:

- Integer IDs: rejected because the outline already standardizes on UUIDs.

### Persist a normalized username and enforce case-insensitive uniqueness in the database

Authentication needs case-insensitive usernames. The design should normalize usernames before persistence and compare against a normalized value during login. The migration should enforce uniqueness at the database level so duplicates cannot be created by concurrent requests.

The cleanest implementation is to store usernames in a normalized form, such as lowercase, and create a unique index on that stored value.

Alternatives considered:

- Preserve original casing and use a functional unique index on `lower(username)`: viable, but it adds more query and serialization decisions without a stated product need for display-case preservation.
- Enforce uniqueness only in changesets: rejected because that is race-prone.

### Use `bcrypt_elixir` for PIN hashing

The outline requires bcrypt. The implementation should add `bcrypt_elixir` as a dependency and expose no raw PIN comparison logic outside the context. `create_user/1` will hash the provided six-digit PIN before insert. `authenticate_user/2` will verify the PIN against the stored hash.

Alternatives considered:

- Plain hashing with `:crypto`: rejected because password hashing requires a slow adaptive algorithm.
- Argon2: rejected because the requirement explicitly says bcrypt.

### Support user maintenance through `update_user/2`

The shared account layer should also support admin-driven maintenance of usernames and PINs. This change will expose `update_user/2` so later CLI tooling can update account credentials without duplicating validation or hashing logic elsewhere.

`update_user/2` should reuse the same normalization and validation rules as account creation:

- usernames stay case-insensitive and unique
- PINs remain exactly 6 numeric characters when present
- updated PINs are re-hashed with bcrypt before persistence

Alternatives considered:

- Add update behavior later when the CLI is built: rejected because the CLI should call stable domain functions rather than introduce account mutation rules itself.
- Expose separate username and PIN update functions: rejected because a standard changeset-based update API is simpler and more reusable.

### Keep JWT concerns in `Accounts.JWT`

JWT creation and validation should live in a focused `Accounts.JWT` module rather than be spread across the context. This keeps token concerns separate from user persistence and makes the auth layer easier to reuse from future plugs and controllers.

`Accounts.JWT` should expose:

- token generation for a user
- token validation
- claim extraction helpers as needed by `Accounts.get_user_from_jwt/1`

The token payload should include `iat`, `username`, and a stable subject claim such as `sub` with the user UUID so user resolution does not depend on a mutable field.

Alternatives considered:

- Create tokens directly in `Accounts`: rejected because signing and validation are cross-cutting concerns.
- Store only `username` in the token: rejected because usernames can change in future revisions even if the first version does not support it.

### Load JWT secret from runtime environment

The JWT signing secret should be configured in `runtime.exs` from an environment variable so the same mechanism works in development, test, and production. For local development, the repository should support a `.env` file that is git ignored, with `.env_example` documenting the required variable. Later deployment can inject the same variable through Docker Compose.

Alternatives considered:

- Hardcode the secret in config: rejected for obvious security reasons.
- Store the secret only in `dev.exs`: rejected because the token layer must work across environments.

### Have `get_user_from_jwt/1` validate first, then fetch by subject claim

The public function should accept a raw bearer token string, validate it through `Accounts.JWT`, extract the stable user identifier, and fetch the user from the database. This keeps caller code simple and centralizes token parsing in one place.

Alternatives considered:

- Return claims only and let callers fetch users: rejected because the requested API explicitly asks for `get_user_from_jwt`.

## Risks / Trade-offs

- Local `.env` handling must match the eventual container environment variable name -> use one variable name across `.env`, runtime config, and later Docker Compose injection.
- Lowercasing usernames loses original user-entered casing -> acceptable for now because display-preserving usernames are not part of the outlined requirements.
- Tokens have no expiry -> acceptable because the outline explicitly requests non-expiring JWTs, but later changes may need revocation or rotation.
- Adding bcrypt increases auth cost per login -> acceptable and intentional because PIN hashing must be slow enough to resist brute force.
- `get_user_from_jwt/1` depends on database availability after token validation -> acceptable because authenticated requests need a current persisted user record.

## Migration Plan

1. Add the password hashing dependency.
2. Generate and edit the `accounts_users` migration with UUID primary key, normalized username, PIN hash, and failed-login tracking fields.
3. Add runtime JWT secret configuration and local `.env_example` documentation.
4. Update `.gitignore` to exclude `.env`.
5. Implement the `Accounts.User`, `Accounts`, and `Accounts.JWT` modules.
6. Add tests for user creation, username uniqueness, user updates, PIN verification, JWT round-trips, and invalid token handling.

Rollback strategy:

- Revert the code change.
- Roll back the user table migration if it has been applied.
- Remove the runtime configuration requirement if the auth layer is being backed out entirely.

## Open Questions

- Whether this change should also include local `.env` loading support in application startup, or only document the `.env` contract for the current workflow.
