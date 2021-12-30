locals {
  cloud_logs_bucket_logical_name    = "cloud-${local.input_param_account_name}-logs"
  cloud_logs_bucket_expiration_days = 14
  cloud_logs_should_create_kms_key  = false
  cloud_3rdparty_bucket_key_enabled = false
}

module "cloud_logs_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_logs_bucket_logical_name

  should_create_kms_key =  local.cloud_logs_should_create_kms_key

  lifecycle_rules = [
    {
      id = format(
        "global expiration in %d days",
        local.cloud_logs_bucket_expiration_days
      )
      enabled = true

      selector_prefix = null
      selector_tags   = null

      abort_incomplete_multipart_upload_days = null

      expiration = [
        {
          date                         = null
          days                         = local.cloud_logs_bucket_expiration_days
          expired_object_delete_marker = null
        }
      ]

      noncurrent_version_expiration = []
      noncurrent_version_transition = []

      transition = []
    }
  ]
}

resource "aws_s3_bucket_public_access_block" "cloud_logs_bucket_block_public_access" {
  bucket = module.cloud_logs_bucket.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "cloud_logs_bucket_read_policy" {
  policy_id = "cloud_logs_bucket_read_policy"

  statement {
    actions = [
      "s3:GetObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_logs_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_logs_bucket_read_policy" {
  name_prefix = "CloudLogsBucketReadPolicy-"
  path        = "/"
  description = "Policy for Cloud Logs Bucket Read Access"
  policy      = data.aws_iam_policy_document.cloud_logs_bucket_read_policy.json

  tags = { Name = "CloudLogsBucketReadPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_logs_bucket_write_policy" {
  policy_id = "cloud_logs_bucket_write_policy"

  statement {
    actions = [
      "s3:PutObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_logs_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_logs_bucket_write_policy" {
  name_prefix = "CloudLogsBucketWritePolicy-"
  path        = "/"
  description = "Policy for Cloud Logs Bucket Write Access"
  policy      = data.aws_iam_policy_document.cloud_logs_bucket_write_policy.json

  tags = { Name = "CloudLogsBucketWritePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_logs_bucket_delete_policy" {
  policy_id = "cloud_logs_bucket_delete_policy"

  statement {
    actions = [
      "s3:DeleteObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_logs_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_logs_bucket_delete_policy" {
  name_prefix = "CloudLogsBucketDeletePolicy-"
  path        = "/"
  description = "Policy for Cloud Logs Bucket Delete Access"
  policy      = data.aws_iam_policy_document.cloud_logs_bucket_delete_policy.json

  tags = { Name = "CloudLogsBucketDeletePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_logs_bucket_list_policy" {
  policy_id = "cloud_logs_bucket_list_policy"

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"

    resources = [
      module.cloud_logs_bucket.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "cloud_logs_bucket_list_policy" {
  name_prefix = "CloudLogsBucketListPolicy-"
  path        = "/"
  description = "Policy for Cloud Logs Bucket List Access"
  policy      = data.aws_iam_policy_document.cloud_logs_bucket_list_policy.json

  tags = { Name = "CloudLogsBucketListPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}
