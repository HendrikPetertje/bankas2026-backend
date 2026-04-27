## ADDED Requirements

### Requirement: Sign-up creates a shared account and initial farm state
The system SHALL provide a public `POST /api/users/sign-up` endpoint that creates a new shared account and provisions the initial farming state.

#### Scenario: Successful sign-up provisions the user and garden
- **WHEN** a client sends a valid `POST /api/users/sign-up` request with `username` and `pin`
- **THEN** the system creates the user account
- **THEN** the system creates one garden for that user
- **THEN** the system creates exactly 9 empty plots for that garden
- **THEN** the system returns a signed JWT and the created garden payload as JSON

#### Scenario: Sign-up rejects invalid account input
- **WHEN** a client sends `POST /api/users/sign-up` with an invalid username or PIN
- **THEN** the system rejects the request with `422 Unprocessable Entity`
- **THEN** the system does not create a user or a garden

#### Scenario: Sign-up rejects duplicate usernames regardless of case
- **WHEN** a client sends `POST /api/users/sign-up` with a username whose normalized value already exists
- **THEN** the system rejects the request with `422 Unprocessable Entity`
- **THEN** the system returns validation details in JSON

### Requirement: Login returns a fresh token and current garden state
The system SHALL provide a public `POST /api/users/login` endpoint that authenticates a user and returns a fresh token plus the current garden payload.

#### Scenario: Successful login returns token and garden
- **WHEN** a client sends a valid `POST /api/users/login` request with matching credentials
- **THEN** the system authenticates the user
- **THEN** the system returns a signed JWT and the current garden payload as JSON

#### Scenario: Login rejects invalid credentials
- **WHEN** a client sends `POST /api/users/login` with an unknown username or wrong PIN
- **THEN** the system rejects the request with `401 Unauthorized`

### Requirement: Login lockout is enforced after repeated failures
The system SHALL enforce the shared account lockout policy during login.

#### Scenario: Fifth failed login starts the lockout window
- **WHEN** a user accumulates a fifth failed login attempt within the active tracking window
- **THEN** the system stores the failed attempt state on the account
- **THEN** subsequent login attempts during the next 10 minutes are rejected with `401 Unauthorized`
- **THEN** the response body includes `{ "reason": "to many login attempts" }`

#### Scenario: Successful login resets failed attempt tracking
- **WHEN** a locked user waits until the lockout window has passed and then logs in with valid credentials
- **THEN** the system authenticates the user
- **THEN** the system resets failed login tracking on the account

### Requirement: Sign-up and login responses use the shared farm payload
The system SHALL return the same garden response shape from both sign-up and login.

#### Scenario: Auth responses omit password material
- **WHEN** the system returns the garden payload from sign-up or login
- **THEN** the response includes `user_name`, `produced_g`, and `plots`
- **THEN** the response does not include `pincode_hash`
