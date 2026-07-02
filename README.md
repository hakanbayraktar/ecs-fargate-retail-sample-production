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
- project plan: [docs/project-plan.md](/Users/hakan/ecs-retail/docs/project-plan.md:1)

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
│   ├── upstream/
│   ├── upstream.md
│   └── docker-compose.local.yml
├── terraform/
│   ├── bootstrap/
│   │   └── remote-state/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── security-groups/
│   │   ├── ecr/
│   │   ├── iam/
│   │   ├── alb/
│   │   ├── ecs-cluster/
│   │   ├── ecs-service/
│   │   ├── service-discovery/
│   │   ├── secrets/
│   │   ├── autoscaling/
│   │   ├── cloudwatch/
│   │   ├── dynamodb/
│   │   ├── elasticache/
│   │   ├── github-actions-deploy-role/
│   │   ├── rds/
│   │   ├── remote-state/
│   │   └── waf/
│   └── envs/
│       ├── dev/
│       ├── stage/
│       └── prod/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── terraform-plan.yml
│       ├── deploy-ui.yml
│       └── deploy-services.yml
├── docs/
│   ├── architecture.md
│   ├── application.md
│   ├── project-plan.md
│   ├── deployment.md
│   ├── security.md
│   ├── cost-optimization.md
│   ├── troubleshooting.md
│   ├── runbook.md
│   └── original-app-attribution.md
├── scripts/
│   ├── smoke-test.sh
│   ├── check-ecr-scan.sh
│   ├── check-trivy-report.sh
│   ├── preflight-prod-cutover.sh
│   ├── rollback-service.sh
│   ├── list-ecs-events.sh
│   ├── cleanup.sh
│   └── sync-github-environment-vars.sh
└── README.md
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
- `terraform/envs/stage/stage.tfvars`
- `terraform/envs/prod/prod.tfvars`
- `terraform/envs/dev/backend.hcl`
- `terraform/envs/stage/backend.hcl`
- `terraform/envs/prod/backend.hcl`

Remote backend:

- backend type: `s3`
- locking: `use_lockfile = true`
- DynamoDB lock table: not used

Prod public-entry guardrails:

- `certificate_arn` is required
- `public_domain_name` is required
- `route53_zone_id` is required
- `enable_waf` must stay `true`
- `terraform-plan.yml` runs `scripts/preflight-prod-cutover.sh` before prod planning

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

Recommended GitHub Environments:

- `dev`
- `stage`
- `prod`

Store the same variable names in each environment, but with environment-specific values.

Required GitHub secret per environment:

| Name | Purpose |
| --- | --- |
| `AWS_DEPLOY_ROLE_ARN` | IAM role assumed by GitHub Actions through OIDC |

Recommended GitHub environment variables:

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
| `CATALOG_HEALTHCHECK_URL` | Internal or reachable healthcheck URL for catalog deploy verification |
| `CART_HEALTHCHECK_URL` | Internal or reachable healthcheck URL for cart deploy verification |
| `CHECKOUT_HEALTHCHECK_URL` | Internal or reachable healthcheck URL for checkout deploy verification |
| `ORDERS_HEALTHCHECK_URL` | Internal or reachable healthcheck URL for orders deploy verification |

Optional quality-control variables:

- `UI_EXPECT_SUBSTRING`
- `CATALOG_HEALTHCHECK_EXPECTED_SUBSTRING`
- `CART_HEALTHCHECK_EXPECTED_SUBSTRING`
- `CHECKOUT_HEALTHCHECK_EXPECTED_SUBSTRING`
- `ORDERS_HEALTHCHECK_EXPECTED_SUBSTRING`
- `SMOKE_RETRIES`
- `SMOKE_RETRY_DELAY_SECONDS`
- `MAX_CRITICAL_FINDINGS`
- `MAX_HIGH_FINDINGS`
- `IMAGE_SCAN_RETRIES`
- `IMAGE_SCAN_DELAY_SECONDS`

Optional repository-level CI variables:

- `CI_MAX_CRITICAL_FINDINGS`
- `CI_MAX_HIGH_FINDINGS`
- `TRIVY_SEVERITIES`
- `TRIVY_IGNORE_UNFIXED`

Suggested mapping source:

- ECS cluster name: `terraform output ecs_cluster_name`
- ECS service names: `terraform output ecs_service_names`
- task definition families: `terraform output ecs_task_definition_families`
- ECR repository URLs: `terraform output ecr_repository_urls`
- ALB URL: `terraform output application_url`
- custom domain: `terraform output custom_domain_name`

