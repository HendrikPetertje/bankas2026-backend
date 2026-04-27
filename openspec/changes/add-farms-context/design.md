## Context

The shared account system is in place, and the project outline already defines the persistent farm model and game rules. What is still missing is the Farms domain itself: the code that owns gardens, plots, plant metadata, plot transitions, and the serialized farm state returned to other layers.

This change needs to establish the Farms context before the user auth API can finish sign-up provisioning or return a current garden snapshot. It also needs to encode the game rules in one place so later controllers do not duplicate timing, validation, or harvest logic.

## Goals / Non-Goals

**Goals:**

- Add `Garden` and `GardenPlot` schemas backed by the database model described in the outline.
- Add context functions to create a farm for a user and load the current farm for a given user ID.
- Return farm state with `user_name` resolved from the associated account while persisting only `user_id`.
- Add context-level plot action functions for clean, seed, water, and harvest.
- Implement the shared pre-action penalty hook used before every non-seed plot action.
- Add a hard-coded plant metadata module used for validation and harvest output.

**Non-Goals:**

- Add HTTP routes or controllers for farm endpoints.
- Add auth plugs or bearer-token request handling.
- Implement browser or client-side state behavior.
- Add plant metadata to the database.

## Decisions

### Keep all farm game rules inside the `Farms` context

The `Farms` context should own both persistence and the game transitions for gardens and plots. Controllers should call context functions rather than manipulate schemas directly. This keeps the rules reusable for the future auth API, farm API, CLI work, or tests.

Alternatives considered:

- Put plot logic in controllers: rejected because the rules would be duplicated and harder to test.
- Split every plot action into its own module immediately: rejected because the first implementation is still small enough to keep inside the context plus schemas.

### Persist `user_id` but render `user_name`

The garden table should reference the owning account by `user_id`, not by a copied username. When the context returns a farm to higher layers, it should preload the associated user and expose `user_name` in the serialized shape expected by the outline.

Alternatives considered:

- Persist `user_name` on the garden: rejected because usernames can change and the outline now explicitly uses `user_id` in storage.

### Create all 9 plots transactionally with the garden

Farm creation should create the garden and its 9 numbered plots in one transaction. This prevents partial state where a garden exists without its complete plot set.

Alternatives considered:

- Create plots lazily on first access: rejected because the outline requires exactly 9 plots for every garden.

### Represent plant metadata in a dedicated hard-coded module

Plant metadata should live in a dedicated Elixir module that returns the allowed plant kinds, growth times, and weight tables. The Farms context should use it both to validate `plant_kind` and to determine harvest output.

Alternatives considered:

- Store plant data in the database: rejected because the outline explicitly says it should be hard coded.

### Apply penalty logic through one shared pre-action function

Every non-seed plot action shares the same pre-action penalty rules. The context should run one shared function before clean, water, and harvest. That function should only affect seeded plots, should respect the 30 minute cooldown via `last_penalty_at`, and should update stars in a controlled way.

Alternatives considered:

- Recompute penalties separately inside each action: rejected because it would duplicate logic and invite drift.

### Treat plot actions as transactional state transitions

Each plot action should load the garden and target plot, apply the pre-hook if required, validate the transition, persist the resulting state, and then return the full updated farm shape. Harvest should also update the garden total in the same transaction.

Alternatives considered:

- Save the plot first and the garden later during harvest: rejected because the produced total and plot reset must stay in sync.

## Risks / Trade-offs

- The Farms context will contain both persistence and game logic -> mitigate by keeping the public API small and testing each action directly.
- Time-based rules can be brittle in tests -> mitigate by centralizing current-time access and using explicit timestamps in test setup.
- Returning `user_name` from a `user_id`-backed garden requires preloading the account -> mitigate by using dedicated queries for farm loading rather than ad hoc Repo calls.
- The pre-action hook affects multiple actions -> mitigate by testing each action path plus the cooldown behavior around `last_penalty_at`.

## Migration Plan

1. Add migrations for `farms_gardens` and `farms_garden_plots` with UUID keys and the required constraints.
2. Add the `Garden` and `GardenPlot` schemas with associations.
3. Add the hard-coded plant metadata module.
4. Implement farm creation and farm loading by user ID.
5. Implement plot actions and the shared pre-action penalty hook.
6. Add tests for provisioning, farm loading, action transitions, and harvest calculations.

Rollback strategy:

- Revert the Farms modules and tests.
- Roll back the garden and garden-plot migrations if applied.

## Open Questions

- None. The outline already defines the data model, the plot states, the allowed plant kinds, and the penalty rules for this context change.
