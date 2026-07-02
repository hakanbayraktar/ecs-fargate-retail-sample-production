Production-Ready ECS Fargate Retail Sample Project Prompt

You are a senior DevOps / Platform Engineer.

Create a complete production-ready GitHub repository named:

ecs-fargate-retail-sample-production

Goal:

Take the AWS Containers Retail Sample App as the base application and create a production-oriented ECS Fargate deployment project using Terraform, GitHub Actions, Amazon ECR, Application Load Balancer, IAM, CloudWatch, Auto Scaling, zero-downtime deployment strategy, security hardening, cost optimization and troubleshooting runbooks.

Base application:

Use AWS Containers Retail Sample App as the application reference:

<https://github.com/aws-containers/retail-store-sample-app>

This sample app includes a retail store application with product catalog, shopping cart, orders and checkout components. It supports Docker Compose and Kubernetes and includes multiple components and persistence backend options.

Important:

Do not simply copy the original repository blindly.

Create a clean DevOps-focused repository that either:

Uses the upstream retail sample app as a Git submodule, or
Documents how to clone/build selected components from the upstream app, or
Includes only the minimum selected components needed for ECS Fargate deployment, while clearly preserving attribution and license information.

The goal is not to rewrite the application. The goal is to productionize its deployment on AWS ECS Fargate.

Repository structure:

ecs-fargate-retail-sample-production/
├── app/
│ ├── README.md
│ ├── upstream.md
│ └── docker-compose.local.yml
├── terraform/
│ ├── modules/
│ │ ├── vpc/
│ │ ├── security-groups/
│ │ ├── ecr/
│ │ ├── iam/
│ │ ├── alb/
│ │ ├── ecs-cluster/
│ │ ├── ecs-service/
│ │ ├── service-discovery/
│ │ ├── secrets/
│ │ ├── autoscaling/
│ │ ├── cloudwatch/
│ │ ├── dynamodb/
│ │ ├── elasticache/
│ │ └── rds/
│ └── envs/
│ ├── dev/
│ ├── stage/
│ └── prod/
├── .github/
│ └── workflows/
│ ├── ci.yml
│ ├── deploy-ui.yml
│ ├── deploy-services.yml
│ └── terraform-plan.yml
├── docs/
│ ├── architecture.md
│ ├── application.md
│ ├── deployment.md
│ ├── security.md
│ ├── cost-optimization.md
│ ├── troubleshooting.md
│ ├── runbook.md
│ └── original-app-attribution.md
├── scripts/
│ ├── smoke-test.sh
│ ├── rollback-service.sh
│ ├── list-ecs-events.sh
│ └── cleanup.sh
└── README.md

Application scope:

Use these services from the retail sample app:

UI service
Catalog service
Cart service
Checkout service
Orders service if practical

Create an MVP mode and full mode.

MVP mode:

UI
Catalog
Cart
Checkout
Minimal dependencies
Lower AWS cost
Suitable for tutorial deployment

Full mode:

UI
Catalog
Cart
Checkout
Orders
Redis or ElastiCache
DynamoDB
Optional RDS/MariaDB
Optional service discovery

Terraform variables:

enable_full_stack = false
enable_rds = false
enable_elasticache = false
enable_dynamodb = true
enable_service_discovery = true
enable_fargate_spot = false

Default should be cost-conscious.

Infrastructure requirements:

Terraform must create:

VPC
Public subnets
Private subnets
Internet Gateway
NAT Gateway or optional VPC endpoints
Route tables
Security groups
Amazon ECR repositories for selected services
ECS cluster
ECS Fargate services for selected app components
Task definitions
Application Load Balancer
Target groups
ALB listeners
IAM Task Execution Role
IAM Task Roles per service
CloudWatch log groups
CloudWatch alarms
ECS service auto scaling
Optional DynamoDB tables
Optional ElastiCache Redis
Optional RDS/MariaDB
Optional Cloud Map service discovery

Networking requirements:

ALB must be public.
ECS tasks must run in private subnets.
ECS tasks must not have public IPs.
ALB security group allows inbound 80/443.
ECS service security groups allow inbound only from ALB or required internal service security groups.
Internal services should not be publicly exposed.
Only UI should be reachable from public ALB.
Backend services should be reachable internally.
Add service discovery or internal ALB pattern if needed.

ECS requirements:

