# Terraform

This directory contains the shared Terraform root used by both `dev` and `prod`. Environment differences are handled by:

- `terraform/envs/dev/dev.tfvars`
- `terraform/envs/prod/prod.tfvars`
- `terraform/envs/*/backend.hcl`

## Remote backend

The remote backend uses Amazon S3 with native lockfile locking:

- backend type: `s3`
- locking: `use_lockfile = true`
- DynamoDB locking: intentionally not used

This follows current Terraform guidance. HashiCorp documents S3 lockfile support and notes that DynamoDB-based locking is deprecated and scheduled for removal in a future minor release:

- <https://developer.hashicorp.com/terraform/language/backend/s3>

## Bootstrap state bucket

Create the remote state bucket first:

```bash
cd terraform/bootstrap/remote-state
terraform init
terraform apply -var='aws_region=eu-central-1' -var='bucket_name=your-unique-tf-state-bucket'
```

## Init and plan

Dev:

```bash
cd terraform
terraform init -backend-config=envs/dev/backend.hcl
terraform plan -var-file=envs/dev/dev.tfvars
```

Prod:

```bash
cd terraform
terraform init -backend-config=envs/prod/backend.hcl
terraform plan -var-file=envs/prod/prod.tfvars
```

## Architecture intent

- public ALB only
- ECS services in private subnets with no public IP
- separate task execution role and task roles
- private ECR repositories with immutable tags and scan on push
- optional Cloud Map service discovery
- optional WAF
- dev cost profile with single NAT and reduced stateful dependencies
- prod HA profile with per-AZ NAT, Multi-AZ databases, Redis failover, and deletion protection
