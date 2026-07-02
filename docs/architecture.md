# Architecture

## Summary

The stack is designed around a public entry point for the `ui` service and private east-west traffic for all backend services.

## Diagram placeholder

```mermaid
flowchart TD
  User[Internet User] --> ALB[Public Application Load Balancer]
  ALB --> UI[ECS Fargate Service: ui]
  UI --> Catalog[ECS Fargate Service: catalog]
  UI --> Cart[ECS Fargate Service: cart]
  UI --> Checkout[ECS Fargate Service: checkout]
  Checkout --> Orders[ECS Fargate Service: orders]
  Catalog --> DDB[(DynamoDB)]
  Cart --> DDB
  Checkout --> Redis[(ElastiCache Redis)]
  Orders --> RDS[(RDS MariaDB)]
  UI --> CW[CloudWatch Logs]
  Catalog --> CW
  Cart --> CW
  Checkout --> CW
  Orders --> CW
```

## Network model

- ALB in public subnets
- ECS tasks in private subnets
- no public IPs on tasks
- internal services reachable only through private networking
- optional Cloud Map namespace for service discovery

## Deployment model

- one ECS service per application component
- one task definition per component
- immutable image tags derived from Git SHA
- circuit breaker rollback enabled

