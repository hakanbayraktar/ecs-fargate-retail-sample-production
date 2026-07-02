# Project Plan

## Goal

Productionize the AWS Containers retail sample for ECS Fargate with:

- private ECS services
- public ALB for UI only
- shared Terraform root for all environments
- zero-downtime ECS rolling deployments
- GitHub Actions with OIDC
- production-ready security, cost, and operations guidance

## Scope

Application scope:

- `ui`
- `catalog`
- `cart`
- `checkout`
- `orders` for full mode

Platform scope:

- networking
- IAM
- ECR
- ECS cluster and services
- CloudWatch logs and alarms
- service discovery
- DynamoDB
- optional Redis
- optional RDS
- WAF-ready edge posture

## Completed Work

### Foundation

- cloned and adapted the upstream retail sample instead of rebuilding from scratch
- aligned the repository around ECS Fargate deployment requirements
- documented upstream ownership and attribution

### Terraform

- created a shared Terraform root with `main.tf`, `variables.tf`, and `outputs.tf`
- split environments with `dev`, `stage`, and `prod` `tfvars` and `backend.hcl`
- added modular infrastructure layout under `terraform/modules`
- implemented S3 remote backend bootstrap with native lockfile support and no DynamoDB lock table
- kept the same Terraform codebase reusable across environments

### Infrastructure Design

- private ECS tasks with no public IPs
- public ALB for the UI only
- least-privilege security groups
- separate ECS task execution role and task role
- Cloud Map service discovery
- DynamoDB for cart
- optional ElastiCache for checkout
- optional RDS for catalog and orders
- optional WAF integration for prod-grade edge protection

### Deployment and CI/CD

- CI workflow for Terraform validation and selected upstream image builds
- Terraform plan workflow for environment-specific manual planning
- zero-downtime UI deploy workflow with:
  - ECS rolling update checks
  - deployment circuit breaker validation
  - smoke test
  - rollback to previous task definition
- backend deploy workflow with the same rollout safety model
- GitHub Environments based promotion model for `dev`, `stage`, and `prod`
- immutable image-tag promotion flow for `stage` and `prod`
- vulnerability gate on ECR image scan findings before release
- explicit prod confirmation and change-reference guard

### Operations and Documentation

- expanded README for operator onboarding without turning it into a delivery log
- added architecture, security, deployment, runbook, troubleshooting, and cost docs
- added helper scripts for smoke test, rollback, ECS event inspection, and cleanup
- strengthened smoke tests with retries and response validation controls
- added scoped GitHub OIDC deploy role support in Terraform

## Delivery Phases

Current delivery status:

- Phase 1 complete
- Phase 2 complete
- Phase 3 complete
- Phase 4 complete
- Next phase items identified

### Phase 1

Base platform and documentation:

- shared Terraform root
- env separation with `tfvars`
- remote state bootstrap
- initial zero-downtime deploy workflows
- operator documentation

### Phase 2

Environment promotion and release control:

- `dev`, `stage`, `prod` GitHub Environments
- environment-scoped deploy variables and secrets
- safer manual promotion path for `stage` and `prod`
- environment-aware Terraform planning
- helper automation for syncing Terraform outputs into GitHub Environment variables
- immutable promotion of previously built ECR image tags

### Phase 3

Release quality controls:

- smoke test retries
- backend-only smoke mode
- expected response substring validation
- image digest visibility in deployment summaries

### Phase 4

Security and release guardrails:

- scoped GitHub OIDC deploy role per environment
- environment-bound OIDC trust policy
- vulnerability gate on ECR image scan findings
- explicit prod confirmation input
- mandatory prod change reference input

### Next Phase

Recommended follow-up work:

- add optional HTTPS and Route53 production cutover guidance
- add image scanning and policy gates to CI if stricter release control is needed
- evaluate GuardDuty, Security Hub, and Inspector-based continuous findings

## Principles

- infrastructure code must stay shared across environments
- security comes before convenience
- production defaults should favor safety and rollback
- optional components should stay cost-aware in `dev`
- documentation should explain operation, not duplicate project-tracking notes in `README.md`
