## Why

The Farms domain and authenticated farm query endpoints now exist, but the farming game still cannot mutate plot state through HTTP. The last major gap is the plots controller layer that exposes clean, seed, water, and harvest as authenticated API endpoints with the correct response and error semantics.

## What Changes

- Add authenticated plot action endpoints under `/api/farms/plots/:plot_number/...`.
- Reuse the existing request auth helper to resolve the current user for plot actions.
- Call the existing Farms context action functions for clean, seed, water, and harvest.
- Return the full updated garden state after every successful plot action.
- Map domain-level action errors to the HTTP semantics defined in the project outline, especially `409` and `422`.

## Capabilities

### New Capabilities
- `farm-plot-api`: Authenticated HTTP endpoints for plot actions and farm-action error mapping.

### Modified Capabilities

None.

## Impact

- Affected code: router, plots controller, JSON rendering, and endpoint tests.
- Affected APIs: introduces `POST /api/farms/plots/:plot_number/clean`, `seed`, `water`, and `harvest`.
- Systems: connects the existing request auth helper to the Farms domain action functions.
- Client behavior: enables the SPA to mutate farm state through the backend instead of local logic.
