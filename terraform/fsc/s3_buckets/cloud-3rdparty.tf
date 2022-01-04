locals {
  cloud_3rdparty_bucket_name    = "cloud-${local.input_param_account_name}-3rdparty"
}

module "cloud_3rdparty_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_name = local.cloud_3rdparty_bucket_name
}

resource "aws_s3_bucket_public_access_block" "cloud_3rdparty_bucket_block_public_access" {
  bucket = module.cloud_3rdparty_bucket.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
