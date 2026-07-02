# Application Scope

## Supported services

MVP mode:

- `ui`
- `catalog`
- `cart`
- `checkout`

Full mode:

- `ui`
- `catalog`
- `cart`
- `checkout`
- `orders`

## Assumptions

- the upstream services expose HTTP endpoints suitable for ECS health checks
- service-to-service URLs can be injected through environment variables
- the exact Docker build contexts are pinned outside this repository

## Integration contract

- images are published to ECR per service
- ECS task definitions reference immutable image tags
- backend service names remain stable across environments

