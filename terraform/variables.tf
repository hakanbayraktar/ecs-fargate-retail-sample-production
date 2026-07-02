variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment name. Use values such as dev or prod."
  type        = string
}

variable "project_name" {
  description = "Project name prefix for resources."
  type        = string
  default     = "ecs-retail"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "Primary VPC CIDR block."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks. Keep one per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks. Keep one per AZ."
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones to use. Leave empty to auto-select."
  type        = list(string)
  default     = []
}

variable "nat_gateway_mode" {
  description = "NAT gateway strategy. Use single for dev and per_az for HA environments."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be single or per_az."
  }
}

variable "enable_vpc_endpoints" {
  description = "Whether to create private interface and gateway VPC endpoints for AWS services."
  type        = bool
  default     = false
}

variable "vpc_endpoint_services" {
  description = "AWS service short names for interface endpoints. S3 is added as a gateway endpoint automatically."
  type        = set(string)
  default     = ["ecr.api", "ecr.dkr", "logs", "secretsmanager", "kms"]
}

variable "enable_waf" {
  description = "Whether to associate an AWS WAF web ACL with the public ALB."
  type        = bool
  default     = false

  validation {
    condition     = var.environment != "prod" || var.enable_waf
    error_message = "enable_waf must be true for prod."
  }
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS."
  type        = string
  default     = null

  validation {
    condition = (
      var.certificate_arn == null ||
      (
        trim(var.certificate_arn) != "" &&
        var.certificate_arn != "CHANGE_ME"
      )
    )
    error_message = "certificate_arn must be null or a real ACM certificate ARN."
  }

  validation {
    condition = (
      var.environment != "prod" ||
      var.certificate_arn != null
    )
    error_message = "certificate_arn is required for prod."
  }
}

variable "route53_zone_id" {
  description = "Optional public Route53 hosted zone ID for a friendly DNS record."
  type        = string
  default     = null

  validation {
    condition = (
      (var.route53_zone_id == null && var.public_domain_name == null) ||
      (var.route53_zone_id != null && var.public_domain_name != null)
    )
    error_message = "route53_zone_id and public_domain_name must both be set or both be null."
  }

  validation {
    condition = (
      var.route53_zone_id == null ||
      (
        trim(var.route53_zone_id) != "" &&
        var.route53_zone_id != "CHANGE_ME"
      )
    )
    error_message = "route53_zone_id must be null or a real Route53 hosted zone ID."
  }
}

variable "public_domain_name" {
  description = "Optional DNS name to create for the ALB."
  type        = string
  default     = null

  validation {
    condition = (
      var.public_domain_name == null ||
      (
        trim(var.public_domain_name) != "" &&
        var.public_domain_name != "CHANGE_ME"
      )
    )
    error_message = "public_domain_name must be null or a real DNS name."
  }

  validation {
    condition = (
      var.public_domain_name == null ||
      var.certificate_arn != null
    )
    error_message = "certificate_arn is required when public_domain_name is set."
  }

  validation {
    condition = (
      var.environment != "prod" ||
      var.public_domain_name != null
    )
    error_message = "public_domain_name is required for prod."
  }
}

variable "enable_github_actions_deploy_role" {
  description = "Create a scoped GitHub Actions OIDC deploy role for this environment."
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository in owner/name format allowed to assume the deploy role."
  type        = string
  default     = "hakanbayraktar/ecs-fargate-retail-sample-production"
}

variable "github_oidc_provider_arn" {
  description = "Optional GitHub OIDC provider ARN. Leave null to use the account-local token.actions.githubusercontent.com provider ARN."
  type        = string
  default     = null
}

variable "upstream_image_tag" {
  description = "Default upstream image tag for the retail sample public images."
  type        = string
  default     = "1.6.1"
}

variable "container_image_overrides" {
  description = "Optional image overrides keyed by service name."
  type        = map(string)
  default     = {}
}

variable "enable_orders" {
  description = "Deploy the optional orders service."
  type        = bool
  default     = false
}

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map private DNS service discovery."
  type        = bool
  default     = true
}

variable "enable_catalog_database" {
  description = "Enable an RDS MariaDB instance for the catalog service."
  type        = bool
  default     = false
}

variable "enable_checkout_redis" {
  description = "Enable ElastiCache Redis for the checkout service."
  type        = bool
  default     = false
}

variable "enable_orders_database" {
  description = "Enable an RDS PostgreSQL instance for the orders service."
  type        = bool
  default     = false
}

variable "catalog_search_enabled" {
  description = "Enable catalog search mode in the UI and catalog service."
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable ECS container insights."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
  default     = 7
}

variable "ecr_image_retention_count" {
  description = "Number of images kept per ECR repository."
  type        = number
  default     = 30
}

variable "service_desired_counts" {
  description = "Desired task counts per service."
  type        = map(number)
  default = {
    ui       = 2
    catalog  = 2
    cart     = 2
    checkout = 2
    orders   = 2
  }
}

variable "service_min_capacity" {
  description = "Auto scaling minimum task counts per service."
  type        = map(number)
  default = {
    ui       = 2
    catalog  = 2
    cart     = 2
    checkout = 2
    orders   = 2
  }
}

variable "service_max_capacity" {
  description = "Auto scaling maximum task counts per service."
  type        = map(number)
  default = {
    ui       = 4
    catalog  = 4
    cart     = 4
    checkout = 4
    orders   = 4
  }
}

variable "service_cpu" {
  description = "Task CPU per service."
  type        = map(number)
  default = {
    ui       = 512
    catalog  = 512
    cart     = 512
    checkout = 512
    orders   = 512
  }
}

variable "service_memory" {
  description = "Task memory per service in MiB."
  type        = map(number)
  default = {
    ui       = 1024
    catalog  = 1024
    cart     = 1024
    checkout = 1024
    orders   = 1024
  }
}

variable "autoscaling_cpu_target" {
  description = "Target tracking CPU utilization."
  type        = number
  default     = 65
}

variable "autoscaling_memory_target" {
  description = "Target tracking memory utilization."
  type        = number
  default     = 75
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent for ECS rolling deployments."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum percent for ECS rolling deployments."
  type        = number
  default     = 200
}

variable "alb_deregistration_delay" {
  description = "ALB target group deregistration delay in seconds."
  type        = number
  default     = 30
}

variable "ui_health_check_path" {
  description = "Health check path for the UI service target group."
  type        = string
  default     = "/actuator/health"
}

variable "catalog_db_instance_class" {
  description = "Catalog RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "orders_db_instance_class" {
  description = "Orders RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_multi_az" {
  description = "Use Multi-AZ for stateful databases."
  type        = bool
  default     = false
}

variable "database_deletion_protection" {
  description = "Protect databases from accidental deletion."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Retention period in days for RDS automated backups."
  type        = number
  default     = 7
}

variable "redis_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ Redis replication."
  type        = bool
  default     = false
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover for Redis."
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other CloudWatch alarm actions."
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_alarms" {
  description = "Enable basic ECS and ALB CloudWatch alarms."
  type        = bool
  default     = true
}
