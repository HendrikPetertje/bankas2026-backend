## 1. Persistence Setup

- [x] 1.1 Add the bcrypt dependency needed for PIN hashing.
- [x] 1.2 Generate the `accounts_users` migration with UUID primary key support.
- [x] 1.3 Edit the migration to add normalized `username`, `pincode_hash`, `failed_login_attempts`, and `last_failed_login_attempt_at` fields.
- [x] 1.4 Add a database-level unique index that enforces case-insensitive username uniqueness.

## 2. Accounts Domain

- [x] 2.1 Create the `Accounts.User` schema with UUID keys, field validations, and username normalization.
- [x] 2.2 Implement `Accounts.create_user/1` to validate input, hash the PIN, and insert a user record.
- [x] 2.3 Implement `Accounts.update_user/2` to support username and PIN updates with normalization, uniqueness checks, and PIN re-hashing.
- [x] 2.4 Implement `Accounts.authenticate_user/2` to look up a user case-insensitively and verify the PIN with bcrypt.
- [x] 2.5 Implement `Accounts.get_user_from_jwt/1` to validate a token and fetch the referenced user.

## 3. JWT And Configuration

- [x] 3.1 Create `Accounts.JWT` with functions to sign tokens and validate token claims through Joken.
- [x] 3.2 Configure the JWT signing secret from runtime environment variables.
- [x] 3.3 Add `.env` to `.gitignore` and create `.env_example` documenting the JWT secret variable.

## 4. Verification

- [x] 4.1 Add tests for user creation, PIN validation, username uniqueness, user updates, and case-insensitive authentication.
- [x] 4.2 Add tests for JWT signing, validation, invalid-token rejection, and deleted-user lookup failure.
- [x] 4.3 Run `mix precommit` and fix any issues.
