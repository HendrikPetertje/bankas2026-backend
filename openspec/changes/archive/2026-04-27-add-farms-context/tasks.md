## 1. Persistence Layer

- [x] 1.1 Add migrations for `farms_gardens` and `farms_garden_plots` with UUID primary keys, associations, and core constraints.
- [x] 1.2 Add the `Garden` and `GardenPlot` schemas with associations, field validations, and plot numbering support.

## 2. Domain Foundations

- [x] 2.1 Add the hard-coded plant metadata module with the allowed kinds, growth times, and harvest weight tables.
- [x] 2.2 Implement Farms context functions to create a farm for a user and provision exactly 9 initial plots transactionally.
- [x] 2.3 Implement Farms context queries that load a farm by user ID and return the response shape with `user_name` resolved from the associated account.

## 3. Plot Actions

- [x] 3.1 Implement the shared pre-action penalty hook for non-seed plot actions, including the 30 minute cooldown and minimum-star behavior.
- [x] 3.2 Implement clean, seed, water, and harvest context functions with the required state-transition validation.
- [x] 3.3 Implement harvest calculations that use the plant catalog and update the garden total plus plot reset in one transaction.

## 4. Verification

- [x] 4.1 Add tests for farm creation, farm loading, and resolved `user_name` response shaping.
- [x] 4.2 Add tests for plot action success paths, invalid state transitions, penalty timing, and harvest output.
- [x] 4.3 Run `mix precommit` and fix any issues.
