resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${var.name}.local"
  description = "Private namespace for ECS services"
  vpc         = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-namespace" })
}

resource "aws_service_discovery_service" "this" {
  for_each = toset(var.service_names)

  name = each.value

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

