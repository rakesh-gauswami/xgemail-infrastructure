locals {
  cloud_lambda_bucket_logical_name    = "cloud-${local.input_param_account_name}-lambda"
  cloud_lambda_bucket_expiration_days = 14
  cloud_lambda_should_create_kms_key  = false
  cloud_3rdparty_bucket_key_enabled   = false
}

module "cloud_lambda_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_lambda_bucket_logical_name

  should_create_kms_key =  local.cloud_lambda_should_create_kms_key

  lifecycle_rules = [
    {
      id = format(
        "global expiration in %d days",
        local.cloud_lambda_bucket_expiration_days
      )
      enabled = true

      selector_prefix = null
      selector_tags   = null

      abort_incomplete_multipart_upload_days = null

      expiration = [
        {
          date                         = null
          days                         = local.cloud_lambda_bucket_expiration_days
          expired_object_delete_marker = null
        }
      ]

      noncurrent_version_expiration = []
      noncurrent_version_transition = []

      transition = []
    }
  ]
}

resource "aws_s3_bucket_public_access_block" "cloud_lambda_bucket_block_public_access" {
  bucket = module.cloud_lambda_bucket.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "cloud_lambda_bucket_read_policy" {
  policy_id = "cloud_lambda_bucket_read_policy"

  statement {
    actions = [
      "s3:GetObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_lambda_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_lambda_bucket_read_policy" {
  name_prefix = "CloudLambdaBucketReadPolicy-"
  path        = "/"
  description = "Policy for Cloud Lambda Bucket Read Access"
  policy      = data.aws_iam_policy_document.cloud_lambda_bucket_read_policy.json

  tags = { Name = "CloudLambdaBucketReadPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_lambda_bucket_write_policy" {
  policy_id = "cloud_lambda_bucket_write_policy"

  statement {
    actions = [
      "s3:PutObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_lambda_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_lambda_bucket_write_policy" {
  name_prefix = "CloudLambdaBucketWritePolicy-"
  path        = "/"
  description = "Policy for Cloud Lambda Bucket Write Access"
  policy      = data.aws_iam_policy_document.cloud_lambda_bucket_write_policy.json

  tags = { Name = "CloudLambdaBucketWritePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_lambda_bucket_delete_policy" {
  policy_id = "cloud_lambda_bucket_delete_policy"

  statement {
    actions = [
      "s3:DeleteObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_lambda_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_lambda_bucket_delete_policy" {
  name_prefix = "CloudLambdaBucketDeletePolicy-"
  path        = "/"
  description = "Policy for Cloud Lambda Bucket Delete Access"
  policy      = data.aws_iam_policy_document.cloud_lambda_bucket_delete_policy.json

  tags = { Name = "CloudLambdaBucketDeletePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_lambda_bucket_list_policy" {
  policy_id = "cloud_lambda_bucket_list_policy"

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"

    resources = [
      module.cloud_lambda_bucket.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "cloud_lambda_bucket_list_policy" {
  name_prefix = "CloudLambdaBucketListPolicy-"
  path        = "/"
  description = "Policy for Cloud Lambda Bucket List Access"
  policy      = data.aws_iam_policy_document.cloud_lambda_bucket_list_policy.json

  tags = { Name = "CloudLambdaBucketListPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}
