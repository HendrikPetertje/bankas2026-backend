## Requirements

### Requirement: The application can be built into a Docker image without embedded runtime secrets
The system SHALL provide a Dockerfile that builds the Phoenix application for the correct Elixir and OTP versions without embedding runtime secrets in the image.

#### Scenario: Runtime secrets are not baked into the image
- **WHEN** the Docker image is built
- **THEN** runtime secret values such as `JWT_SECRET` are not copied into the image from `.env`

#### Scenario: The application build completes inside Docker
- **WHEN** the Dockerfile is used to build the application image
- **THEN** the image installs dependencies and builds the application successfully for container runtime use

### Requirement: Docker Compose runs the app and PostgreSQL together
The system SHALL provide a Docker Compose configuration that runs the Phoenix app and PostgreSQL in one stack.

#### Scenario: The app container exposes the requested host port
- **WHEN** the Compose stack starts
- **THEN** host port `4010` is mapped to container port `4000`

#### Scenario: Runtime env vars are injected from `.env`
- **WHEN** the Compose stack starts the app container
- **THEN** the container receives the required runtime environment variables from `.env`

#### Scenario: PostgreSQL persists data under the project directory
- **WHEN** the Compose stack starts the PostgreSQL container
- **THEN** the database stores its data under `/postgres` in the project directory

### Requirement: Local PostgreSQL data is not tracked by git
The system SHALL ignore the project-local PostgreSQL data directory in git.

#### Scenario: The postgres data directory is ignored
- **WHEN** PostgreSQL writes data into `/postgres`
- **THEN** git does not track that directory
