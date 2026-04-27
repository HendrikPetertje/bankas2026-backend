## 1. Shared Domain Updates

- [x] 1.1 Extend `Accounts.authenticate_user/2` to track failed attempts, reset counters on success, and return a distinct lockout result during the 10 minute lockout window.
- [x] 1.2 Add or adjust account tests to cover failed-attempt increments, reset-on-success behavior, and active lockout rejection.

## 2. User Auth API

- [x] 2.1 Add public API routes for `POST /api/users/sign-up`, `POST /api/users/login`, and the required `OPTIONS` preflight handling.
- [x] 2.2 Implement the sign-up flow that creates the user, calls `Farms.create_farm/1`, creates a JWT, and returns `{token, garden}`.
- [x] 2.3 Implement the login flow that authenticates the user, handles lockout responses, calls `Farms.get_farm_by_user_id/1`, creates a fresh JWT, and returns `{token, garden}`.
- [x] 2.4 Add shared JSON rendering for the auth responses using the agreed garden payload shape without exposing `pincode_hash`.

## 3. CORS Handling

- [x] 3.1 Add API CORS handling that allows `https://lager.bankasviken` and `http://localhost:3000`.
- [x] 3.2 Support preflight `OPTIONS` responses with the required methods and headers for JSON and authorization requests.

## 4. Verification

- [x] 4.1 Add endpoint tests for successful sign-up, successful login, validation errors, invalid credentials, and lockout responses.
- [x] 4.2 Add endpoint or plug tests for allowed-origin CORS headers, unknown origins, and approved-origin `OPTIONS` preflight behavior.
- [x] 4.3 Run `mix precommit` and fix any issues.
