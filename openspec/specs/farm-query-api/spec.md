## Requirements

### Requirement: Plant info is exposed as a public farm endpoint
The system SHALL provide a public `GET /api/farms/plant-info` endpoint that returns the hard-coded plant metadata.

#### Scenario: Plant info returns the supported plant catalog
- **WHEN** a client sends `GET /api/farms/plant-info`
- **THEN** the system returns a JSON object with a `plants` list
- **THEN** the list includes `LETTUCE`, `TOMATO`, `CARROT`, and `PUMPKIN`
- **THEN** each plant includes `growing_time_s` and `weight_g`

### Requirement: The current authenticated farm can be fetched by API
The system SHALL provide an authenticated `GET /api/farms/me` endpoint that returns the current garden state for the bearer token user.

#### Scenario: Authenticated request returns the current garden
- **WHEN** a client sends `GET /api/farms/me` with a valid bearer token
- **THEN** the system resolves the current user from the token
- **THEN** the system returns the current garden payload as JSON

#### Scenario: Missing token is rejected
- **WHEN** a client sends `GET /api/farms/me` without a bearer token
- **THEN** the system rejects the request with `401 Unauthorized`

#### Scenario: Invalid token is rejected
- **WHEN** a client sends `GET /api/farms/me` with an invalid bearer token
- **THEN** the system rejects the request with `401 Unauthorized`

### Requirement: Farm query endpoints use the existing farm response shape
The system SHALL return the same garden response shape already used by the auth API.

#### Scenario: The farm response shape is consistent
- **WHEN** the system returns the garden payload from `GET /api/farms/me`
- **THEN** the response includes `user_name`, `produced_g`, and `plots`
- **THEN** the response does not include `pincode_hash`