Use Fargate launch type.
Use separate ECS services for UI, catalog, cart, checkout and orders where applicable.
Use separate task definitions per service.
Use separate CloudWatch log groups per service.
Use health checks per service.
Use deployment circuit breaker with rollback enabled.
Configure minimum_healthy_percent and maximum_percent.
Default desired count should be 2 for public-facing services.
Configure auto scaling policies.
Use Git SHA image tags.
Do not use latest tag.

CI/CD requirements:

Create GitHub Actions workflows.

ci.yml:

Validate repository structure
Run lint/test if available
Build selected service images
Run Trivy image scan
Do not deploy

terraform-plan.yml:

Run terraform fmt
Run terraform validate
Run terraform plan
Optional Checkov scan
Optional Infracost comment placeholder

deploy-ui.yml:

Use GitHub Actions OIDC to assume AWS role
Login to Amazon ECR
Build UI image
Tag image with Git SHA
Push image to ECR
Update ECS task definition
Deploy UI service
Wait for service stability
Run smoke test

deploy-services.yml:

Similar flow for backend services
Allow manual workflow_dispatch
Support service name input
Deploy selected service only

Security requirements:

Use GitHub Actions OIDC, not long-lived AWS keys
Use least privilege IAM roles
Separate Task Execution Role and Task Role
Use service-specific Task Roles where possible
Use Secrets Manager for application secrets
Do not hardcode secrets
Add ECR image scanning
Add CloudWatch log retention
Add documentation for IAM role design
Add attribution and license reference for the upstream AWS sample app

Zero-downtime deployment requirements:

Implement and document:

ECS rolling deployment
desired count >= 2
minimum healthy percent
maximum percent
ALB health checks
health check grace period
deregistration delay
deployment circuit breaker
rollback strategy
smoke tests after deployment

Cost optimization requirements:

Add cost-conscious defaults:

enable_full_stack = false
enable_rds = false
small Fargate CPU/memory values for dev
log_retention_days = 7 for dev
optional Fargate Spot for non-critical services
optional VPC endpoints
ECR lifecycle policy
clear cleanup instructions

Add docs/cost-optimization.md explaining:

Fargate sizing
Fargate Spot
NAT Gateway cost
VPC endpoints
CloudWatch log retention
ECR lifecycle
dev/stage/prod capacity differences
DynamoDB vs RDS cost tradeoff
ElastiCache cost awareness

Troubleshooting documentation:

Add docs/troubleshooting.md with scenarios:

ECS task keeps restarting
ALB returns 503
Target group unhealthy
UI cannot reach backend service
Checkout service fails
Catalog API unavailable
Cart persistence backend unavailable
Image pull error
Secret cannot be read
Deployment stuck
High latency
High 5xx error rate
NAT Gateway or private subnet egress issue
Terraform state lock issue
GitHub Actions deployment failed

For each scenario include:

Symptom
Possible causes
Where to check
Useful AWS Console pages
Useful AWS CLI commands
Fix
Production note

Runbook requirements:

Add docs/runbook.md with:

Deployment failed runbook
ALB 5xx increase runbook
ECS service unhealthy runbook
Backend dependency failure runbook
Rollback runbook
Secret rotation runbook
CPU or memory spike runbook
Cost spike runbook
Cleanup runbook

README requirements:

Root README.md must include:

Project overview
Why this project exists
Upstream application attribution
Architecture summary
Architecture diagram placeholder
MVP mode vs full mode
Prerequisites
AWS services used
Estimated cost warning
Local run instructions
Terraform bootstrap steps
Deployment steps
GitHub Actions OIDC setup
CI/CD workflow explanation
Zero-downtime deployment explanation
Security notes
Cost optimization notes
Troubleshooting links
Cleanup instructions
CV bullet example
Medium article link placeholder

Add this warning:

This project creates AWS resources that may incur cost. Use the MVP mode first and destroy resources after testing.

Acceptance criteria:

The final repository must allow a user to:

Understand the upstream retail sample app.
Run the app locally or understand how to run it locally.
Build selected service images.
Push selected images to ECR.
Create ECS Fargate infrastructure with Terraform.
Deploy UI and backend services to ECS Fargate.
Access the UI through ALB.
View logs in CloudWatch.
Trigger deployments from GitHub Actions.
Understand zero-downtime deployment behavior.
Troubleshoot common ECS Fargate issues.
Clean up AWS resources after testing.

Output:

Create all files and folders.

At the end, provide:

Repository summary
File tree
Setup steps
What to configure before deployment
AWS resources created
Estimated cost considerations
Known limitations
Next improvements

Do not ask unnecessary questions. Make reasonable production-ready defaults and document assumptions.
