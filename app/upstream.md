# Upstream Application Strategy

## Source of truth

Upstream repository:

- <https://github.com/aws-containers/retail-store-sample-app>

## Recommended integration model

Use one of these approaches:

1. Add the upstream repository as a Git submodule under `app/upstream/retail-store-sample-app`.
2. Clone the upstream repository during CI into a known path and build only the selected services.
3. Mirror only the minimum application directories needed for `ui`, `catalog`, `cart`, `checkout`, and optionally `orders`, while preserving attribution and license files.

## Why the repository stays separate

The goal of this project is to productionize deployment on ECS Fargate. Keeping the application source separate avoids accidental divergence from upstream while making the operational layer easier to reason about.

## Pinning guidance

- pin an upstream commit hash
- record the selected services and their Docker build contexts
- validate health endpoints before production rollout
- preserve the upstream license and attribution

