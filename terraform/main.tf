module "vpc" {
  source = "./modules/vpc"

  name                  = local.name
  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  availability_zones    = local.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  nat_gateway_mode      = var.nat_gateway_mode
  enable_vpc_endpoints  = var.enable_vpc_endpoints
  vpc_endpoint_services = var.vpc_endpoint_services
  tags                  = local.tags
}

module "security_groups" {
  source = "./modules/security-groups"

  name                   = local.name
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr_block         = var.vpc_cidr
  alb_ingress_cidrs      = var.allowed_ingress_cidrs
  ui_container_port      = 8080
  backend_container_port = 8080
  tags                   = local.tags
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix           = local.name
  repositories          = toset(local.enabled_services)
  image_retention_count = var.ecr_image_retention_count
  tags                  = local.tags
}

module "service_discovery" {
  source = "./modules/service-discovery"
  count  = var.enable_service_discovery ? 1 : 0

  name          = local.name
  vpc_id        = module.vpc.vpc_id
  service_names = local.enabled_services
  tags          = local.tags
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  name_prefix           = local.name
  service_names         = local.enabled_services
  log_retention_in_days = var.log_retention_in_days
  create_alarms         = var.enable_cloudwatch_alarms
  cluster_name          = module.ecs_cluster.name
  alarm_actions         = var.alarm_actions
  alb_arn_suffix        = module.alb.arn_suffix
  cpu_threshold         = var.autoscaling_cpu_target
  memory_threshold      = var.autoscaling_memory_target
  tags                  = local.tags
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  name                      = local.name
  enable_container_insights = var.enable_container_insights
  tags                      = local.tags
}

module "cart_dynamodb" {
  source = "./modules/dynamodb"

  name = "${local.name}-cart"
  tags = local.tags
}

module "catalog_db" {
  source = "./modules/rds"
  count  = var.enable_catalog_database ? 1 : 0

  identifier              = "${local.name}-catalog"
  db_name                 = "catalogdb"
  engine                  = "mariadb"
  engine_version          = "10.11"
  instance_class          = var.catalog_db_instance_class
  allocated_storage       = 20
  port                    = 3306
  username                = "catalog_user"
  subnet_ids              = module.vpc.private_subnet_ids
  security_group_ids      = [module.security_groups.database_sg_id]
  multi_az                = var.database_multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.database_deletion_protection
  tags                    = local.tags
}

module "orders_db" {
  source = "./modules/rds"
  count  = var.enable_orders && var.enable_orders_database ? 1 : 0

  identifier              = "${local.name}-orders"
  db_name                 = "orders"
  engine                  = "postgres"
  engine_version          = "16.4"
  instance_class          = var.orders_db_instance_class
  allocated_storage       = 20
  port                    = 5432
  username                = "orders_user"
  subnet_ids              = module.vpc.private_subnet_ids
  security_group_ids      = [module.security_groups.database_sg_id]
  multi_az                = var.database_multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.database_deletion_protection
  tags                    = local.tags
}

module "checkout_redis" {
  source = "./modules/elasticache"
  count  = var.enable_checkout_redis ? 1 : 0

  name                       = "${local.name}-checkout"
  subnet_ids                 = module.vpc.private_subnet_ids
  security_group_ids         = [module.security_groups.cache_sg_id]
  node_type                  = var.redis_node_type
  multi_az_enabled           = var.redis_multi_az_enabled
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  tags                       = local.tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix             = local.name
  service_names           = local.enabled_services
  cart_dynamodb_table_arn = module.cart_dynamodb.table_arn
  execution_secret_arns = compact(concat(
    var.enable_catalog_database ? [module.catalog_db[0].master_user_secret_arn] : [],
    var.enable_orders && var.enable_orders_database ? [module.orders_db[0].master_user_secret_arn] : []
  ))
  tags = local.tags
}

module "alb" {
  source = "./modules/alb"

  name                  = local.name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_sg_id
  target_port           = 8080
  health_check_path     = var.ui_health_check_path
  deregistration_delay  = var.alb_deregistration_delay
  certificate_arn       = var.certificate_arn
  route53_zone_id       = var.route53_zone_id
  public_domain_name    = var.public_domain_name
  tags                  = local.tags
}

module "waf" {
  source = "./modules/waf"
  count  = var.enable_waf ? 1 : 0

  name         = local.name
  resource_arn = module.alb.arn
  tags         = local.tags
}

module "ecs_service_ui" {
  source = "./modules/ecs-service"

