locals {
  cloud_connections_bucket_name    = "cloud-${local.input_param_account_name}-connections"
  cloud_connections_enable_versioning      = true
}

module "cloud_connections_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  enable_versioning = local.cloud_connections_enable_versioning

  bucket_name = local.cloud_connections_bucket_name
}

resource "aws_s3_bucket_public_access_block" "cloud_connections_bucket_block_public_access" {
  bucket = module.cloud_connections_bucket.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
