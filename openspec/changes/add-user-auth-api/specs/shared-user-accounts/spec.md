## MODIFIED Requirements

### Requirement: User authentication verifies the PIN against the stored hash
The system SHALL provide an authentication function that locates a user by case-insensitive username, verifies the supplied PIN with bcrypt, tracks failed login attempts, and enforces the lockout policy used by the public login API.

#### Scenario: Authenticate with valid credentials
- **WHEN** `authenticate_user` is called with a username and PIN that match a persisted user
- **THEN** the system returns the authenticated user
- **THEN** the system resets failed login tracking on that account

#### Scenario: Reject invalid credentials
- **WHEN** `authenticate_user` is called with a valid username and an incorrect PIN
- **THEN** the system rejects authentication
- **THEN** the system increments failed login tracking for that account

#### Scenario: Resolve username case-insensitively during login
- **WHEN** `authenticate_user` is called with a username that differs only by letter case from the persisted user
- **THEN** the system matches the existing user record

#### Scenario: Reject login during an active lockout window
- **WHEN** `authenticate_user` is called for an account that has reached the failed-attempt threshold and the 10 minute lockout window is still active
- **THEN** the system rejects authentication with a distinct lockout result
- **THEN** the system does not authenticate the user even if the supplied PIN is otherwise correct