  name                               = "${local.name}-ui"
  service_name                       = "ui"
  cluster_id                         = module.ecs_cluster.id
  cluster_name                       = module.ecs_cluster.name
  aws_region                         = var.aws_region
  task_execution_role_arn            = module.iam.task_execution_role_arn
  task_role_arn                      = module.iam.task_role_arns["ui"]
  subnet_ids                         = module.vpc.private_subnet_ids
  security_group_ids                 = [module.security_groups.ui_sg_id]
  container_image                    = local.service_images["ui"]
  container_port                     = 8080
  cpu                                = var.service_cpu["ui"]
  memory                             = var.service_memory["ui"]
  desired_count                      = var.service_desired_counts["ui"]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  load_balancer_target_group_arn     = module.alb.target_group_arn
  health_check_grace_period_seconds  = 60
  service_discovery_service_arn      = var.enable_service_discovery ? module.service_discovery[0].service_arns["ui"] : null
  log_group_name                     = module.cloudwatch.log_group_names["ui"]
  environment = {
    RETAIL_UI_ENDPOINTS_CATALOG  = var.enable_service_discovery ? "http://catalog.${module.service_discovery[0].namespace_name}" : "false"
    RETAIL_UI_ENDPOINTS_CARTS    = var.enable_service_discovery ? "http://cart.${module.service_discovery[0].namespace_name}" : "false"
    RETAIL_UI_ENDPOINTS_CHECKOUT = var.enable_service_discovery ? "http://checkout.${module.service_discovery[0].namespace_name}" : "false"
    RETAIL_UI_ENDPOINTS_ORDERS   = var.enable_orders && var.enable_service_discovery ? "http://orders.${module.service_discovery[0].namespace_name}" : "false"
    RETAIL_UI_SEARCH_ENABLED     = tostring(var.catalog_search_enabled)
  }
  secrets             = {}
  healthcheck_command = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
  tags                = local.tags
}

module "ecs_service_catalog" {
  source = "./modules/ecs-service"

  name                               = "${local.name}-catalog"
  service_name                       = "catalog"
  cluster_id                         = module.ecs_cluster.id
  cluster_name                       = module.ecs_cluster.name
  aws_region                         = var.aws_region
  task_execution_role_arn            = module.iam.task_execution_role_arn
  task_role_arn                      = module.iam.task_role_arns["catalog"]
  subnet_ids                         = module.vpc.private_subnet_ids
  security_group_ids                 = [module.security_groups.backend_sg_id]
  container_image                    = local.service_images["catalog"]
  container_port                     = 8080
  cpu                                = var.service_cpu["catalog"]
  memory                             = var.service_memory["catalog"]
  desired_count                      = var.service_desired_counts["catalog"]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  service_discovery_service_arn      = var.enable_service_discovery ? module.service_discovery[0].service_arns["catalog"] : null
  log_group_name                     = module.cloudwatch.log_group_names["catalog"]
  environment = merge(
    {
      RETAIL_CATALOG_PERSISTENCE_PROVIDER = var.enable_catalog_database ? "mysql" : "in-memory"
      RETAIL_CATALOG_PERSISTENCE_DB_NAME  = "catalogdb"
      RETAIL_CATALOG_SEARCH_ENABLED       = tostring(var.catalog_search_enabled)
    },
    var.catalog_search_enabled ? { RETAIL_CATALOG_SEARCH_OS_INDEX = "products" } : {}
  )
  secrets = var.enable_catalog_database ? {
    RETAIL_CATALOG_PERSISTENCE_ENDPOINT = "${module.catalog_db[0].master_user_secret_arn}:host::"
    RETAIL_CATALOG_PERSISTENCE_USER     = "${module.catalog_db[0].master_user_secret_arn}:username::"
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = "${module.catalog_db[0].master_user_secret_arn}:password::"
  } : {}
  healthcheck_command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
  tags                = local.tags
}

module "ecs_service_cart" {
  source = "./modules/ecs-service"

  name                               = "${local.name}-cart"
  service_name                       = "cart"
  cluster_id                         = module.ecs_cluster.id
  cluster_name                       = module.ecs_cluster.name
  aws_region                         = var.aws_region
  task_execution_role_arn            = module.iam.task_execution_role_arn
  task_role_arn                      = module.iam.task_role_arns["cart"]
  subnet_ids                         = module.vpc.private_subnet_ids
  security_group_ids                 = [module.security_groups.backend_sg_id]
  container_image                    = local.service_images["cart"]
  container_port                     = 8080
  cpu                                = var.service_cpu["cart"]
  memory                             = var.service_memory["cart"]
  desired_count                      = var.service_desired_counts["cart"]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  service_discovery_service_arn      = var.enable_service_discovery ? module.service_discovery[0].service_arns["cart"] : null
  log_group_name                     = module.cloudwatch.log_group_names["cart"]
  environment = {
    RETAIL_CART_PERSISTENCE_PROVIDER            = "dynamodb"
    RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME = module.cart_dynamodb.table_name
  }
  secrets             = {}
  healthcheck_command = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
  tags                = local.tags
}

module "ecs_service_checkout" {
  source = "./modules/ecs-service"

