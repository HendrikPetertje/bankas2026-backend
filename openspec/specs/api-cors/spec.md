## Requirements

### Requirement: Approved SPA origins can call the API cross-origin
The system SHALL allow browser API requests from the approved production and local SPA origins.

#### Scenario: Production SPA origin is allowed
- **WHEN** a request to an API endpoint includes the origin `https://lager.bankasviken`
- **THEN** the response includes CORS headers that allow that origin

#### Scenario: Local SPA origin is allowed
- **WHEN** a request to an API endpoint includes the origin `http://localhost:3000`
- **THEN** the response includes CORS headers that allow that origin

#### Scenario: Unknown origin is not allowed
- **WHEN** a request to an API endpoint includes an origin outside the approved list
- **THEN** the system does not grant CORS access for that origin

### Requirement: API preflight requests are answered for approved origins
The system SHALL answer browser `OPTIONS` preflight requests for approved origins and supported API methods.

#### Scenario: Preflight request succeeds for an approved origin
- **WHEN** a browser sends an `OPTIONS` request for an API route from an approved origin
- **THEN** the response includes the allowed origin header
- **THEN** the response includes the allowed methods needed by the API
- **THEN** the response includes the allowed request headers needed for JSON and authorization requests
