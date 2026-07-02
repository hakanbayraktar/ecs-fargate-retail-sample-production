# ecs-fargate-retail-sample-production

Production-oriented AWS ECS Fargate reference repository for the AWS Containers Retail Sample App. This repository does not rewrite the upstream application; it defines the infrastructure, delivery workflows, runbooks, and guardrails required to deploy a selected subset of services on ECS Fargate with cost-conscious defaults.

> This project creates AWS resources that may incur cost. Use the MVP mode first and destroy resources after testing.

## Why this project exists

The upstream retail sample is useful for learning microservices, but it is intentionally broad. This repository narrows the scope to a practical ECS Fargate deployment pattern with:

- reproducible Terraform environments
- service-per-task ECS deployment units
- public ALB for the UI only
- internal-only backend services
- GitHub Actions with AWS OIDC
- security and cost-aware defaults
- troubleshooting and operational runbooks

## Upstream attribution

The application reference is the AWS Containers Retail Sample App:

- Upstream project: <https://github.com/aws-containers/retail-store-sample-app>
- Attribution details: [docs/original-app-attribution.md](/Users/hakan/ecs-retail/docs/original-app-attribution.md:1)
- Local integration notes: [app/upstream.md](/Users/hakan/ecs-retail/app/upstream.md:1)

This repository keeps the application layer separate and focuses on productionizing deployment on AWS.

## Architecture summary

- Public traffic enters through an internet-facing Application Load Balancer.
- Only the `ui` service is attached to the public ALB.
- ECS tasks run on Fargate in private subnets without public IP addresses.
- Internal services communicate over private networking and optional Cloud Map service discovery.
- Container images are published to Amazon ECR with immutable Git SHA tags.
- Logs are centralized in CloudWatch Logs with short retention in dev and longer retention in higher environments.

Architecture notes and a diagram placeholder live in [docs/architecture.md](/Users/hakan/ecs-retail/docs/architecture.md:1).

## MVP mode vs full mode

`MVP mode` is the default:

- `ui`
- `catalog`
- `cart`
- `checkout`
- DynamoDB enabled
- RDS disabled
- ElastiCache disabled
- lower cost defaults

`Full mode` extends the stack with:

- `orders`
- optional ElastiCache
- optional MariaDB / RDS
- optional service discovery for richer internal routing

Primary toggles:

- `enable_full_stack = false`
- `enable_rds = false`
- `enable_elasticache = false`
- `enable_dynamodb = true`
- `enable_service_discovery = true`
- `enable_fargate_spot = false`

## Repository layout

```text
.
├── app/
├── docs/
├── scripts/
├── terraform/
└── .github/workflows/
```

## Prerequisites

- AWS account with permission to create ECS, ECR, VPC, IAM, ALB, CloudWatch, DynamoDB, and optional RDS/ElastiCache resources
- Terraform `>= 1.6`
- AWS CLI v2
- Docker
- GitHub repository admin access for Actions OIDC setup

## AWS services used

- Amazon ECS with AWS Fargate
- Amazon ECR
- Application Load Balancer
- Amazon VPC
- IAM
- CloudWatch Logs and Alarms
- Application Auto Scaling
- AWS Secrets Manager
- Amazon DynamoDB
- Amazon ElastiCache for Redis
- Amazon RDS for MariaDB
- AWS Cloud Map

## Local run instructions

This repository keeps the application source separate. To run locally:

1. Clone the upstream app into `app/upstream/retail-store-sample-app`.
2. Review [app/upstream.md](/Users/hakan/ecs-retail/app/upstream.md:1) for the expected integration model.
3. Use [app/docker-compose.local.yml](/Users/hakan/ecs-retail/app/docker-compose.local.yml:1) as a local adapter and adjust service build paths to match the pinned upstream commit if needed.

## Terraform bootstrap

1. Create the remote state bucket from `terraform/bootstrap/remote-state`.
2. Update `terraform/envs/dev/backend.hcl` or `terraform/envs/prod/backend.hcl` with the real S3 bucket name.
3. Adjust the matching environment tfvars file.
4. Initialize and apply from the shared root:

   ```bash
   cd terraform
   terraform init -backend-config=envs/dev/backend.hcl
   terraform plan -var-file=envs/dev/dev.tfvars
   terraform apply -var-file=envs/dev/dev.tfvars
   ```

## Deployment steps

