aws_region                   = "eu-central-1"
environment                  = "stage"
project_name                 = "ecs-retail"
vpc_cidr                     = "10.5.0.0/16"
public_subnet_cidrs          = ["10.5.1.0/24", "10.5.2.0/24"]
private_subnet_cidrs         = ["10.5.11.0/24", "10.5.12.0/24"]
nat_gateway_mode             = "single"
enable_vpc_endpoints         = true
enable_waf                   = false
certificate_arn              = null
route53_zone_id              = null
public_domain_name           = null
enable_orders                = true
enable_service_discovery     = true
enable_catalog_database      = true
enable_checkout_redis        = true
enable_orders_database       = true
catalog_search_enabled       = false
enable_container_insights    = true
log_retention_in_days        = 14
ecr_image_retention_count    = 30
database_multi_az            = false
database_deletion_protection = false
backup_retention_period      = 7
redis_multi_az_enabled       = false
redis_automatic_failover_enabled = false
service_desired_counts = {
  ui       = 2
  catalog  = 2
  cart     = 2
  checkout = 2
  orders   = 1
}
service_min_capacity = {
  ui       = 2
  catalog  = 2
  cart     = 2
  checkout = 2
  orders   = 1
}
service_max_capacity = {
  ui       = 4
  catalog  = 4
  cart     = 4
  checkout = 4
  orders   = 2
}
service_cpu = {
  ui       = 512
  catalog  = 512
  cart     = 512
  checkout = 512
  orders   = 512
}
service_memory = {
  ui       = 1024
  catalog  = 1024
  cart     = 1024
  checkout = 1024
  orders   = 1024
}

