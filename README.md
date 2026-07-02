# ecs-fargate-retail-sample-production

Production-ready ECS Fargate wrapper repository for the AWS Containers Retail Sample App. This repository uses the upstream application as the workload source and adds the infrastructure, CI/CD, security, rollout, and operational controls needed for a production-oriented deployment flow.

> This project creates AWS resources that incur cost. Start with `dev`, keep optional dependencies disabled until needed, and destroy non-prod environments after testing.

## Project goal

This repository is built to match the Medium article's deployment story:

- upstream retail sample application
- ECS Fargate services in private subnets
- public ALB for the UI only
- Terraform-managed infrastructure
- GitHub Actions with AWS OIDC
- immutable image tags
- rolling deployment with deployment circuit breaker and rollback
- production-minded security and cost controls

## Upstream application

Application source of truth:

- Upstream repository: <https://github.com/aws-containers/retail-store-sample-app>
- Local integration notes: [app/upstream.md](/Users/hakan/ecs-retail/app/upstream.md:1)
- Attribution: [docs/original-app-attribution.md](/Users/hakan/ecs-retail/docs/original-app-attribution.md:1)

Selected services used by this repo:

- `ui`
- `catalog`
- `cart`
- `checkout`
- `orders` in full mode

## Sprint 1

Sprint 1 is the foundation sprint for making the repository deployable and understandable.

- scope document: [docs/sprint-1.md](/Users/hakan/ecs-retail/docs/sprint-1.md:1)
- output: shared Terraform root, environment tfvars, remote backend bootstrap, zero-downtime deploy workflows, operator-focused README

Sprint 1 goals:

- shared Terraform code for `dev` and `prod`
- environment split with `tfvars` and `backend.hcl`
- S3 remote backend with native Terraform lockfile support
- ECS rolling deployment workflow with rollback guardrails
- documented GitHub variables, secrets, and setup flow

## Architecture

High-level request flow:

```text
Internet User
  -> Route53 / CloudFront (optional)
  -> Public Application Load Balancer
  -> ECS Fargate UI Service
  -> Private backend services
     -> catalog
     -> cart
     -> checkout
     -> orders (optional)
  -> Data services
     -> DynamoDB
     -> ElastiCache Redis (optional)
     -> RDS MariaDB / PostgreSQL (optional)
```

Core security and networking decisions:

- ALB lives in public subnets
- ECS tasks run in private subnets
- ECS tasks do not receive public IPs
- backend services are not publicly exposed
- security groups restrict inbound traffic to ALB-to-UI and private east-west traffic only
- task execution role and task role are separate
- secrets are consumed from Secrets Manager references, not hardcoded into images

Supporting docs:

- architecture: [docs/architecture.md](/Users/hakan/ecs-retail/docs/architecture.md:1)
- security: [docs/security.md](/Users/hakan/ecs-retail/docs/security.md:1)
- troubleshooting: [docs/troubleshooting.md](/Users/hakan/ecs-retail/docs/troubleshooting.md:1)
- runbook: [docs/runbook.md](/Users/hakan/ecs-retail/docs/runbook.md:1)

## Application modes

`dev / MVP mode`:

- `ui`
- `catalog`
- `cart`
- `checkout`
- DynamoDB enabled
- RDS disabled
- Redis disabled
- single NAT gateway
- lower log retention
- lower task sizes and scale limits

`prod / full mode`:

- `ui`
- `catalog`
- `cart`
- `checkout`
- `orders`
- DynamoDB enabled
- RDS enabled
- Redis enabled
- per-AZ NAT gateways
- Multi-AZ database options
- WAF and HTTPS-ready settings

## Repository layout

```text
.
├── app/
│   ├── docker-compose.local.yml
│   ├── README.md
│   ├── upstream.md
│   └── upstream/retail-store-sample-app/
├── docs/
├── scripts/
├── terraform/
│   ├── backend.tf
│   ├── bootstrap/remote-state/
│   ├── envs/dev/
│   ├── envs/prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
└── .github/workflows/
```

## Prerequisites

- AWS account with rights to create VPC, ECS, ECR, ALB, IAM, CloudWatch, DynamoDB, Secrets Manager, and optional RDS/ElastiCache/WAF resources
- Terraform `>= 1.10`
- AWS CLI v2
- Docker
- GitHub repository admin rights for Actions OIDC, variables, and secrets

## Local application run

Run the selected upstream services locally:

```bash
cd app
DB_PASSWORD=testing docker compose -f docker-compose.local.yml up --build
```

Primary local URL:

- UI: `http://localhost:8888`

Useful service directories:

- `app/upstream/retail-store-sample-app/src/ui`
- `app/upstream/retail-store-sample-app/src/catalog`
- `app/upstream/retail-store-sample-app/src/cart`
- `app/upstream/retail-store-sample-app/src/checkout`
- `app/upstream/retail-store-sample-app/src/orders`

## Terraform design

Terraform uses one shared root for all environments.

