# App Integration Notes

This directory intentionally keeps application concerns separate from the infrastructure repository.

## Expected usage

- place the upstream checkout under `app/upstream/retail-store-sample-app`
- pin the upstream commit in `app/upstream.md`
- build only the selected services needed by ECS Fargate

## Selected services

- `ui`
- `catalog`
- `cart`
- `checkout`
- `orders` in full mode

## Local development

Use [docker-compose.local.yml](/Users/hakan/ecs-retail/app/docker-compose.local.yml:1) as a thin adapter for local smoke testing and image build verification.

