resource "aws_cloudwatch_log_group" "service" {
  for_each          = toset(var.service_names)
  name              = "/ecs/${var.name_prefix}/${each.value}"
  retention_in_days = var.log_retention_in_days
  tags              = merge(var.tags, { Name = "${var.name_prefix}-${each.value}-logs" })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = var.create_alarms ? toset(var.service_names) : []

  alarm_name          = "${var.name_prefix}-${each.value}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "${var.name_prefix}-${each.value}"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  for_each = var.create_alarms ? toset(var.service_names) : []

  alarm_name          = "${var.name_prefix}-${each.value}-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "${var.name_prefix}-${each.value}"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

