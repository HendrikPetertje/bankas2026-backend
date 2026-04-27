## Requirements

### Requirement: JWT tokens are created as signed application tokens
The system SHALL generate signed JWT tokens for authenticated users through a dedicated JWT module.

#### Scenario: Create a token for a user
- **WHEN** the JWT module creates a token for a persisted user
- **THEN** the token is signed with the configured application secret
- **THEN** the token includes an `iat` claim
- **THEN** the token includes the username claim
- **THEN** the token includes a stable subject claim that identifies the user

### Requirement: JWT validation rejects untrusted or malformed tokens
The system SHALL validate incoming JWT tokens before they are used for authentication.

#### Scenario: Accept a valid signed token
- **WHEN** the JWT module validates a token signed with the configured application secret
- **THEN** the system accepts the token and returns its claims

#### Scenario: Reject a token signed with the wrong secret
- **WHEN** the JWT module validates a token that was not signed with the configured application secret
- **THEN** the system rejects the token

#### Scenario: Reject a malformed token
- **WHEN** the JWT module validates a malformed token string
- **THEN** the system rejects the token

### Requirement: JWT secret configuration is environment-backed
The system SHALL read the JWT signing secret from environment-driven configuration and document the required variable for local setup.

#### Scenario: Runtime configuration has a JWT secret available
- **WHEN** the application boots with the required JWT secret environment variable set
- **THEN** the JWT module can sign and validate tokens with that configured secret

#### Scenario: Local setup documents the JWT secret variable
- **WHEN** a developer reads the repository environment example file
- **THEN** the file shows the JWT secret variable name and an example value

#### Scenario: Local secrets are not committed to the repository
- **WHEN** a developer creates a local `.env` file with the JWT secret
- **THEN** the repository ignores that file
