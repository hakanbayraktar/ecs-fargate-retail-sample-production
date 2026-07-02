# Sprint 1

Sprint 1 establishes the production-ready platform baseline around the upstream retail sample application.

## Sprint goal

Create a deployable and understandable foundation that matches the Medium article:

- shared Terraform code
- environment split by tfvars
- secure ECS Fargate networking
- GitHub Actions OIDC deployment flow
- rolling deployment with rollback
- operator-grade documentation

## Sprint scope

- shared Terraform root under `terraform/`
- `dev` and `prod` separation through `envs/*/*.tfvars`
- S3 remote backend with native lockfile
- modular Terraform layout with `main.tf`, `variables.tf`, `outputs.tf`, and reusable modules
- deploy workflows for UI and backend services
- README expanded into installation and operations guide

## Sprint deliverables

- validated Terraform root
- remote-state bootstrap stack
- `ci.yml`
- `terraform-plan.yml`
- `deploy-ui.yml`
- `deploy-services.yml`
- application and deployment documentation

## Done criteria

- `terraform fmt` passes
- `terraform validate` passes
- `dev` and `prod` can use the same Terraform root
- GitHub repository variables and secret requirements are documented
- zero-downtime deploy flow is documented and implemented in workflows
- README covers architecture, setup, deployment, and operational basics

## Out of scope

- blue/green deployment
- canary rollout
- full automated integration test suite
- Infracost / Checkov / Slack notification integration
- complete production observability dashboarding
