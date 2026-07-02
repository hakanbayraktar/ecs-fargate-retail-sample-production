# Security

## Core controls

- GitHub Actions uses OIDC and assumes an AWS IAM role
- ECS task execution role is separated from service task roles
- application secrets are designed to come from AWS Secrets Manager
- backend services are not exposed to the internet
- immutable image tagging avoids ambiguous rollbacks

## IAM design

- one execution role for ECS image pull and log publishing
- one task role per service for least privilege extension
- one GitHub deploy role for CI/CD

## Secret handling

- never hardcode secrets in Terraform or workflow files
- keep secret material in AWS Secrets Manager
- inject only required keys into task definitions

## Recommended next controls

- add WAF in front of the ALB for public environments
- use ACM and HTTPS-only listeners
- enable runtime threat detection and GuardDuty where appropriate

