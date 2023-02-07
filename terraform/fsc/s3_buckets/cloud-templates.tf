locals {
  cloud_templates_bucket_name    = "cloud-${local.input_param_account_name}-templates"
  default_cloud_templates_bucket_expiration_days = 90
  cloud_templates_enable_versioning      = true

  S3_CLOUD_TEMPLATE_BUCKET_BY_EXPIRATION_DAYS = {
    inf  = 60
    dev  = 60
    qa   = 60
    prod = 90
  }

  s3_cloud_lifecyle_expiration_days_value = lookup(
    local.S3_CLOUD_TEMPLATE_BUCKET_BY_EXPIRATION_DAYS,
    local.input_param_deployment_environment,
    local.default_cloud_templates_bucket_expiration_days
  )
}

module "cloud_templates_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  enable_versioning = local.cloud_templates_enable_versioning

  bucket_name = local.cloud_templates_bucket_name
  lifecycle_rules = [
    {
      id = format(
        "global expiration in %d days",
        local.s3_cloud_lifecyle_expiration_days_value
      )
      enabled = true

      selector_prefix = null
      selector_tags   = null

      abort_incomplete_multipart_upload_days = null

      expiration = [
        {
          date                         = null
          days                         = local.s3_cloud_lifecyle_expiration_days_value
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
