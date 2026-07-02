# Runbook

## Deployment failed

- freeze further deploys for the affected service
- inspect the failed workflow and ECS service events
- use `scripts/list-ecs-events.sh <cluster> <service>` for quick ECS event inspection
- compare old and new task definition revisions
- decide between immediate rollback and targeted fix

## ALB 5xx increase

- verify whether the issue is limited to the UI or a backend dependency
- inspect target health and ALB 5xx metrics
- roll back UI if the incident started with a fresh deploy

## ECS service unhealthy

- inspect stopped task reasons and CloudWatch logs
- verify security groups, image tag, and health command
- re-enable steady traffic only after target health recovers

## Backend dependency failure

- identify the failing dependency: DynamoDB, Redis, RDS, or internal service
- confirm that the matching Terraform feature flag is enabled
- restore dependency health before recycling healthy frontends

## Rollback

- determine the last known-good task definition revision
- update the ECS service to that revision
- wait for service stability
- run smoke tests and confirm ALB target health
- if the failed revision never reaches steady state, rely on ECS deployment circuit breaker first
- if smoke tests fail after steady state, use the previous task definition captured by the deploy workflow
- helper: `scripts/rollback-service.sh <cluster> <service> [task-definition-arn] --wait`

## Secret rotation

- write the new secret value in Secrets Manager
- update the service if secret names or ARN references changed
- force a new deployment when applications only read secrets at startup

## CPU or memory spike

- inspect ECS service metrics and recent deploy history
- scale out first if the service is customer-facing and saturated
- right-size CPU and memory in Terraform after the incident

## Cost spike

- review Fargate runtime, NAT data transfer, log growth, and optional data stores
- disable non-essential environments if necessary
- reduce retention and desired counts where safe

## Cleanup

- drain or delete ECS services if needed
- run `scripts/cleanup.sh <env>`
- confirm ECR, logs, and state resources are handled according to retention policy
