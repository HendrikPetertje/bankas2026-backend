## Why

The application now has enough core functionality to run outside local `mix phx.server`, but there is no containerized deployment setup for a small self-hosted server. A Dockerfile and Docker Compose setup will make it straightforward to build the app, inject runtime secrets from `.env`, and run it alongside PostgreSQL with persistent local storage.

## What Changes

- Add a Dockerfile that builds the Phoenix application for the correct Elixir and OTP versions without baking runtime secrets into the image.
- Add a `docker-compose.yml` file that runs the Phoenix server and a PostgreSQL container together.
- Inject runtime environment variables into the app container from `.env` via Compose.
- Map host port `4010` to container port `4000`.
- Persist PostgreSQL data under `/postgres` in the project directory.
- Ignore `/postgres` in git.

## Capabilities

### New Capabilities
- `dockerized-deployment`: Container build and runtime setup for the Phoenix app and PostgreSQL.

### Modified Capabilities

None.

## Impact

- Affected code: new Docker and Compose configuration files plus ignore rules.
- Runtime: adds a supported self-hosted container workflow.
- Secrets handling: keeps runtime secrets outside the built image and injects them through Compose.
- Local storage: introduces a project-local PostgreSQL data directory.
