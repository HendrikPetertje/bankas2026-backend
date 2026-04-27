## 1. Shared Domain Updates

- [ ] 1.1 Extend `Accounts.authenticate_user/2` to track failed attempts, reset counters on success, and return a distinct lockout result during the 10 minute lockout window.
- [ ] 1.2 Add or adjust account tests to cover failed-attempt increments, reset-on-success behavior, and active lockout rejection.

## 2. User Auth API

- [ ] 2.1 Add public API routes for `POST /api/users/sign-up`, `POST /api/users/login`, and the required `OPTIONS` preflight handling.
- [ ] 2.2 Implement the sign-up flow that creates the user, provisions the garden plus 9 plots in one transaction, creates a JWT, and returns `{token, garden}`.
- [ ] 2.3 Implement the login flow that authenticates the user, handles lockout responses, creates a fresh JWT, and returns `{token, garden}`.
- [ ] 2.4 Add shared JSON rendering for the auth responses using the agreed garden payload shape without exposing `pincode_hash`.

## 3. CORS Handling

- [ ] 3.1 Add API CORS handling that allows `https://lager.bankasviken` and `http://localhost:3000`.
- [ ] 3.2 Support preflight `OPTIONS` responses with the required methods and headers for JSON and authorization requests.

## 4. Verification

- [ ] 4.1 Add endpoint tests for successful sign-up, successful login, validation errors, invalid credentials, and lockout responses.
- [ ] 4.2 Add endpoint or plug tests for allowed-origin CORS headers, unknown origins, and approved-origin `OPTIONS` preflight behavior.
- [ ] 4.3 Run `mix precommit` and fix any issues.
