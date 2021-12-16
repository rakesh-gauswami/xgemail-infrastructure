locals {

  bucket_prefix = "${var.bucket_logical_name}"
  logging = var.logging_target_bucket == null ? [] : [
    {
      target_bucket = var.logging_target_bucket
      target_prefix = var.logging_target_prefix
    }
  ]

  versioning = var.enable_versioning ? [
    {
      enabled = true
    }
  ] : []

  # Allows for clean deletes in INF environments
  resolved_force_destroy = local.input_param_deployment_environment == "inf" ? true : var.force_destroy
}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${local.bucket_prefix}-"

  force_destroy = local.resolved_force_destroy

  acl = "private"

  dynamic "lifecycle_rule" {
    for_each = toset(var.lifecycle_rules)

    content {
      id      = lifecycle_rule.key["id"]
      enabled = lifecycle_rule.key["enabled"]
      prefix  = lifecycle_rule.key["selector_prefix"]
      tags    = lifecycle_rule.key["selector_tags"]

      dynamic "expiration" {
        for_each = toset(lifecycle_rule.key["expiration"])

        content {
          date                         = expiration.key["date"]
          days                         = expiration.key["days"]
          expired_object_delete_marker = expiration.key["expired_object_delete_marker"]
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = toset(lifecycle_rule.key["noncurrent_version_expiration"])

        content {
          days = noncurrent_version_expiration.key["days"]
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = toset(lifecycle_rule.key["noncurrent_version_transition"])

        content {
          days          = noncurrent_version_transition.key["days"]
          storage_class = noncurrent_version_transition.key["storage_class"]
        }
      }

      dynamic "transition" {
        for_each = toset(lifecycle_rule.key["transition"])

        content {
          date          = transition.key["date"]
          days          = transition.key["days"]
          storage_class = transition.key["storage_class"]
        }
      }
    }
  }

  dynamic "logging" {
    for_each = toset(local.logging)

    content {
      target_bucket = logging.key["target_bucket"]
      target_prefix = logging.key["target_prefix"]
    }
  }

  dynamic "versioning" {
    for_each = toset(local.versioning)

    content {
      enabled = versioning.key["enabled"]
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.should_create_kms_key ? module.kms_key[0].key_arn : null
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  tags = { Name = local.bucket_prefix }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count = var.should_block_public_access ? 1 : 0

  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
