aws_region                       = "eu-central-1"
environment                      = "dev"
project_name                     = "ecs-retail"
vpc_cidr                         = "10.0.0.0/16"
public_subnet_cidrs              = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs             = ["10.0.11.0/24", "10.0.12.0/24"]
nat_gateway_mode                 = "single"
enable_vpc_endpoints             = false
enable_waf                       = false
certificate_arn                  = null
route53_zone_id                  = null
public_domain_name               = null
enable_orders                    = false
enable_service_discovery         = true
enable_catalog_database          = false
enable_checkout_redis            = false
enable_orders_database           = false
catalog_search_enabled           = false
enable_container_insights        = true
log_retention_in_days            = 7
ecr_image_retention_count        = 15
database_multi_az                = false
database_deletion_protection     = false
backup_retention_period          = 1
redis_multi_az_enabled           = false
redis_automatic_failover_enabled = false
service_desired_counts = {
  ui       = 2
  catalog  = 1
  cart     = 1
  checkout = 1
  orders   = 1
}
service_min_capacity = {
  ui       = 2
  catalog  = 1
  cart     = 1
  checkout = 1
  orders   = 1
}
service_max_capacity = {
  ui       = 3
  catalog  = 2
  cart     = 2
  checkout = 2
  orders   = 2
}
service_cpu = {
  ui       = 512
  catalog  = 256
  cart     = 256
  checkout = 256
  orders   = 256
}
service_memory = {
  ui       = 1024
  catalog  = 512
  cart     = 512
  checkout = 512
  orders   = 512
}