Shared root:

- [terraform/main.tf](/Users/hakan/ecs-retail/terraform/main.tf:1)
- [terraform/variables.tf](/Users/hakan/ecs-retail/terraform/variables.tf:1)
- [terraform/outputs.tf](/Users/hakan/ecs-retail/terraform/outputs.tf:1)

Environment split:

- `terraform/envs/dev/dev.tfvars`
- `terraform/envs/dev/backend.hcl`
- `terraform/envs/prod/prod.tfvars`
- `terraform/envs/prod/backend.hcl`

Remote backend:

- backend type: `s3`
- locking: `use_lockfile = true`
- DynamoDB lock table: not used

Bootstrap remote state first:

```bash
cd terraform/bootstrap/remote-state
terraform init
terraform apply \
  -var='aws_region=eu-central-1' \
  -var='bucket_name=your-unique-tf-state-bucket'
```

Plan and apply `dev`:

```bash
cd terraform
terraform init -backend-config=envs/dev/backend.hcl
terraform plan -var-file=envs/dev/dev.tfvars
terraform apply -var-file=envs/dev/dev.tfvars
```

Plan and apply `prod`:

```bash
cd terraform
terraform init -backend-config=envs/prod/backend.hcl
terraform plan -var-file=envs/prod/prod.tfvars
terraform apply -var-file=envs/prod/prod.tfvars
```

Key modules:

- `vpc`
- `security-groups`
- `ecr`
- `ecs-cluster`
- `ecs-service`
- `iam`
- `alb`
- `cloudwatch`
- `autoscaling`
- `dynamodb`
- `elasticache`
- `rds`
- `service-discovery`
- `waf`
- `remote-state`

## Infrastructure created

Base infrastructure:

- VPC
- public and private subnets
- internet gateway
- NAT gateway strategy by environment
- optional VPC endpoints
- public ALB
- ECS cluster
- one ECS service per application component
- one task definition family per component
- service discovery namespace
- CloudWatch log groups
- CloudWatch alarms
- Application Auto Scaling targets and policies
- private ECR repositories

Data dependencies:

- DynamoDB table for cart
- optional ElastiCache Redis for checkout
- optional RDS MariaDB for catalog
- optional RDS PostgreSQL for orders

Security controls:

- security groups with minimum ingress
- IAM execution role
- IAM task roles
- Secrets Manager-compatible secret references
- optional WAF

## GitHub secrets and variables

Configure these before using deploy workflows.

Required GitHub secret:

| Name | Purpose |
| --- | --- |
| `AWS_DEPLOY_ROLE_ARN` | IAM role assumed by GitHub Actions through OIDC |

Recommended GitHub repository variables:

| Name | Purpose |
| --- | --- |
| `AWS_REGION` | AWS region used by deploy workflows |
| `ECS_CLUSTER_NAME` | ECS cluster name from Terraform output |
| `ECS_UI_SERVICE_NAME` | ECS service name for UI |
| `ECS_CATALOG_SERVICE_NAME` | ECS service name for catalog |
| `ECS_CART_SERVICE_NAME` | ECS service name for cart |
| `ECS_CHECKOUT_SERVICE_NAME` | ECS service name for checkout |
| `ECS_ORDERS_SERVICE_NAME` | ECS service name for orders |
| `ECS_UI_TASK_DEFINITION_FAMILY` | Current task definition family for UI |
| `ECS_CATALOG_TASK_DEFINITION_FAMILY` | Current task definition family for catalog |
| `ECS_CART_TASK_DEFINITION_FAMILY` | Current task definition family for cart |
| `ECS_CHECKOUT_TASK_DEFINITION_FAMILY` | Current task definition family for checkout |
| `ECS_ORDERS_TASK_DEFINITION_FAMILY` | Current task definition family for orders |
| `ECR_UI_REPOSITORY` | ECR repository URL for UI |
| `ECR_CATALOG_REPOSITORY` | ECR repository URL for catalog |
| `ECR_CART_REPOSITORY` | ECR repository URL for cart |
| `ECR_CHECKOUT_REPOSITORY` | ECR repository URL for checkout |
| `ECR_ORDERS_REPOSITORY` | ECR repository URL for orders |
| `SMOKE_TEST_URL` | Public URL used by smoke test after UI deployment |

Suggested mapping source:

- ECS cluster name: `terraform output ecs_cluster_name`
- ECS service names: `terraform output ecs_service_names`
- task definition families: `terraform output ecs_task_definition_families`
- ECR repository URLs: `terraform output ecr_repository_urls`
- ALB URL: `terraform output application_url`

Helper script:

- [scripts/sync-github-variables.sh](/Users/hakan/ecs-retail/scripts/sync-github-variables.sh:1)

Examples:

```bash
bash scripts/sync-github-variables.sh dev
bash scripts/sync-github-variables.sh prod --apply
```

## GitHub Actions workflows

Workflow inventory:

