## ADDED Requirements

### Requirement: Protected farm controllers can reuse bearer token authentication
The system SHALL provide a reusable request authentication helper for protected farm endpoints.

#### Scenario: Valid bearer token assigns the current user
- **WHEN** the auth helper processes a request with a valid `Authorization: Bearer <token>` header
- **THEN** the system resolves the user from the token
- **THEN** the system assigns the current user to the request for downstream controller code

#### Scenario: Missing bearer token halts the request
- **WHEN** the auth helper processes a request without a valid bearer token header
- **THEN** the system responds with `401 Unauthorized`
- **THEN** the request does not continue to the controller action

#### Scenario: Invalid bearer token halts the request
- **WHEN** the auth helper processes a request with an invalid bearer token
- **THEN** the system responds with `401 Unauthorized`
- **THEN** the request does not continue to the controller action
