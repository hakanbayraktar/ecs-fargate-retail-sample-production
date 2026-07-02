# Cost Optimization

## Defaults

- `enable_full_stack = false`
- `enable_rds = false`
- `enable_elasticache = false`
- small dev CPU and memory reservations
- `log_retention_days = 7` in dev
- `enable_fargate_spot = false` until non-critical services are identified

## Main cost levers

- Fargate task size and desired counts
- NAT gateway usage
- CloudWatch retention
- ECR image retention
- DynamoDB on-demand vs provisioned throughput
- optional RDS and ElastiCache capacity

## Guidance

- use a single NAT gateway in dev
- consider VPC endpoints before scaling data transfer
- use Fargate Spot only for tolerant internal workloads
- keep dev image retention low
- prefer DynamoDB for simpler, lower-ops MVP persistence

## Environment strategy

- `dev`: minimum size, short retention, MVP only
- `stage`: mirror production topology where practical
- `prod`: higher desired counts, longer retention, stricter protections

