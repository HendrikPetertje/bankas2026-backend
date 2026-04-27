## Requirements

### Requirement: A farm can be created for a user with a complete initial plot set
The system SHALL provide a Farms context function that creates a garden for a given user and provisions exactly 9 plots.

#### Scenario: Create a farm for a user
- **WHEN** the Farms context creates a farm for a valid user ID
- **THEN** the system creates one garden for that user
- **THEN** the system creates exactly 9 plots numbered `1` through `9`
- **THEN** every new plot starts in the `BARREN` state
- **THEN** every new plot starts with `last_watered_at` set to `null`

### Requirement: A farm can be loaded by user ID in response shape form
The system SHALL provide a Farms context function that returns the current farm for a given user ID using the response shape required by the outline.

#### Scenario: Load a farm by user ID
- **WHEN** the Farms context loads a farm for a user ID that has a garden
- **THEN** the system returns the garden with `produced_g` and `plots`
- **THEN** the returned garden includes `user_name` resolved from the associated account
- **THEN** the returned garden does not expose `user_id` as the response field name

### Requirement: Plot actions are executed through Farms context functions
The system SHALL provide context-level functions for clean, seed, water, and harvest plot actions.

#### Scenario: Clean a barren plot
- **WHEN** the clean action is executed for a `BARREN` plot
- **THEN** the plot state changes to `CLEANED`
- **THEN** `last_weeds_removed_at` is updated to the current time

#### Scenario: Clean a seeded plot removes weeds
- **WHEN** the clean action is executed for a `SEEDED` plot
- **THEN** the plot remains planted
- **THEN** `last_weeds_removed_at` is updated to the current time

#### Scenario: Seed a cleaned plot
- **WHEN** the seed action is executed for a `CLEANED` plot with a valid plant kind and a `last_watered_at` value within the last 30 minutes
- **THEN** the plot state changes to `SEEDED`
- **THEN** the system stores the chosen `plant_kind`
- **THEN** the system sets `planted_at` to the current time
- **THEN** the system sets `water_stars` and `weed_stars` to `5`

#### Scenario: Water a plot
- **WHEN** the water action is executed for any plot state
- **THEN** the system updates `last_watered_at` to the current time

#### Scenario: Harvest a mature plot
- **WHEN** the harvest action is executed for a `SEEDED` plot whose growth time has been reached
- **THEN** the system applies the pre-action penalty hook first
- **THEN** the system calculates harvest output from the plant catalog using `min(water_stars, weed_stars)`
- **THEN** the system adds the produced grams to the garden total
- **THEN** the system resets the plot to `BARREN`

### Requirement: Invalid plot transitions are rejected
The system SHALL reject plot actions that violate the game rules.

#### Scenario: Reject seeding without recent watering
- **WHEN** the seed action is executed for a plot whose `last_watered_at` is missing or older than 30 minutes
- **THEN** the system rejects the action

#### Scenario: Reject harvesting before maturity
- **WHEN** the harvest action is executed for a `SEEDED` plot before the configured growth time has elapsed
- **THEN** the system rejects the action

#### Scenario: Reject an action for an incompatible plot state
- **WHEN** a plot action is executed for a state where that action is not allowed
- **THEN** the system rejects the action

### Requirement: The pre-action penalty hook runs before non-seed actions
The system SHALL apply the shared penalty hook before every non-seed plot action.

#### Scenario: Non-seed action applies water and weed penalties to seeded plots
- **WHEN** a non-seed action targets a seeded plot whose timing thresholds have been exceeded
- **THEN** the system updates `water_stars` and `weed_stars` according to the penalty rules
- **THEN** the system never reduces a star value below `1`

#### Scenario: Penalty hook respects the cooldown window
- **WHEN** a non-seed action targets a seeded plot whose `last_penalty_at` is less than 30 minutes ago
- **THEN** the system does not apply new penalties yet

#### Scenario: Non-seed actions ignore penalties for non-seeded plots
- **WHEN** a non-seed action targets a plot that is not `SEEDED`
- **THEN** the penalty hook makes no star changes
