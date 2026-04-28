## Why

The domain and auth layers are now in place, but the farm API still has no read-only HTTP endpoints for clients to fetch plant metadata or the current authenticated garden. The next step is to expose those endpoints and introduce a reusable request auth helper that future farm controllers can share.

## What Changes

- Add a public `GET /api/farms/plant-info` endpoint backed by the plant catalog.
- Add an authenticated `GET /api/farms/me` endpoint that returns the current garden state.
- Add a reusable web-layer helper or plug that validates the bearer token, loads the current user, and returns `401 Unauthorized` when authentication fails.
- Reuse the shared farm response shape for the read-only farm endpoint.

## Capabilities

### New Capabilities
- `farm-query-api`: Read-only farm API endpoints for plant info and the current authenticated garden.
- `request-auth-helper`: Reusable request authentication helper for protected game controllers.

### Modified Capabilities

None.

## Impact

- Affected code: router, farm controller, JSON rendering, auth helper modules, and endpoint tests.
- Affected APIs: introduces `GET /api/farms/plant-info` and `GET /api/farms/me`.
- Systems: connects the web layer to the existing Accounts JWT resolution and Farms context.
- Future work: the auth helper will also support upcoming plot action endpoints.
