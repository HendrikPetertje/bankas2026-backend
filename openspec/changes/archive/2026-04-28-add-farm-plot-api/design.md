## Context

The project now has the Farms domain, the request auth helper, and the read-only farm endpoints. What remains is the HTTP layer for plot mutations: the authenticated controller endpoints that let the client clean, seed, water, and harvest plots through the backend.

The Farms context already owns the game rules, state transitions, penalty hook, and harvest calculations. This change is therefore about exposing those actions safely and consistently through HTTP, not about inventing new domain logic.

## Goals / Non-Goals

**Goals:**

- Add authenticated plot action endpoints under `/api/farms/plots/:plot_number/...`.
- Reuse the existing request auth helper for all plot actions.
- Reuse the existing Farms context action functions for state changes.
- Return the full updated garden state after every successful action.
- Map domain action failures to the outline’s `401`, `409`, and `422` semantics.

**Non-Goals:**

- Change the Farms domain rules themselves unless implementation reveals a mismatch.
- Add new JWT behavior or user auth flows.
- Add browser-specific client logic.
- Add new database tables or fields unless implementation discovers a true gap.

## Decisions

### Add a dedicated plots controller under the farms API namespace

Plot mutations should live in a dedicated controller under `/api/farms/plots`, separate from the read-only farms controller. This keeps read and write concerns distinct and matches the plural route structure in the outline.

Alternatives considered:

- Put actions into the existing Farms controller: rejected because the mutation surface is larger and easier to maintain in its own controller.

### Reuse the request auth helper rather than re-validating tokens inline

All plot endpoints require the same authenticated current user as `GET /api/farms/me`. The existing auth helper should assign `current_user` and halt invalid requests before controller action logic runs.

Alternatives considered:

- Call `Accounts.get_user_from_jwt/1` directly in every action: rejected because it duplicates request-level auth behavior.

### Keep controller actions as thin adapters over the Farms context

The controller should translate route params and request bodies into calls like `Farms.clean_plot/2` or `Farms.seed_plot/3`, then convert returned domain errors into HTTP statuses. The controller should not repeat validation or game rules already owned by the context.

Alternatives considered:

- Re-validate plot transitions in the controller: rejected because the domain already owns that logic.

### Map domain errors into HTTP semantics explicitly

The outline distinguishes between `409 Conflict` for stale or impossible transitions and `422 Unprocessable Entity` for rule or validation failures. The controller should codify this mapping centrally so all plot actions behave consistently.

Likely examples:

- `401` for missing or invalid auth, handled by the auth helper
- `409` for incompatible plot states or stale transitions
- `422` for invalid plant kind, missing recent watering, or harvesting before maturity

Alternatives considered:

- Treat every domain error as `422`: rejected because the outline explicitly distinguishes stale/conflict cases.

## Risks / Trade-offs

- The current Farms domain error atoms may not map cleanly to HTTP semantics -> mitigate by keeping a single controller mapping function and adjusting the domain only if a real ambiguity appears.
- Plot endpoints all return the full garden state, not just the updated plot -> acceptable because the outline requires that shape and it keeps the client simple.
- The controller layer depends on route param parsing for `plot_number` -> mitigate by normalizing and validating the param once before dispatch.

## Migration Plan

1. Add the plots controller and routes.
2. Reuse the existing request auth helper on all plot endpoints.
3. Add JSON rendering that returns the existing garden payload shape.
4. Add endpoint tests for each action plus auth and error mapping.

Rollback strategy:

- Revert the plots controller, routes, rendering, and endpoint tests.
- No schema rollback is required.

## Open Questions

- None. The route structure, auth requirement, and success response shape are already defined.
