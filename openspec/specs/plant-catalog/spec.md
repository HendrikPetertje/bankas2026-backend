## Requirements

### Requirement: Plant metadata is provided by a hard-coded catalog
The system SHALL provide the plant metadata used by farm validation and harvest logic from a hard-coded Elixir module.

#### Scenario: List the supported plant kinds
- **WHEN** the plant catalog is queried
- **THEN** the system returns metadata for `LETTUCE`, `TOMATO`, `CARROT`, and `PUMPKIN`

#### Scenario: Metadata includes growth time and weight tables
- **WHEN** the plant catalog returns a plant definition
- **THEN** the definition includes `growing_time_s`
- **THEN** the definition includes `weight_g` values for final star ratings `1` through `5`

### Requirement: The Farms context validates and calculates from the plant catalog
The system SHALL use the hard-coded plant catalog for both seed validation and harvest output.

#### Scenario: Reject an unknown plant kind
- **WHEN** the seed action is executed with a plant kind outside the hard-coded catalog
- **THEN** the system rejects the action

#### Scenario: Harvest output comes from the catalog table
- **WHEN** the harvest action completes with a final star rating for a known plant kind
- **THEN** the system reads the produced grams from the corresponding `weight_g` table in the plant catalog
