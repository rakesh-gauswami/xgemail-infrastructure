locals {
  cloud_connections_bucket_logical_name    = "cloud-${local.input_param_account_name}-connections"
  cloud_connections_bucket_expiration_days = 14
  cloud_connections_enable_versioning      = true
}

module "cloud_connections_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  enable_versioning = local.cloud_connections_enable_versioning

  bucket_logical_name = local.cloud_connections_bucket_logical_name
  lifecycle_rules = [
    {
      id = format(
        "global expiration in %d days",
        local.cloud_connections_bucket_expiration_days
      )
      enabled = true

      selector_prefix = null
      selector_tags   = null

      abort_incomplete_multipart_upload_days = null

      expiration = [
        {
          date                         = null
          days                         = local.cloud_connections_bucket_expiration_days
          expired_object_delete_marker = null
        }
      ]

      noncurrent_version_expiration = []
      noncurrent_version_transition = []

      transition = []
    }
  ]
}

resource "aws_s3_bucket_public_access_block" "cloud_connections_bucket_block_public_access" {
  bucket = module.cloud_connections_bucket.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "cloud_connections_bucket_read_policy" {
  policy_id = "cloud_connections_bucket_read_policy"

  statement {
    actions = [
      "s3:GetObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_connections_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_connections_bucket_read_policy" {
  name_prefix = "CloudConnectionsBucketReadPolicy-"
  path        = "/"
  description = "Policy for Cloud Connections Bucket Read Access"
  policy      = data.aws_iam_policy_document.cloud_connections_bucket_read_policy.json

  tags = { Name = "CloudConnectionsBucketReadPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_connections_bucket_write_policy" {
  policy_id = "cloud_connections_bucket_write_policy"

  statement {
    actions = [
      "s3:PutObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_connections_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_connections_bucket_write_policy" {
  name_prefix = "CloudConnectionsBucketWritePolicy-"
  path        = "/"
  description = "Policy for Cloud Connections Bucket Write Access"
  policy      = data.aws_iam_policy_document.cloud_connections_bucket_write_policy.json

  tags = { Name = "CloudConnectionsBucketWritePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_connections_bucket_delete_policy" {
  policy_id = "cloud_connections_bucket_delete_policy"

  statement {
    actions = [
      "s3:DeleteObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_connections_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_connections_bucket_delete_policy" {
  name_prefix = "CloudConnectionsBucketDeletePolicy-"
  path        = "/"
  description = "Policy for Cloud Connections Bucket Delete Access"
  policy      = data.aws_iam_policy_document.cloud_connections_bucket_delete_policy.json

  tags = { Name = "CloudConnectionsBucketDeletePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_connections_bucket_list_policy" {
  policy_id = "cloud_connections_bucket_list_policy"

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"

    resources = [
      module.cloud_connections_bucket.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "cloud_connections_bucket_list_policy" {
  name_prefix = "CloudConnectionsBucketListPolicy-"
  path        = "/"
  description = "Policy for Cloud Connections Bucket List Access"
  policy      = data.aws_iam_policy_document.cloud_connections_bucket_list_policy.json

  tags = { Name = "CloudConnectionsBucketListPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}