  name                               = "${local.name}-checkout"
  service_name                       = "checkout"
  cluster_id                         = module.ecs_cluster.id
  cluster_name                       = module.ecs_cluster.name
  aws_region                         = var.aws_region
  task_execution_role_arn            = module.iam.task_execution_role_arn
  task_role_arn                      = module.iam.task_role_arns["checkout"]
  subnet_ids                         = module.vpc.private_subnet_ids
  security_group_ids                 = [module.security_groups.backend_sg_id]
  container_image                    = local.service_images["checkout"]
  container_port                     = 8080
  cpu                                = var.service_cpu["checkout"]
  memory                             = var.service_memory["checkout"]
  desired_count                      = var.service_desired_counts["checkout"]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  service_discovery_service_arn      = var.enable_service_discovery ? module.service_discovery[0].service_arns["checkout"] : null
  log_group_name                     = module.cloudwatch.log_group_names["checkout"]
  environment = merge(
    {
      RETAIL_CHECKOUT_PERSISTENCE_PROVIDER = var.enable_checkout_redis ? "redis" : "in-memory"
    },
    var.enable_checkout_redis ? {
      RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL = "redis://${module.checkout_redis[0].primary_endpoint_address}:${module.checkout_redis[0].port}"
    } : {},
    var.enable_orders && var.enable_service_discovery ? {
      RETAIL_CHECKOUT_ENDPOINTS_ORDERS = "http://orders.${module.service_discovery[0].namespace_name}"
    } : {}
  )
  secrets             = {}
  healthcheck_command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
  tags                = local.tags
}

module "ecs_service_orders" {
  source = "./modules/ecs-service"
  count  = var.enable_orders ? 1 : 0

  name                               = "${local.name}-orders"
  service_name                       = "orders"
  cluster_id                         = module.ecs_cluster.id
  cluster_name                       = module.ecs_cluster.name
  aws_region                         = var.aws_region
  task_execution_role_arn            = module.iam.task_execution_role_arn
  task_role_arn                      = module.iam.task_role_arns["orders"]
  subnet_ids                         = module.vpc.private_subnet_ids
  security_group_ids                 = [module.security_groups.backend_sg_id]
  container_image                    = local.service_images["orders"]
  container_port                     = 8080
  cpu                                = var.service_cpu["orders"]
  memory                             = var.service_memory["orders"]
  desired_count                      = var.service_desired_counts["orders"]
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  service_discovery_service_arn      = var.enable_service_discovery ? module.service_discovery[0].service_arns["orders"] : null
  log_group_name                     = module.cloudwatch.log_group_names["orders"]
  environment = {
    RETAIL_ORDERS_MESSAGING_PROVIDER   = "in-memory"
    RETAIL_ORDERS_PERSISTENCE_PROVIDER = var.enable_orders_database ? "postgres" : "in-memory"
    RETAIL_ORDERS_PERSISTENCE_NAME     = "orders"
  }
  secrets = var.enable_orders_database ? {
    RETAIL_ORDERS_PERSISTENCE_ENDPOINT = "${module.orders_db[0].master_user_secret_arn}:host::"
    RETAIL_ORDERS_PERSISTENCE_USERNAME = "${module.orders_db[0].master_user_secret_arn}:username::"
    RETAIL_ORDERS_PERSISTENCE_PASSWORD = "${module.orders_db[0].master_user_secret_arn}:password::"
  } : {}
  healthcheck_command = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
  tags                = local.tags
}

module "autoscaling" {
  source = "./modules/autoscaling"
  for_each = {
    for service_name, service_module in {
      ui       = module.ecs_service_ui
      catalog  = module.ecs_service_catalog
      cart     = module.ecs_service_cart
      checkout = module.ecs_service_checkout
      orders   = var.enable_orders ? module.ecs_service_orders[0] : null
    } : service_name => service_module if service_module != null
  }

  cluster_name  = each.value.cluster_name
  service_name  = each.value.service_name
  min_capacity  = var.service_min_capacity[each.key]
  max_capacity  = var.service_max_capacity[each.key]
  cpu_target    = var.autoscaling_cpu_target
  memory_target = var.autoscaling_memory_target
}

module "github_actions_deploy_role" {
  source = "./modules/github-actions-deploy-role"

  create                   = var.enable_github_actions_deploy_role
  name                     = "${local.name}-github-deploy"
  github_repository        = var.github_repository
  github_environment       = var.environment
  github_oidc_provider_arn = coalesce(var.github_oidc_provider_arn, "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com")
  ecr_repository_arns      = values(module.ecr.repository_arns)
  service_arns = compact([
    module.ecs_service_ui.service_arn,
    module.ecs_service_catalog.service_arn,
    module.ecs_service_cart.service_arn,
    module.ecs_service_checkout.service_arn,
    var.enable_orders ? module.ecs_service_orders[0].service_arn : null
  ])
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arns          = values(module.iam.task_role_arns)
  tags                    = local.tags
}
