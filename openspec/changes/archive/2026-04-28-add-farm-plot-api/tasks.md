## 1. Controller And Routing

- [x] 1.1 Add authenticated plot action routes under `/api/farms/plots/:plot_number` for clean, seed, water, and harvest.
- [x] 1.2 Add a dedicated plots controller that reuses the request auth helper and dispatches to the existing Farms context actions.
- [x] 1.3 Add JSON rendering that returns the existing updated garden payload shape for all successful plot actions.

## 2. Error Mapping

- [x] 2.1 Map Farms domain action failures to the outline’s `409 Conflict` and `422 Unprocessable Entity` semantics in one controller-level translation path.
- [x] 2.2 Adjust the Farms domain only if needed to make stale/conflict vs validation/rule failures distinguishable.

## 3. Verification

- [x] 3.1 Add endpoint tests for successful clean, seed, water, and harvest actions.
- [x] 3.2 Add endpoint tests for unauthorized requests and for `409` / `422` error mapping cases.
- [x] 3.3 Run `mix precommit` and fix any issues.
