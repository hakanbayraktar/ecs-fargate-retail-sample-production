# Deployment

## Terraform-first flow

1. Bootstrap the remote state S3 bucket from `terraform/bootstrap/remote-state`.
2. Apply infrastructure from the shared root `terraform/`.
2. Capture outputs for:
   - ALB DNS name
   - ECS cluster name
   - ECR repository URLs
   - ECS service names
3. Configure GitHub Environments, variables, and secrets.
4. Deploy UI first, then deploy backend services.

Example:

```bash
cd terraform
terraform init -backend-config=envs/dev/backend.hcl
terraform plan -var-file=envs/dev/dev.tfvars
terraform apply -var-file=envs/dev/dev.tfvars
```

## GitHub Environments

Create these GitHub Environments first:

- `dev`
- `stage`
- `prod`

Store the same variable names in each environment, but point them to that environment's Terraform outputs.

To reduce manual copy work, use:

```bash
scripts/sync-github-environment-vars.sh dev
scripts/sync-github-environment-vars.sh stage --apply
```

Notes:

- dry run prints the variables that will be written
- `--apply` requires authenticated `gh`
- backend healthcheck URLs remain manual because they depend on your network reachability model

## GitHub Actions variables

Recommended environment variables:

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
- `ECS_UI_TASK_DEFINITION_FAMILY`
- `ECS_CATALOG_TASK_DEFINITION_FAMILY`
- `ECS_CART_TASK_DEFINITION_FAMILY`
- `ECS_CHECKOUT_TASK_DEFINITION_FAMILY`
- `ECS_ORDERS_TASK_DEFINITION_FAMILY`
- `SMOKE_TEST_URL`

Required secret per environment:

- `AWS_DEPLOY_ROLE_ARN`

## Deployment sequence

- run `terraform-plan.yml` manually for `dev`, `stage`, or `prod`
- deploy the `ui` service through `deploy-ui.yml`
- deploy backend services individually through `deploy-services.yml`
- verify ECS steady state
- run smoke tests against the ALB URL

Behavior:

- pushes to `main` deploy UI to `dev`
- `stage` and `prod` are manual promotion environments
- environment protection rules should be configured in GitHub for `prod`

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
