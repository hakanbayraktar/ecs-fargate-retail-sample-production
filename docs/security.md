# Security

This repository follows the Medium article's core security model:

- private ECS tasks
- public ALB only
- least privilege IAM
- task execution role and task role separation
- secrets from AWS Secrets Manager
- immutable images
- encrypted state and data paths

## Security architecture

The intended request path is:

1. users reach the public ALB
2. only the `ui` ECS service receives internet traffic
3. backend services stay private inside the VPC
4. ECS tasks pull images, write logs, and read startup secrets using the task execution role
5. application containers access AWS services only through their own task role

This model prevents the most common ECS anti-patterns:

- public IP on application tasks
- broad IAM permissions on all services
- long-lived AWS credentials in GitHub
- secrets embedded in Dockerfiles or plaintext env files

## Network isolation

Security boundaries in the Terraform design:

- public subnets: ALB only
- private subnets: ECS services, optional RDS, optional ElastiCache
- no public IP assignment for ECS tasks
- UI security group allows traffic only from the ALB security group
- backend security group allows traffic from UI and approved internal east-west service flows
- database and cache security groups accept traffic only from backend service security groups

Recommended production posture:

- enable HTTPS with ACM
- enable WAF for public environments
- enable VPC endpoints for ECR, Logs, Secrets Manager, and KMS in higher environments
- reduce NAT dependency for AWS service traffic where cost and security justify it

## IAM role separation

### Task execution role

Purpose:

- pull images from ECR
- publish logs to CloudWatch Logs
- read startup secrets referenced in ECS task definitions

This role exists for ECS and Fargate platform operations, not for application business logic.

Expected permissions:

- `ecr:GetAuthorizationToken`
- ECR image pull permissions
- CloudWatch Logs write permissions
- `secretsmanager:GetSecretValue` for startup secrets

### Task role

Purpose:

- allow the running application container to access AWS APIs it actually needs

Examples in this repository:

- cart service access to DynamoDB
- optional future access to S3, SQS, SNS, or KMS only when required

This role should remain service-specific. Do not use one broad shared application role for every service.

## GitHub Actions security

Deploy workflows use AWS OIDC, not static AWS keys.

Required pattern:

1. GitHub Actions requests an OIDC token
2. AWS IAM trust policy validates repository and branch conditions
3. GitHub assumes the deploy role temporarily
4. workflow performs ECR push and ECS deploy actions

Benefits:

- no long-lived access keys in GitHub secrets
- short-lived credentials
- explicit trust boundaries by repo and branch
- better auditability in AWS CloudTrail

Minimum GitHub secret:

- `AWS_DEPLOY_ROLE_ARN`

## Secrets management

Application secrets must not be:

- hardcoded in Terraform variables committed to git
- written into Docker images
- stored as plain repository variables

Expected path:

1. secret exists in AWS Secrets Manager
2. ECS task definition references the secret using `valueFrom`
3. task execution role can read the secret
4. container receives the secret at startup as an environment variable

For stateful dependencies:

- RDS master credentials are managed by AWS where possible
- Terraform passes secret references rather than plaintext values into workloads

## Image security

Repository expectations:

- immutable image tagging using Git SHA
- no `latest` tag in deploy workflows
- ECR scan on push enabled
- ECR lifecycle policy to reduce stale image sprawl

Recommended next additions:

- Trivy in CI
- Inspector integration
- signed image / provenance strategy if organizationally required

## Encryption

Current encryption expectations:

- Terraform remote state bucket encryption
- S3 public access block on the remote state bucket
- ECR encryption at rest
- DynamoDB server-side encryption
- RDS storage encryption
- ElastiCache at-rest encryption where supported

Production follow-up:

- ensure ACM is used for public HTTPS
- consider KMS customer-managed keys where stricter control is required

## Least privilege checklist

- each ECS service has only the IAM permissions it needs
- deploy role can update ECS and ECR but is not an unrestricted admin role
- security groups expose only required ports
- backend services remain private
- secrets are fetched at runtime, not committed
- logs never intentionally print sensitive values

## Production hardening backlog

- tighten deploy role resource scoping further
- add WAF by default in prod
- enforce HTTPS-only public entry
- evaluate GuardDuty, Security Hub, and Inspector
- add Config / CloudTrail governance if this becomes a real shared platform