1. Provision infrastructure with Terraform.
2. Create the ECR repositories returned in Terraform outputs.
3. Configure GitHub Actions variables and secrets described in [docs/deployment.md](/Users/hakan/ecs-retail/docs/deployment.md:1).
4. Trigger `deploy-ui.yml` to publish the UI and update ECS.
5. Trigger `deploy-services.yml` for backend services individually.
6. Run the smoke test script against the ALB DNS name.

## GitHub Actions OIDC setup

The workflows are designed for short-lived AWS credentials through GitHub Actions OIDC, not static keys. Configure:

- an IAM role trusted by GitHub OIDC
- repository variables for cluster, service, and ECR identifiers
- optional environment protection rules for `stage` and `prod`

Details: [docs/security.md](/Users/hakan/ecs-retail/docs/security.md:1)

## CI/CD workflows

- `ci.yml`: structural checks, upstream image builds, and shared-root Terraform fmt/validate
- `terraform-plan.yml`: shared-root Terraform plan using `dev` or `prod` tfvars
- `deploy-ui.yml`: build, scan, push, deploy UI, wait for stability, smoke test
- `deploy-services.yml`: manually deploy a selected backend service

## Zero-downtime deployment approach

- ECS rolling deployments
- deployment circuit breaker with rollback
- `minimum_healthy_percent` and `maximum_percent` set per service
- public UI desired count defaults to `2`
- ALB health checks and deregistration delay
- smoke tests after deploy

Operational details: [docs/runbook.md](/Users/hakan/ecs-retail/docs/runbook.md:1)

## Security notes

- no long-lived AWS keys in GitHub
- separate ECS task execution role and service task roles
- optional Secrets Manager integration for application configuration
- immutable image tags based on Git SHA
- ECR image scanning and lifecycle retention

## Cost optimization notes

- dev defaults keep optional services disabled
- single NAT gateway by default
- short log retention in dev
- Fargate Spot kept optional
- ECR lifecycle policy retains a limited number of images

See [docs/cost-optimization.md](/Users/hakan/ecs-retail/docs/cost-optimization.md:1).

## Troubleshooting and cleanup

- Troubleshooting guide: [docs/troubleshooting.md](/Users/hakan/ecs-retail/docs/troubleshooting.md:1)
- Operations runbook: [docs/runbook.md](/Users/hakan/ecs-retail/docs/runbook.md:1)
- Cleanup helper: [scripts/cleanup.sh](/Users/hakan/ecs-retail/scripts/cleanup.sh:1)

## Setup before deployment

Configure these items before the first deploy:

- `terraform/envs/<env>/<env>.tfvars`
- `terraform/envs/<env>/backend.hcl`
- GitHub repository variables for AWS region, ECS cluster, ECS service names, and ECR repositories
- GitHub secret `AWS_DEPLOY_ROLE_ARN`
- optional secret values for application configuration
- optional ACM certificate ARN for HTTPS

## AWS resources created

The Terraform stack provisions:

- VPC, public subnets, private subnets, route tables, and NAT
- security groups
- ECS cluster
- ECR repositories
- ALB, listeners, and target groups
- ECS task definitions and services
- CloudWatch log groups and alarms
- Application Auto Scaling targets and policies
- optional DynamoDB, ElastiCache, RDS, Cloud Map, and Secrets Manager resources

## Estimated cost considerations

Primary cost drivers are:

- Fargate task runtime and desired counts
- NAT gateway hourly and data processing charges
- ALB hourly and LCU usage
- CloudWatch log ingestion and retention
- optional RDS and ElastiCache instances

Use MVP mode in `dev` first.

## Known limitations

- This repository does not vendor the upstream application code.
- Docker build contexts for application services must be aligned with the pinned upstream checkout.
- Service-specific health endpoints may need adjustment after selecting the exact upstream commit.

## Next improvements

- add service-specific task definition JSON snapshots for workflow-based deployments
- add environment-specific remote Terraform state backend examples
- add integration tests against ephemeral preview environments
- add blue/green deployment option with CodeDeploy for stricter cutovers

## CV bullet example

Built a production-oriented AWS ECS Fargate deployment platform for a multi-service retail sample using Terraform, GitHub Actions OIDC, ECR, ALB, CloudWatch, autoscaling, and operational runbooks.

## Medium article placeholder

Add a project write-up link here after publication.
