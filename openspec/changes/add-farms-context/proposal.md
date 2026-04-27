## Why

The project outline already defines a full garden and plot game model, but the codebase does not yet have a Farms domain that can persist farms, load a farm for a user, or execute plot actions. This context needs to exist before the user auth API can provision the initial garden state or return the current farm payload.

## What Changes

- Add a new `Farms` context centered on `Garden` and `GardenPlot`.
- Persist gardens by `user_id` and expose farm responses with `user_name` resolved from the associated account.
- Add context functions to create a farm for a user and fetch the farm for a given user ID.
- Add context-level plot action functions for clean, seed, water, and harvest.
- Implement the shared plot pre-action hook that applies time-based penalties before non-seed actions.
- Add a hard-coded plant metadata module used for validation and harvest output calculations.

## Capabilities

### New Capabilities
- `farms-context`: Garden and plot persistence, loading, serialization, and game actions.
- `plant-catalog`: Hard-coded plant metadata used by farm validation and harvest logic.

### Modified Capabilities

None.

## Impact

- Affected code: new Farms schemas, context functions, migrations, and tests.
- Affected systems: the future user auth API depends on this change to create and load garden state.
- Data model: introduces the `farms_gardens` and `farms_garden_plots` tables with UUID keys and per-plot state.
- Domain behavior: centralizes plot actions and penalty rules in the backend instead of leaving them to controllers or the frontend.
