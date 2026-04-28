## 1. Container Build

- [x] 1.1 Add a Dockerfile for the correct Elixir and OTP versions that installs dependencies and builds the Phoenix application.
- [x] 1.2 Ensure the image build does not copy `.env` or embed runtime secrets into the image.

## 2. Compose Runtime

- [x] 2.1 Add a `docker-compose.yml` file that runs the app container and a PostgreSQL container together.
- [x] 2.2 Configure the app service to receive runtime env vars from `.env` and expose host port `4010` to container port `4000`.
- [x] 2.3 Configure the PostgreSQL service to persist its data under `/postgres` in the project directory.

## 3. Repository Hygiene And Verification

- [x] 3.1 Add `/postgres` to `.gitignore`.
- [x] 3.2 Validate the Docker and Compose files for correctness and update documentation if needed.
