## Why

The project now has a shared `Accounts` domain and JWT support, but clients still have no HTTP API for sign-up or login. The farming game cannot start without public user auth endpoints, and browser clients also need explicit CORS support for the approved SPA origins.

## What Changes

- Add public JSON endpoints for `POST /api/users/sign-up` and `POST /api/users/login`.
- Create a user on sign-up, create the associated farm garden and its 9 empty plots, and return `{token, garden}`.
- Authenticate existing users on login and return a fresh `{token, garden}` response.
- Enforce failed-login lockout behavior at the API boundary using the existing account tracking fields.
- Add CORS handling for `https://lager.bankasviken` and `http://localhost:3000`, including preflight `OPTIONS` support.

## Capabilities

### New Capabilities
- `user-auth-api`: Public JSON API endpoints for user sign-up and login.
- `api-cors`: Cross-origin access rules for approved SPA origins.

### Modified Capabilities
- `shared-user-accounts`: Add the observable account lockout behavior needed by the login API.

## Impact

- Affected code: router, controllers, JSON rendering, auth-related plugs, farms integration, and account logic.
- Affected APIs: introduces `/api/users/sign-up` and `/api/users/login`.
- Browser access: adds cross-origin support for the approved production and local SPA origins.
- Systems: sign-up now spans both Accounts and Farms to provision the initial garden state.
