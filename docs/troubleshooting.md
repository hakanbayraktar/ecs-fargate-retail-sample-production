# Troubleshooting

## ECS task keeps restarting

- Symptom: tasks cycle repeatedly and never stabilize.
- Possible causes: bad image tag, health check failure, missing secret, bad runtime env.
- Where to check: ECS service events, stopped task reason, CloudWatch logs.
- Useful AWS Console pages: ECS Cluster, CloudWatch Logs, ECR.
- Useful AWS CLI commands: `aws ecs describe-services`, `aws ecs describe-tasks`, `aws logs tail`.
- Fix: verify image, env vars, health endpoint, and IAM permissions.
- Production note: capture the failed task definition revision before redeploy.

## ALB returns 503

- Symptom: UI URL responds with `503 Service Unavailable`.
- Possible causes: no healthy targets, wrong health check path, security group mismatch.
- Where to check: target group health, ECS desired vs running count, ALB listener rules.
- Useful AWS Console pages: EC2 Target Groups, ECS Services, CloudWatch Metrics.
- Useful AWS CLI commands: `aws elbv2 describe-target-health`, `aws ecs describe-services`.
- Fix: align target port and path, confirm ALB-to-task ingress, verify app readiness.
- Production note: do not change multiple network controls at once during incident response.

## Target group unhealthy

- Symptom: targets register but stay unhealthy.
- Possible causes: container port mismatch, app boot delay, wrong health path.
- Where to check: ECS task definition port mappings and target group settings.
- Useful AWS CLI commands: `aws ecs describe-task-definition`, `aws elbv2 describe-target-groups`.
- Fix: correct port mappings, add grace period, raise startup timeout if needed.
- Production note: keep health checks simple and deterministic.

## UI cannot reach backend service

- Symptom: UI is up but backend calls fail.
- Possible causes: service discovery disabled, DNS mismatch, backend security groups too strict.
- Where to check: UI logs, backend service status, Cloud Map namespace.
- Useful AWS CLI commands: `aws servicediscovery list-services`, `aws ecs execute-command`.
- Fix: confirm backend endpoint env vars and private networking rules.
- Production note: keep service names stable across environments.

## Checkout service fails

- Symptom: checkout requests return 5xx or time out.
- Possible causes: orders dependency unavailable, Redis missing, bad secret or env.
- Where to check: checkout logs, dependency health, task events.
- Useful AWS CLI commands: `aws ecs describe-services`, `aws logs tail`.
- Fix: verify downstream endpoints and optional data store toggles.
- Production note: keep `enable_full_stack` and dependency flags aligned.

## Catalog API unavailable

- Symptom: product listing fails.
- Possible causes: DynamoDB table missing, IAM denied, bad container revision.
- Where to check: catalog logs, DynamoDB tables, task role permissions.
- Useful AWS CLI commands: `aws dynamodb list-tables`, `aws iam simulate-principal-policy`.
- Fix: validate table names, task role access, and image health.
- Production note: prefer explicit table outputs wired into ECS env vars.

## Cart persistence backend unavailable

- Symptom: cart requests fail or are inconsistent.
- Possible causes: DynamoDB or Redis disabled unexpectedly, config drift.
- Where to check: cart logs and Terraform variable set for the environment.
- Useful AWS CLI commands: `aws dynamodb describe-table`, `aws elasticache describe-replication-groups`.
- Fix: align feature flags with deployed dependencies.
- Production note: do not enable cache-backed code paths without the backing service.

## Image pull error

- Symptom: tasks stop with image pull failures.
- Possible causes: image tag missing, ECR permission issue, wrong repository URI.
- Where to check: stopped task reason, ECR repository, execution role policy.
- Useful AWS CLI commands: `aws ecr describe-images`, `aws ecs describe-tasks`.
- Fix: push the image, confirm repository URI, and verify execution role permissions.
- Production note: never use `latest`; deploy a known Git SHA.

## Secret cannot be read

- Symptom: task launches fail or app exits on startup.
- Possible causes: missing secret ARN, bad task role permission, malformed secret contents.
- Where to check: ECS task definition secrets block, Secrets Manager, task role.
- Useful AWS CLI commands: `aws secretsmanager describe-secret`, `aws iam get-role-policy`.
- Fix: grant precise secret access and validate key names.
- Production note: rotate secrets with staged rollout, not a blind overwrite.

## Deployment stuck

- Symptom: service never reaches steady state.
- Possible causes: unhealthy revision, insufficient capacity, bad network route, app deadlock.
- Where to check: ECS service events and CloudWatch metrics.
- Useful AWS CLI commands: `aws ecs wait services-stable`, `aws ecs describe-services`.
- Fix: inspect the new revision, roll back if necessary, then re-run smoke tests.
- Production note: record the exact task definition revision involved.

## High latency

- Symptom: response times increase without full outage.
- Possible causes: CPU throttling, slow downstream calls, NAT egress contention.
- Where to check: ECS CPU and memory metrics, ALB target response time.
- Useful AWS CLI commands: `aws cloudwatch get-metric-statistics`.
- Fix: right-size tasks, reduce cross-service hops, check dependency saturation.
- Production note: scale only after ruling out code-path regressions.

## High 5xx error rate

- Symptom: ALB or service-level 5xx alarms fire.
- Possible causes: failed rollout, downstream dependency outage, secret/config drift.
- Where to check: ALB metrics, ECS events, service logs.
- Useful AWS CLI commands: `aws cloudwatch describe-alarms`, `aws logs tail`.
- Fix: stabilize the failing service, then roll back if the new revision is implicated.
- Production note: keep rollback procedures rehearsed.

## NAT gateway or private subnet egress issue

- Symptom: tasks cannot reach ECR, public APIs, or package mirrors.
- Possible causes: bad route table, NAT unavailable, subnet association drift.
- Where to check: VPC routes, NAT gateway status, subnet route associations.
- Useful AWS CLI commands: `aws ec2 describe-route-tables`, `aws ec2 describe-nat-gateways`.
- Fix: repair routes and confirm private subnet associations.
- Production note: VPC endpoints can reduce NAT dependency for AWS service traffic.

## Terraform state lock issue

- Symptom: `terraform apply` fails with a state lock error.
- Possible causes: stale lock, concurrent pipeline run, interrupted apply.
- Where to check: backend state system and CI job history.
- Useful commands: `terraform force-unlock`, backend-specific inspection tooling.
- Fix: confirm no active run exists before unlocking.
- Production note: protect production state with remote backend locking.

## GitHub Actions deployment failed

- Symptom: deploy workflow exits before ECS update.
- Possible causes: OIDC trust mismatch, missing repository variable, Docker build path mismatch.
- Where to check: workflow logs, IAM trust policy, repository settings.
- Useful commands: `gh run view`, `aws sts get-caller-identity`.
- Fix: correct role trust, verify inputs, and re-run with the same Git SHA.
- Production note: keep environment variables documented and versioned.

