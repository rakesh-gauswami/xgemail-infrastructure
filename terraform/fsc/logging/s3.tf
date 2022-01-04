locals {
  application_log_bucket_name = "cloud-${local.input_param_account_name}-logs"

  lifecycle_rules = {
    for config in [
      {
        bucket_id       = local.application_log_bucket_name
        expiration_days = var.logs_expiration_days
        transition_days = var.logs_transition_days
      }
    ] :
    config.bucket_id => [
      {
        id = format(
          "transition to glacier: %d, expiration: %d",
          config.transition_days, config.expiration_days
        )

        enabled = true

        selector_prefix = null
        selector_tags   = null

        abort_incomplete_multipart_upload_days = null

        expiration = [
          {
            date                         = null
            days                         = config.expiration_days
            expired_object_delete_marker = null
          }
        ]

        noncurrent_version_expiration = []
        noncurrent_version_transition = []

        transition = [
          {
            date          = null
            days          = config.transition_days
            storage_class = "GLACIER"
          }
        ]
      }
    ]
  }
}

module "logs_bucket" {
  source    = "../modules/s3_bucket"
  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_name   = local.application_log_bucket_name
  lifecycle_rules       = local.lifecycle_rules[local.application_log_bucket_name]
}
