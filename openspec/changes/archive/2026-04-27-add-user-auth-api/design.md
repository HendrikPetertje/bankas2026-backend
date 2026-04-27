## Context

The shared `Accounts` domain, JWT support, and Farms context now exist, but there is still no public HTTP surface for clients to create accounts or log in. The farming SPA needs those endpoints first so it can obtain tokens and bootstrap the initial game state. The outline also requires browser access from the production SPA origin and the local React development server.

This change crosses several application layers:

- Phoenix router and API pipeline
- controller and JSON response modules
- account authentication flow and failed-login tracking
- farms provisioning and garden serialization
- cross-origin request handling, including preflight `OPTIONS` requests

The account layer already stores `failed_login_attempts` and `last_failed_login_attempt_at`, but it does not yet implement the 5-attempt lockout window described in the outline. This change will make that behavior observable through the login endpoint.

## Goals / Non-Goals

**Goals:**

- Add `POST /api/users/sign-up` and `POST /api/users/login` as public JSON endpoints.
- Return a signed JWT plus the full garden payload on both sign-up and login.
- Provision a garden and 9 empty plots as part of sign-up.
- Enforce the 5 failed-attempt, 10 minute lockout behavior during login.
- Allow cross-origin API requests from `https://lager.bankasviken` and `http://localhost:3000`.
- Support browser preflight requests for the allowed origins and API methods.

**Non-Goals:**

- Implement authenticated farm action endpoints beyond what is needed to return the garden snapshot.
- Build a general browser auth plug for all protected routes.
- Add third-party CORS dependencies if a small in-app plug is sufficient.
- Change JWT claims or token format beyond using the existing shared token support.

## Decisions

### Add a dedicated public users controller under the API scope

The API should expose a dedicated controller for `sign-up` and `login` under `/api/users`, not under `/api/farms`. The account system is shared infrastructure, and the updated outline explicitly moved auth endpoints into the shared namespace.

Alternatives considered:

- Keep auth inside a farms controller: rejected because it couples a shared account concern to one game namespace.

### Keep sign-up orchestration in application code, not in callbacks

Sign-up will span multiple domains: create the user, call the Farms context to provision the initial farm, create a token, and render the response. That orchestration should live in an application-facing function or controller-facing service flow backed by a transaction, rather than hidden inside schema callbacks.

Alternatives considered:

- Use Ecto callbacks or side effects in `Accounts.create_user/1`: rejected because farm provisioning belongs to a higher-level flow, not the account schema.
- Reimplement garden and plot creation inside the auth controller: rejected because the Farms context already owns that behavior.

### Implement login lockout inside the shared account domain

The login endpoint needs the lockout rules, but the behavior belongs in the shared account layer so future games get the same semantics. `authenticate_user/2` should evolve from raw credential checking into a function that also tracks failed attempts, resets counters on success, and returns a distinct lockout error when the 10 minute window is active.

Alternatives considered:

- Count failed attempts in the controller only: rejected because the behavior would not be reusable.
- Add a separate lockout service: rejected because the existing account record already has the required state.

### Use a small custom CORS plug instead of adding a dependency

The CORS policy is narrow: two origins, API routes only, and standard browser methods and headers. A small plug in the endpoint or API pipeline is enough to set the response headers and answer preflight requests without bringing in another dependency.

Alternatives considered:

- Add a CORS library dependency: viable, but unnecessary for such a small rule set.
- Handle CORS inside each controller: rejected because the policy should live at the boundary, not per action.

### Return the same garden shape from sign-up and login

Both endpoints should return `{token, garden}` using the same garden serializer that the farm API will later reuse. That keeps the SPA bootstrap path simple and avoids introducing two representations of the same resource.

Alternatives considered:

- Return token only on login: rejected because the outline already defines `{token, garden}` for both endpoints.

## Risks / Trade-offs

- Login logic now mutates account state on both success and failure -> mitigate by keeping the behavior transactional and testing lockout transitions directly.
- Sign-up spans Accounts and Farms -> mitigate by using one transaction so partial user creation cannot leave orphaned records.
- Custom CORS logic can drift from browser expectations -> mitigate by covering `OPTIONS` responses and allowed origin behavior with controller or plug tests.
- Returning the full garden payload from login increases response size -> acceptable because the SPA needs the current game state immediately after auth.

## Migration Plan

1. Extend the shared account logic to support failed-attempt tracking and lockout decisions.
2. Add the users API routes, controller, and JSON rendering.
3. Add the sign-up transaction that creates the user and calls the Farms context to provision the initial farm.
4. Add CORS handling for the approved SPA origins and preflight requests.
5. Add tests for sign-up, login, lockout behavior, and CORS responses.

Rollback strategy:

- Revert the routes, controller, and plug changes.
- Revert the account lockout behavior if needed.
- No schema rollback is required unless a later implementation adds new fields beyond the existing account table.

## Open Questions

- None. The endpoint paths, response shape, lockout policy, and allowed origins are all specified.
