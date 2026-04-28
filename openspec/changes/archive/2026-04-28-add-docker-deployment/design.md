## Context

The application now has enough implemented functionality to be useful outside local development, but there is still no containerized deployment path. For a small home server, the missing pieces are a Docker image build, a Compose runtime that injects environment variables from `.env`, and a PostgreSQL container with persistent local storage.

This change touches both build-time and runtime concerns:

- container build for the Phoenix application
- runtime environment injection without baking secrets into the image
- local PostgreSQL orchestration
- local persistent data handling under the project directory

## Goals / Non-Goals

**Goals:**

- Add a Dockerfile that builds the app with the correct Elixir and OTP versions.
- Ensure runtime secrets are not copied into the image.
- Add a Compose file that runs the app container and a PostgreSQL container together.
- Bind host port `4010` to container port `4000`.
- Store PostgreSQL data under `/postgres` in the project directory.
- Ignore `/postgres` in git.

**Non-Goals:**

- Add cloud deployment manifests or orchestration beyond Docker Compose.
- Move secrets into Docker secrets, Vault, or another secret manager.
- Add TLS termination or reverse proxy configuration.
- Redesign Phoenix runtime config beyond what is needed for Compose.

## Decisions

### Build a production-style image without embedding secrets

The Dockerfile should compile the application inside the image, but it should not copy `.env` or otherwise bake runtime secrets into any build layer. Runtime values like `JWT_SECRET`, `DATABASE_URL`, and `SECRET_KEY_BASE` should be injected only when the container starts.

Alternatives considered:

- Copy `.env` into the image: rejected because it would bake secrets into the image and the layer history.

### Use Docker Compose for both the app and PostgreSQL

For a home server, Compose is the simplest way to run the app and database together, mount persistent local storage, and inject env vars from the project’s `.env` file.

Alternatives considered:

- Run PostgreSQL outside Compose: rejected because the request explicitly asks for a Compose-managed Postgres instance.

### Map host `4010` to container `4000`

Phoenix already defaults to port `4000` in the container runtime. Compose should publish that internal port to `4010` on the host to avoid conflicts and match the requested home-server layout.

Alternatives considered:

- Change the app to run on `4010` internally: rejected because there is no need to diverge from the current runtime default.

### Persist PostgreSQL data under a project-local `/postgres` directory

The Compose file should mount a local directory under the project root so database data survives container recreation. That directory should be git ignored.

Alternatives considered:

- Use an anonymous Docker volume: rejected because the request explicitly wants `/postgres` in the project directory.

### Use the existing runtime env configuration model

The current app already reads runtime config from environment variables. The Compose setup should feed that mechanism rather than invent a second config path.

Alternatives considered:

- Add environment-specific runtime loaders inside the app: rejected because Compose already handles env injection cleanly.

## Risks / Trade-offs

- Production-style image builds may require more explicit system packages than local `mix phx.server` -> mitigate by documenting and testing the Docker build path.
- Compose env injection depends on a correctly exported or referenced `.env` file -> mitigate by documenting the required variables clearly.
- Project-local database storage increases the chance of accidental large local data directories -> mitigate by adding `/postgres` to `.gitignore`.

## Migration Plan

1. Add the Dockerfile.
2. Add the Compose file for app plus Postgres.
3. Update `.gitignore` for `/postgres`.
4. Document or test the container startup flow if needed during implementation.

Rollback strategy:

- Remove the Dockerfile and Compose files.
- Remove the `/postgres` ignore rule if the container workflow is abandoned.

## Open Questions

- None. The requested port mapping, env injection model, and local PostgreSQL storage location are all specified.
