module "remote_state" {
  source = "../../modules/remote-state"

  bucket_name = var.bucket_name
  tags        = var.tags
}

