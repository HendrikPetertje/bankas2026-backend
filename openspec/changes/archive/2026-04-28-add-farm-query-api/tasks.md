## 1. Request Auth Helper

- [x] 1.1 Add a reusable request auth helper or plug that validates bearer tokens, loads the current user, assigns it to the request, and halts with `401` on auth failure.
- [x] 1.2 Add focused tests for valid token assignment and `401` behavior for missing or invalid tokens.

## 2. Farm Query API

- [x] 2.1 Add public and authenticated farm routes for `GET /api/farms/plant-info` and `GET /api/farms/me`.
- [x] 2.2 Add a Farms controller and JSON rendering that return plant catalog data and the existing garden payload shape.
- [x] 2.3 Implement the authenticated `GET /api/farms/me` action by reusing the request auth helper and the existing Farms context.

## 3. Verification

- [x] 3.1 Add endpoint tests for public plant info, authenticated farm lookup, and unauthorized access to `GET /api/farms/me`.
- [x] 3.2 Run `mix precommit` and fix any issues.
