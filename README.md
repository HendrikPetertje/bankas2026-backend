# Bankas2026Backend

Phoenix JSON API for Bankasviken game backends.

## Requirements

- Elixir
- Erlang/OTP
- PostgreSQL

## Setup

1. Create a local env file from the example:

```bash
cp .env_example .env
```

2. Set a JWT secret in `.env`.

You can generate one with:

```bash
mix phx.gen.secret
```

3. Export the env file in your shell.

Example:

```bash
set -a
source .env
set +a
```

4. Install dependencies, create the database, run migrations, and build assets:

```bash
mix setup
```

Keep `.env` in plain `KEY=value` format. Do not prefix lines with `export` if you want Docker Compose to read the file correctly.

## Run The Server

Start the Phoenix server with:

```bash
mix phx.server
```

Or inside IEx:

```bash
iex -S mix phx.server
```

The app will be available at `http://localhost:4000`.

## Docker / Compose

Build and run the app plus PostgreSQL with Compose:

```bash
podman compose up --build
```

On your server you can use Docker Compose instead:

```bash
docker compose up --build -d
```

The containerized Phoenix server listens on port `4000` inside the container and is exposed on port `4010` on the host.

PostgreSQL data is stored in the project-local `/postgres` directory.

## Database Commands

Create, migrate, and seed the database:

```bash
mix ecto.setup
```

Drop and recreate the database:

```bash
mix ecto.reset
```

Run pending migrations:

```bash
mix ecto.migrate
```

## Test Suite

Run the full test suite:

```bash
mix test
```

Run the project verification suite used before commits:

```bash
mix precommit
```

## API Endpoints

All examples below assume the server is running at `http://localhost:4000`.

Protected endpoints require a bearer token:

```bash
-H "Authorization: Bearer $FARM_TOKEN"
```

The API currently exposes these routes:

- `POST /api/users/sign-up`
- `POST /api/users/login`
- `GET /api/farms/plant-info`
- `GET /api/farms/me`
- `POST /api/farms/plots/:plot_number/clean`
- `POST /api/farms/plots/:plot_number/seed`
- `POST /api/farms/plots/:plot_number/water`
- `POST /api/farms/plots/:plot_number/harvest`
- `OPTIONS /api/*path`

## User Auth

### `POST /api/users/sign-up`

Creates a user, creates that user's farm, and returns a JWT plus the initial garden state.

```bash
curl -X POST http://localhost:4000/api/users/sign-up \
  -H "Content-Type: application/json" \
  -d '{
    "username": "farmer123",
    "pin": "123456"
  }'
```

Export the returned token to `FARM_TOKEN`:

```bash
export FARM_TOKEN="$({
  curl -s -X POST http://localhost:4000/api/users/sign-up \
    -H "Content-Type: application/json" \
    -d '{
      "username": "farmer123",
      "pin": "123456"
    }'
} | jq -r '.token')"
```

### `POST /api/users/login`

Authenticates an existing user and returns a fresh JWT plus the current garden state.

```bash
curl -X POST http://localhost:4000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "farmer123",
    "pin": "123456"
  }'
```

Refresh `FARM_TOKEN` from the login response:

```bash
export FARM_TOKEN="$({
  curl -s -X POST http://localhost:4000/api/users/login \
    -H "Content-Type: application/json" \
    -d '{
      "username": "farmer123",
      "pin": "123456"
    }'
} | jq -r '.token')"
```

### `OPTIONS /api/users/sign-up`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/users/sign-up \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

### `OPTIONS /api/users/login`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/users/login \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

## Farms

### `GET /api/farms/plant-info`

Returns the hard-coded plant catalog.

```bash
curl -X GET http://localhost:4000/api/farms/plant-info
```

### `GET /api/farms/me`

Returns the current authenticated garden state.

```bash
curl -X GET http://localhost:4000/api/farms/me \
  -H "Authorization: Bearer $FARM_TOKEN"
```

### `OPTIONS /api/farms/me`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/farms/me \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET"
```

## Plot Actions

All plot action endpoints require authentication and return the full updated garden state.

### `POST /api/farms/plots/:plot_number/clean`

Cleans a plot or removes weeds from the selected plot.

```bash
curl -X POST http://localhost:4000/api/farms/plots/1/clean \
  -H "Authorization: Bearer $FARM_TOKEN"
```

### `POST /api/farms/plots/:plot_number/seed`

Seeds a plot with a valid plant kind.

```bash
curl -X POST http://localhost:4000/api/farms/plots/1/seed \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $FARM_TOKEN" \
  -d '{
    "plant_kind": "carrot"
  }'
```

### `POST /api/farms/plots/:plot_number/water`

Waters the selected plot.

```bash
curl -X POST http://localhost:4000/api/farms/plots/1/water \
  -H "Authorization: Bearer $FARM_TOKEN"
```

### `POST /api/farms/plots/:plot_number/harvest`

Harvests a ready plot and returns the updated garden.

```bash
curl -X POST http://localhost:4000/api/farms/plots/1/harvest \
  -H "Authorization: Bearer $FARM_TOKEN"
```

### `OPTIONS /api/farms/plots/:plot_number/clean`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/farms/plots/1/clean \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

### `OPTIONS /api/farms/plots/:plot_number/seed`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/farms/plots/1/seed \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

### `OPTIONS /api/farms/plots/:plot_number/water`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/farms/plots/1/water \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

### `OPTIONS /api/farms/plots/:plot_number/harvest`

Preflight request for browser clients.

```bash
curl -i -X OPTIONS http://localhost:4000/api/farms/plots/1/harvest \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```
