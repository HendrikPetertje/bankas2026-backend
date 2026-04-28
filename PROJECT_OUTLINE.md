## 1. Idea

This project is a Phoenix JSON API that supports a React SPA. The SPA is not part of this repository.

The application hosts multiple games. One of those games is a farming mini game. The farming game lets a user create an account, receive a JWT, manage a 9-plot garden, and harvest produce over time.

The backend is the source of truth for:

- account creation and login
- JWT-based authentication
- farm and plot persistence
- plant growth rules
- plot state transitions
- harvest output in grams

This project should be designed so the account system can be reused by other authenticated games later.

## 2. Goals

- Build a JSON-first Phoenix API for the farming game.
- Use one shared authentication system for auth-required games.
- Create one account, one garden, and exactly 9 plots per user.
- Return JWTs on sign-up and login.
- Enforce game rules on the server so the SPA cannot authoritatively decide game state.
- Keep plant metadata hard coded in Elixir, not in the database.
- Use integer grams for production totals. The frontend may convert grams to kilograms.
- Support public and authenticated endpoints in the same application.

## 3. Data Model

### Persisted Data

#### `accounts_users`

- `id: UUID`
- `username: string`
- `pincode_hash: string`
- `failed_login_attempts: integer`
- `last_failed_login_attempt_at: utc_datetime`
- `inserted_at: utc_datetime`
- `updated_at: utc_datetime`

Rules:

- `username` is required.
- `username` has a minimum length of 6.
- `username` is unique case-insensitively.
- `pin` is accepted by the API as a string of exactly 6 digits.
- `pincode_hash` stores a bcrypt hash. Raw PIN values are never persisted.
- `failed_login_attempts` tracks failed login attempts only.
- After 5 failed login attempts, login is blocked for 10 minutes.
- A successful login resets `failed_login_attempts` and `last_failed_login_attempt_at`.

#### `farms_gardens`

- `id: UUID`
- `user_id: UUID`
- `produced_g: integer`
- `inserted_at: utc_datetime`
- `updated_at: utc_datetime`

Rules:

- one garden per user
- `user_id` references `accounts_users.id`
- `produced_g` is required and defaults to `0`

#### `farms_garden_plots`

- `id: UUID`
- `garden_id: UUID`
- `number: integer`
- `state: string`
- `plant_kind: string | null`
- `planted_at: utc_datetime | null`
- `last_watered_at: utc_datetime | null`
- `last_weeds_removed_at: utc_datetime | null`
- `water_stars: integer | null`
- `weed_stars: integer | null`
- `last_penalty_at: utc_datetime | null`
- `inserted_at: utc_datetime`
- `updated_at: utc_datetime`

Rules:

- every garden has exactly 9 plots
- `number` is required and must be between 1 and 9
- `(garden_id, number)` is unique
- `state` values: `BARREN`, `CLEANED`, `SEEDED`
- `plant_kind` values: `LETTUCE`, `TOMATO`, `CARROT`, `PUMPKIN`
- `plant_kind` is `null` unless the plot is `SEEDED`
- fresh accounts start with 9 `BARREN` plots
- fresh plots start with `last_watered_at: null`
- cleaning a barren plot updates `last_weeds_removed_at`
- seeding initializes `water_stars` and `weed_stars` to `5`
- `last_penalty_at` prevents repeated penalty application for 30 minutes after penalties are applied
- stars never go below `1`

### Non-Persisted Data

Plant metadata is hard coded in Elixir and not stored in the database. It should live in a dedicated module used by both validation and response rendering.

Required plant metadata:

- `kind`
- `growing_time_s`
- `weight_g` keyed by final star rating `1..5`

Initial plant catalog:

- `LETTUCE`
- `TOMATO`
- `CARROT`
- `PUMPKIN`

### Response Shape

Authenticated farm responses should use this shape:

```json
{
  "garden": {
    "user_name": "string",
    "produced_g": 0,
    "plots": [
      {
        "number": 1,
        "state": "BARREN",
        "plant_kind": null,
        "planted_at": null,
        "last_watered_at": null,
        "last_weeds_removed_at": null,
        "water_stars": null,
        "weed_stars": null
      }
    ]
  }
}
```

Notes:

- `pincode_hash` is never returned.
- persisted gardens reference users by `user_id`, but farm responses expose `user_name`
- action endpoints return the entire updated farm state.

## 4. Auth

### Overview

The application uses one shared JWT-based authentication system for auth-required games.

- JWTs are handled with `joken`
- PIN hashing uses bcrypt
- tokens do not expire
- public endpoints remain accessible without a token
- protected endpoints require `Authorization: Bearer <token>`

If the token is missing or invalid, the API returns `401`.

### JWT Contents

The token payload must include:

- `iat`
- `username`

The token should also include enough information to identify the authenticated user reliably during request processing. Since users have UUID primary keys, the implementation may also include a stable subject claim such as `sub`.

### Login Attempt Rules

