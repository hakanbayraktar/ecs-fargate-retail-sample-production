data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project_name}-${var.environment}"

  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "ecs-fargate-retail-sample-production"
    },
    var.tags
  )

  enabled_services = concat(
    ["ui", "catalog", "cart", "checkout"],
    var.enable_orders ? ["orders"] : []
  )

  published_repository = "public.ecr.aws/aws-containers"

  default_images = {
    ui       = "${local.published_repository}/retail-store-sample-ui:${var.upstream_image_tag}"
    catalog  = "${local.published_repository}/retail-store-sample-catalog:${var.upstream_image_tag}"
    cart     = "${local.published_repository}/retail-store-sample-cart:${var.upstream_image_tag}"
    checkout = "${local.published_repository}/retail-store-sample-checkout:${var.upstream_image_tag}"
    orders   = "${local.published_repository}/retail-store-sample-orders:${var.upstream_image_tag}"
  }

  service_images = merge(local.default_images, var.container_image_overrides)
}

