## Requirements

### Requirement: Account creation persists a reusable authenticated user
The system SHALL provide a shared account creation function that persists a user record for authenticated games.

#### Scenario: Create a user with a valid username and PIN
- **WHEN** `create_user` is called with a username of at least 6 characters and a PIN containing exactly 6 numeric characters
- **THEN** the system creates a user with a UUID primary key
- **THEN** the stored username is normalized for case-insensitive uniqueness
- **THEN** the PIN is stored as a bcrypt hash instead of raw input
- **THEN** `failed_login_attempts` is initialized for future authentication tracking

#### Scenario: Reject a duplicate username regardless of case
- **WHEN** `create_user` is called with a username whose normalized value already exists
- **THEN** the system rejects the request as invalid
- **THEN** no second user record is created

#### Scenario: Reject an invalid PIN format
- **WHEN** `create_user` is called with a PIN that is not exactly 6 numeric characters
- **THEN** the system rejects the request as invalid
- **THEN** no user record is created

### Requirement: User authentication verifies the PIN against the stored hash
The system SHALL provide an authentication function that locates a user by case-insensitive username and verifies the supplied PIN with bcrypt.

#### Scenario: Authenticate with valid credentials
- **WHEN** `authenticate_user` is called with a username and PIN that match a persisted user
- **THEN** the system returns the authenticated user

#### Scenario: Reject invalid credentials
- **WHEN** `authenticate_user` is called with a valid username and an incorrect PIN
- **THEN** the system rejects authentication

#### Scenario: Resolve username case-insensitively during login
- **WHEN** `authenticate_user` is called with a username that differs only by letter case from the persisted user
- **THEN** the system matches the existing user record

### Requirement: User account credentials can be updated through the shared domain API
The system SHALL provide an update function that allows account usernames and PINs to be changed while preserving the same validation and security rules as account creation.

#### Scenario: Update a username successfully
- **WHEN** `update_user` is called with a new valid username
- **THEN** the system persists the normalized username
- **THEN** the updated username remains unique case-insensitively

#### Scenario: Update a PIN successfully
- **WHEN** `update_user` is called with a new valid six-digit PIN
- **THEN** the system stores a new bcrypt hash instead of the raw PIN

#### Scenario: Reject an invalid update
- **WHEN** `update_user` is called with an invalid username or invalid PIN format
- **THEN** the system rejects the update
- **THEN** the existing persisted credentials remain unchanged

### Requirement: Authenticated user resolution works from a validated JWT
The system SHALL provide a function that resolves the current user from a signed JWT.

#### Scenario: Fetch a user from a valid JWT
- **WHEN** `get_user_from_jwt` is called with a valid signed token for an existing user
- **THEN** the system validates the token
- **THEN** the system fetches the referenced user from the database
- **THEN** the system returns that user

#### Scenario: Reject an invalid JWT during user resolution
- **WHEN** `get_user_from_jwt` is called with an invalid or malformed token
- **THEN** the system rejects the token
- **THEN** the system does not return a user

#### Scenario: Reject a JWT for a deleted user
- **WHEN** `get_user_from_jwt` is called with a valid token whose referenced user no longer exists
- **THEN** the system does not return a user