## GitHub Actions workflows

Workflow inventory:

| Workflow | Purpose |
| --- | --- |
| `.github/workflows/ci.yml` | Validates shared-root Terraform, builds selected upstream service images, and enforces Trivy policy gates with SARIF output |
| `.github/workflows/terraform-plan.yml` | Always validates Terraform, and on manual runs creates an environment-specific plan for `dev`, `stage`, or `prod` |
| `.github/workflows/deploy-ui.yml` | Auto-deploys UI to `dev` on `main`, and manually promotes UI to `stage` or `prod` through GitHub Environments |
| `.github/workflows/deploy-services.yml` | Manually deploys one backend service at a time to `dev`, `stage`, or `prod` with the same rolling deploy safety model |

Deployment behavior follows the Medium article:

- rolling deployment
- `desiredCount >= 2`
- `minimumHealthyPercent >= 100`
- `maximumPercent >= 200`
- deployment circuit breaker enabled
- rollback enabled
- smoke test after steady state

This repository intentionally does not default to blue/green or canary. The baseline approach is ECS rolling deployment with health checks and rollback.

Additional release controls:

- scoped GitHub OIDC deploy role per environment
- Trivy CI gate before promotion workflows run
- image vulnerability gate before ECS rollout
- explicit prod confirmation and change reference input
- immutable promotion by image tag and digest

## AWS OIDC setup

Minimum GitHub-to-AWS trust flow:

1. Create an IAM OIDC identity provider for GitHub.
2. Create an IAM role for deployments.
3. Restrict trust policy by repository and branch.
4. Store the role ARN as `AWS_DEPLOY_ROLE_ARN` in each GitHub Environment.

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
8. Create GitHub Environments named `dev`, `stage`, and `prod`.
9. Add `AWS_DEPLOY_ROLE_ARN` secret and the listed variables to each environment.
10. Run `scripts/sync-github-environment-vars.sh <env> --apply`.
11. Run `terraform-plan.yml` for the target environment.
12. Push to `main` for automatic `dev` UI deployment, or run `deploy-ui.yml` manually for `stage` or `prod`.
13. For `prod`, provide `change_reference` and `confirm_production_release=prod-release`.
14. Promote only previously validated `image_tag` values.
15. Run `deploy-services.yml` for `catalog`, `cart`, `checkout`, and optionally `orders` in the selected environment.
16. Confirm the ALB URL and run smoke validation.

## Smoke test and operations

Available helper script:

- [scripts/smoke-test.sh](/Users/hakan/ecs-retail/scripts/smoke-test.sh:1)
- [scripts/check-ecr-scan.sh](/Users/hakan/ecs-retail/scripts/check-ecr-scan.sh:1)
- [scripts/check-trivy-report.sh](/Users/hakan/ecs-retail/scripts/check-trivy-report.sh:1)
- [scripts/preflight-prod-cutover.sh](/Users/hakan/ecs-retail/scripts/preflight-prod-cutover.sh:1)
- [scripts/list-ecs-events.sh](/Users/hakan/ecs-retail/scripts/list-ecs-events.sh:1)
- [scripts/rollback-service.sh](/Users/hakan/ecs-retail/scripts/rollback-service.sh:1)
- [scripts/cleanup.sh](/Users/hakan/ecs-retail/scripts/cleanup.sh:1)
- [scripts/sync-github-environment-vars.sh](/Users/hakan/ecs-retail/scripts/sync-github-environment-vars.sh:1)

Current smoke test expectation:

- verifies the public UI URL is reachable
- retries before failing
- can optionally verify backend healthcheck URLs when provided
- can optionally validate expected response substrings per endpoint
- CI now gates container images with Trivy before merge or `main` continuation
- release workflows also gate on ECR image scan findings

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
- Trivy CI gate with SARIF upload
- ECR scan on push
- optional WAF
- optional VPC endpoints
- Terraform remote state in private S3 bucket with versioning and encryption

Remaining hardening candidates:

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
- workflow deploy steps still require Terraform outputs to be copied into GitHub Environment variables
- smoke testing is still minimal and UI-focused
- service-specific health endpoint tuning may still need refinement against the selected upstream revision

## Medium article link

Public repository for the article:

- <https://github.com/hakanbayraktar/ecs-fargate-retail-sample-production>
