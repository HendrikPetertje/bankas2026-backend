## Requirements

### Requirement: Plot actions are exposed as authenticated farm endpoints
The system SHALL provide authenticated HTTP endpoints for clean, seed, water, and harvest under `/api/farms/plots/:plot_number`.

#### Scenario: Clean endpoint returns the updated garden
- **WHEN** a client sends an authenticated `POST /api/farms/plots/:plot_number/clean` request
- **THEN** the system executes the clean action through the Farms context
- **THEN** the system returns the full updated garden payload as JSON

#### Scenario: Seed endpoint returns the updated garden
- **WHEN** a client sends an authenticated `POST /api/farms/plots/:plot_number/seed` request with `plant_kind`
- **THEN** the system executes the seed action through the Farms context
- **THEN** the system returns the full updated garden payload as JSON

#### Scenario: Water endpoint returns the updated garden
- **WHEN** a client sends an authenticated `POST /api/farms/plots/:plot_number/water` request
- **THEN** the system executes the water action through the Farms context
- **THEN** the system returns the full updated garden payload as JSON

#### Scenario: Harvest endpoint returns the updated garden
- **WHEN** a client sends an authenticated `POST /api/farms/plots/:plot_number/harvest` request
- **THEN** the system executes the harvest action through the Farms context
- **THEN** the system returns the full updated garden payload as JSON

### Requirement: Plot action endpoints require authenticated requests
The system SHALL require a valid bearer token for all plot action endpoints.

#### Scenario: Missing token is rejected
- **WHEN** a client sends a plot action request without a valid bearer token
- **THEN** the system rejects the request with `401 Unauthorized`

#### Scenario: Invalid token is rejected
- **WHEN** a client sends a plot action request with an invalid bearer token
- **THEN** the system rejects the request with `401 Unauthorized`

### Requirement: Plot action errors use the defined HTTP semantics
The system SHALL translate domain action failures into the HTTP semantics defined by the project outline.

#### Scenario: Stale or impossible state transitions return conflict
- **WHEN** a plot action request targets a plot state where that action is not allowed
- **THEN** the system rejects the request with `409 Conflict`

#### Scenario: Rule or validation failures return unprocessable entity
- **WHEN** a plot action request fails a game rule such as missing recent watering, unknown plant kind, or harvesting before maturity
- **THEN** the system rejects the request with `422 Unprocessable Entity`

### Requirement: Plot action responses use the existing farm payload shape
The system SHALL return the same garden response shape already used by the auth and query APIs.

#### Scenario: Action responses omit password material
- **WHEN** the system returns the garden payload from any plot action endpoint
- **THEN** the response includes `user_name`, `produced_g`, and `plots`
- **THEN** the response does not include `pincode_hash`