- failed login attempts increment `failed_login_attempts`
- after 5 failed attempts, the account is locked for 10 minutes
- locked login attempts return `401` with:

```json
{ "reason": "to many login attempts" }
```

- successful login resets failed-attempt tracking

### Auth Scope

This auth system is not farm-specific. It should be implemented so other authenticated games can reuse it.

## 5. API Endpoints

### Public Endpoints

#### `POST /api/users/sign-up`

Request body:

```json
{ "username": "string", "pin": "123456" }
```

Behavior:

- creates a user
- creates a garden for that user
- creates 9 empty plots for that garden
- returns a JWT and the created garden state

Success response:

```json
{
  "token": "JWT",
  "garden": {
    "user_name": "string",
    "produced_g": 0,
    "plots": []
  }
}
```

Validation notes:

- `username` must be unique case-insensitively
- `username` minimum length is 6
- `pin` must be exactly 6 numeric characters

#### `POST /api/users/login`

Request body:

```json
{ "username": "string", "pin": "123456" }
```

Behavior:

- authenticates the user by username and PIN
- returns a new JWT and the current garden state

Success response:

```json
{
  "token": "JWT",
  "garden": {
    "user_name": "string",
    "produced_g": 0,
    "plots": []
  }
}
```

#### `GET /api/farms/plant-info`

This endpoint is public.

Response shape:

```json
{
  "plants": [
    {
      "kind": "LETTUCE",
      "growing_time_s": 3600,
      "weight_g": {
        "5": 1000,
        "4": 800,
        "3": 600,
        "2": 400,
        "1": 200
      }
    },
    {
      "kind": "TOMATO",
      "growing_time_s": 14400,
      "weight_g": {
        "5": 5000,
        "4": 4500,
        "3": 3000,
        "2": 1000,
        "1": 800
      }
    },
    {
      "kind": "CARROT",
      "growing_time_s": 7200,
      "weight_g": {
        "5": 3000,
        "4": 2000,
        "3": 1500,
        "2": 900,
        "1": 500
      }
    },
    {
      "kind": "PUMPKIN",
      "growing_time_s": 21600,
      "weight_g": {
        "5": 7000,
        "4": 6000,
        "3": 4000,
        "2": 1000,
        "1": 900
      }
    }
  ]
}
```

### Authenticated Endpoints

#### `GET /api/farms/me`

Returns the current authenticated garden state.

#### `POST /api/farms/plots/:plot_number/clean`

Behavior:

- on `BARREN`, changes the plot to `CLEANED`
- on `SEEDED`, acts as weed removal for the growing plant
- updates `last_weeds_removed_at` to now
- returns the entire updated garden state

Notes:

- there is no separate weed-removal endpoint
- cleaning does not fix watering

#### `POST /api/farms/plots/:plot_number/seed`

Request body:

```json
{ "plant_kind": "LETTUCE" }
```

Behavior:

- allowed only on `CLEANED` plots
- requires `last_watered_at` to be within the last 30 minutes
- changes the plot to `SEEDED`
- sets `plant_kind`
- sets `planted_at` to now
- initializes `water_stars` to `5`
- initializes `weed_stars` to `5`
- returns the entire updated garden state

#### `POST /api/farms/plots/:plot_number/water`

Behavior:

- available on all plot states
- updates `last_watered_at` to now
- returns the entire updated garden state

#### `POST /api/farms/plots/:plot_number/harvest`

Behavior:

- allowed only on `SEEDED` plots
- the plant must be fully grown, meaning elapsed time since `planted_at` is greater than or equal to `growing_time_s`
- runs pre-action penalty checks first
- uses `min(water_stars, weed_stars)` as the final star rating
- looks up produced grams from hard-coded plant metadata
- adds produced grams to `garden.produced_g`
- resets the plot to `BARREN`
- clears `plant_kind`
- clears `planted_at`
- clears stars
- keeps `last_watered_at` as-is so watering cadence carries over across harvests
- returns the entire updated garden state

### Penalty Rules

Every action except `seed` runs penalty checks before doing anything else.

Penalty logic applies only to seeded plots. Penalties do not stack continuously on every request. If penalties were applied in the last 30 minutes, do not apply new penalties yet.

Water penalties:

- if time since `last_watered_at` is greater than `max(30% of growing_time_s, 1 hour)`, remove 1 water star
- if time since `last_watered_at` is greater than `max(60% of growing_time_s, 2 hours)`, set water stars to `1`

Weed penalties:

- if time since `last_weeds_removed_at` is greater than 1 hour, remove 1 weed star

Additional rules:

- minimum star value is `1`
- when a penalty is applied, update `last_penalty_at`
- final harvest quality uses the lower of `water_stars` and `weed_stars`

### Error Semantics

- `401 Unauthorized` for missing or invalid auth, and for temporary login lockouts
- `409 Conflict` for impossible state transitions caused by stale client state, such as harvesting an already harvested plot
- `422 Unprocessable Entity` for valid requests that fail game rules or validation, such as trying to harvest before a plant is fully grown
