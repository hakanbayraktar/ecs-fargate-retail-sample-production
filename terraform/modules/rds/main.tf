resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.identifier}-subnets" })
}

resource "aws_db_instance" "this" {
  identifier                   = var.identifier
  db_name                      = var.db_name
  engine                       = var.engine
  engine_version               = var.engine_version
  instance_class               = var.instance_class
  allocated_storage            = var.allocated_storage
  port                         = var.port
  username                     = var.username
  manage_master_user_password  = true
  storage_encrypted            = true
  backup_retention_period      = var.backup_retention_period
  deletion_protection          = var.deletion_protection
  multi_az                     = var.multi_az
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = var.security_group_ids
  publicly_accessible          = false
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${var.identifier}-final"
  auto_minor_version_upgrade   = true
  performance_insights_enabled = true
  copy_tags_to_snapshot        = true

  tags = merge(var.tags, { Name = var.identifier })
}

