resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = var.name
  description                = "Checkout Redis for ${var.name}"
  engine                     = "redis"
  node_type                  = var.node_type
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = var.security_group_ids
  at_rest_encryption_enabled = true
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  num_cache_clusters         = var.multi_az_enabled ? 2 : 1
  apply_immediately          = true

  tags = merge(var.tags, { Name = var.name })
}
