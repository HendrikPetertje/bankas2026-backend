## Context

The project now has the shared account system, JWT support, the user auth API, and the Farms domain. What is missing is the read-only farm HTTP layer: the public plant metadata endpoint and the authenticated endpoint that returns the current user’s garden state.

This is also the right point to add a reusable request auth helper at the web layer. The helper should validate bearer tokens, load the current user, and return `401 Unauthorized` on failure. That same behavior will be needed again when the plot action endpoints are added.

## Goals / Non-Goals

**Goals:**

- Add `GET /api/farms/plant-info` as a public endpoint backed by the hard-coded plant catalog.
- Add `GET /api/farms/me` as an authenticated endpoint backed by the Farms context.
- Add a reusable request auth helper that protected farm controllers can share.
- Return the existing farm response shape from `/api/farms/me`.

**Non-Goals:**

- Implement plot action endpoints.
- Add a general authorization policy engine.
- Change JWT structure or account behavior.
- Duplicate farm or plant catalog logic in controllers.

## Decisions

### Add a dedicated Farms controller for read-only endpoints

The read-only farm endpoints should live in a Farms-focused controller under `/api/farms`. This keeps them separate from the users auth controller and aligns the API structure with the outline.

Alternatives considered:

- Put plant info into a generic metadata controller: rejected because the endpoint is farm-specific.

### Use a reusable controller helper or plug for authenticated farm requests

The `/api/farms/me` endpoint and the future plot endpoints all need the same request authentication behavior. A reusable plug or controller helper should validate the bearer token, resolve the current user with `Accounts.get_user_from_jwt/1`, assign the user to the connection, and halt with `401` when authentication fails.

Alternatives considered:

- Call `Accounts.get_user_from_jwt/1` inline in every action: rejected because it would duplicate error handling and assignment behavior.

### Keep controllers thin and delegate to existing domain modules

The plant info endpoint should call the plant catalog. The authenticated farm endpoint should call the Farms context. Controllers should only handle request parsing, auth integration, and HTTP response rendering.

Alternatives considered:

- Build response data manually inside controllers: rejected because the domain modules already own the state and serialization shape.

### Reuse the existing farm payload shape directly

`GET /api/farms/me` should return the same `garden` shape already used by the user auth API. This avoids inventing a second representation of the same domain object.

Alternatives considered:

- Return a flattened farm object for `/api/farms/me`: rejected because it would diverge from the outline and the auth API.

## Risks / Trade-offs

- A controller auth helper can become too farm-specific -> mitigate by keeping it focused on bearer token validation and current-user assignment only.
- Public and authenticated endpoints will coexist in the same controller namespace -> mitigate by applying auth only where required, not globally.
- Farm response rendering could drift from the auth API shape -> mitigate by centralizing JSON rendering around the existing response contract.

## Migration Plan

1. Add the reusable request auth helper.
2. Add farm routes for `plant-info` and `me`.
3. Add the Farms controller and JSON rendering.
4. Add endpoint tests for public plant info, authenticated `me`, and auth failure behavior.

Rollback strategy:

- Revert the routes, controller, helper, and tests.
- No schema rollback is required.

## Open Questions

- None. The endpoint behavior and auth requirements are already defined by the outline.
