# Deployment

## Terraform-first flow

1. Apply infrastructure from `terraform/envs/<env>`.
2. Capture outputs for:
   - ALB DNS name
   - ECS cluster name
   - ECR repository URLs
   - ECS service names
3. Configure GitHub Actions variables and secrets.
4. Deploy UI first, then deploy backend services.

## GitHub Actions variables

Recommended repository variables:

- `AWS_REGION`
- `ECS_CLUSTER_NAME`
- `ECS_UI_SERVICE_NAME`
- `ECS_CATALOG_SERVICE_NAME`
- `ECS_CART_SERVICE_NAME`
- `ECS_CHECKOUT_SERVICE_NAME`
- `ECS_ORDERS_SERVICE_NAME`
- `ECR_UI_REPOSITORY`
- `ECR_CATALOG_REPOSITORY`
- `ECR_CART_REPOSITORY`
- `ECR_CHECKOUT_REPOSITORY`
- `ECR_ORDERS_REPOSITORY`
- `UI_BUILD_CONTEXT`
- `CATALOG_BUILD_CONTEXT`
- `CART_BUILD_CONTEXT`
- `CHECKOUT_BUILD_CONTEXT`
- `ORDERS_BUILD_CONTEXT`
- `SMOKE_TEST_URL`

Required secret:

- `AWS_DEPLOY_ROLE_ARN`

## Deployment sequence

- deploy the `ui` service through `deploy-ui.yml`
- deploy backend services individually through `deploy-services.yml`
- verify ECS steady state
- run smoke tests against the ALB URL

## Zero-downtime deployment model

This repository follows the Medium article's preferred path:

- ECS rolling deployment
- desired count `>= 2`
- `minimum_healthy_percent = 100`
- `maximum_percent = 200`
- deployment circuit breaker enabled
- rollback enabled
- smoke test after stability

`Blue/green` and `canary` are intentionally not the default here. They are valid for higher-risk cutovers, but the article's baseline approach is rolling deployment with health checks and circuit-breaker rollback.
