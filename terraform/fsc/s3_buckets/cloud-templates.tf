locals {
  cloud_templates_bucket_logical_name    = "cloud-${local.input_param_account_name}-templates"
  cloud_templates_bucket_expiration_days = 14
}

module "cloud_templates_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_templates_bucket_logical_name
  lifecycle_rules = [
    {
      id = format(
        "global expiration in %d days",
        local.cloud_templates_bucket_expiration_days
      )
      enabled = true

      selector_prefix = null
      selector_tags   = null

      abort_incomplete_multipart_upload_days = null

      expiration = [
        {
          date                         = null
          days                         = local.cloud_templates_bucket_expiration_days
          expired_object_delete_marker = null
        }
      ]

      noncurrent_version_expiration = []
      noncurrent_version_transition = []

      transition = []
    }
  ]
}

resource "aws_s3_bucket_public_access_block" "cloud_templates_bucket_block_public_access" {
  bucket = module.cloud_templates_bucket.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
