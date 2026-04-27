## Why

The project outline defines a shared account system that authenticated games can reuse, but the codebase does not yet have a dedicated `Accounts.User` data layer or JWT support. This change establishes the core account primitives now so the farming API can sign up users, authenticate logins, and resolve the current user from bearer tokens.

## What Changes

- Add a new `Accounts.User` context and schema backed by the database.
- Persist users with UUID primary keys, case-insensitive unique usernames, bcrypt PIN hashes, and failed-login tracking fields.
- Add public support functions for `create_user`, `update_user`, `authenticate_user`, and `get_user_from_jwt`.
- Add an `Accounts.JWT` library module responsible for creating and validating signed JWT tokens with Joken.
- Load the JWT signing secret from environment configuration and document it in `.env_example`.
- Prepare the data and auth layer so future authenticated games can reuse the same account system.

## Capabilities

### New Capabilities
- `shared-user-accounts`: Shared account persistence and authentication functions for authenticated games.
- `jwt-authentication`: Signed JWT creation and validation for API authentication.

### Modified Capabilities

None.

## Impact

- Affected code: new `Accounts` context modules, user schema, migrations, and auth support code.
- Affected APIs: future auth endpoints will depend on these functions, but this change only establishes the data and token layer.
- Dependencies: uses existing `bcrypt` and `joken` integration patterns; no new external auth system is introduced.
- Configuration: adds a required JWT secret in environment-driven runtime configuration, a local `.env` workflow, and `.env_example` documentation.