| Workflow | Purpose |
| --- | --- |
| `.github/workflows/ci.yml` | Builds selected upstream service images and validates shared-root Terraform |
| `.github/workflows/terraform-plan.yml` | Runs Terraform fmt, init, validate, and plan for `dev` or `prod` tfvars |
| `.github/workflows/deploy-ui.yml` | Builds and deploys UI with rolling update, stability wait, smoke test, and rollback guard |
| `.github/workflows/deploy-services.yml` | Manually deploys one backend service at a time with the same rolling deploy safety model |

Deployment behavior follows the Medium article:

- rolling deployment
- `desiredCount >= 2`
- `minimumHealthyPercent >= 100`
- `maximumPercent >= 200`
- deployment circuit breaker enabled
- rollback enabled
- smoke test after steady state

This repository intentionally does not default to blue/green or canary. The baseline approach is ECS rolling deployment with health checks and rollback.

## AWS OIDC setup

Minimum GitHub-to-AWS trust flow:

1. Create an IAM OIDC identity provider for GitHub.
2. Create an IAM role for deployments.
3. Restrict trust policy by repository and branch.
4. Store the role ARN as `AWS_DEPLOY_ROLE_ARN`.

The role should allow:

- ECR push
- ECS task definition registration
- ECS service update
- IAM pass role for ECS task and execution roles where required
- read access for deployment metadata lookups

## Step-by-step installation

1. Clone this repository.
2. Review upstream application notes in `app/upstream.md`.
3. Bootstrap the Terraform remote state bucket.
4. Fill `terraform/envs/dev/backend.hcl`.
5. Review and adjust `terraform/envs/dev/dev.tfvars`.
6. Run `terraform init`, `plan`, and `apply` from `terraform/`.
7. Capture Terraform outputs.
8. Create GitHub Actions secret `AWS_DEPLOY_ROLE_ARN`.
9. Create the GitHub repository variables listed above.
   Tip: `bash scripts/sync-github-variables.sh dev` prints the exact `gh variable set` commands.
10. Run `deploy-ui.yml`.
11. Run `deploy-services.yml` for `catalog`, `cart`, `checkout`, and optionally `orders`.
12. Confirm the ALB URL and run smoke validation.

## Smoke test and operations

Available helper script:

- [scripts/smoke-test.sh](/Users/hakan/ecs-retail/scripts/smoke-test.sh:1)
- [scripts/list-ecs-events.sh](/Users/hakan/ecs-retail/scripts/list-ecs-events.sh:1)
- [scripts/rollback-service.sh](/Users/hakan/ecs-retail/scripts/rollback-service.sh:1)
- [scripts/cleanup.sh](/Users/hakan/ecs-retail/scripts/cleanup.sh:1)
- [scripts/sync-github-variables.sh](/Users/hakan/ecs-retail/scripts/sync-github-variables.sh:1)

Current smoke test expectation:

- verifies the public UI URL is reachable

Operational docs:

- deployment: [docs/deployment.md](/Users/hakan/ecs-retail/docs/deployment.md:1)
- runbook: [docs/runbook.md](/Users/hakan/ecs-retail/docs/runbook.md:1)
- troubleshooting: [docs/troubleshooting.md](/Users/hakan/ecs-retail/docs/troubleshooting.md:1)

Common operator commands:

```bash
bash scripts/list-ecs-events.sh <cluster-name> <service-name>
bash scripts/rollback-service.sh <cluster-name> <service-name> --wait
bash scripts/cleanup.sh dev
```

## Security posture

Current security baseline:

- private ECS tasks
- least privilege task role separation
- no public backend exposure
- immutable image tags
- ECR scan on push
- optional WAF
- optional VPC endpoints
- Terraform remote state in private S3 bucket with versioning and encryption

Remaining hardening candidates:

- stricter IAM resource scoping for deploy role
- HTTPS enforcement with ACM in every public environment
- WAF enablement by default in prod
- GuardDuty / Security Hub / Inspector integration

## Cost considerations

`dev` defaults:

- single NAT gateway
- optional databases and Redis disabled
- lower CPU/memory values
- lower scaling ceilings
- shorter log retention

`prod` defaults:

- per-AZ NAT gateways
- optional stateful services enabled
- Multi-AZ data path options
- higher desired counts and autoscaling ceilings
- longer retention

Main cost drivers:

- Fargate runtime
- NAT gateways
- ALB
- CloudWatch logs
- RDS
- ElastiCache

More detail: [docs/cost-optimization.md](/Users/hakan/ecs-retail/docs/cost-optimization.md:1)

## Known limitations

- upstream application code remains external in design intent even though a local checkout is included for build alignment
- workflow deploy steps assume GitHub variables are mapped from Terraform outputs manually
- smoke testing is still minimal and UI-focused
- service-specific health endpoint tuning may still need refinement against the selected upstream revision

## Medium article link

Public repository for the article:

- <https://github.com/hakanbayraktar/ecs-fargate-retail-sample-production>
