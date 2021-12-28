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

data "aws_iam_policy_document" "cloud_templates_bucket_read_policy" {
  policy_id = "cloud_templates_bucket_read_policy"

  statement {
    actions = [
      "s3:GetObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_templates_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_templates_bucket_read_policy" {
  name_prefix = "CloudTemplatesBucketReadPolicy-"
  path        = "/"
  description = "Policy for Cloud Templates Bucket Read Access"
  policy      = data.aws_iam_policy_document.cloud_templates_bucket_read_policy.json

  tags = { Name = "CloudTemplatesBucketReadPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_templates_bucket_write_policy" {
  policy_id = "cloud_templates_bucket_write_policy"

  statement {
    actions = [
      "s3:PutObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_templates_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_templates_bucket_write_policy" {
  name_prefix = "CloudTemplatesBucketWritePolicy-"
  path        = "/"
  description = "Policy for Cloud Templates Bucket Write Access"
  policy      = data.aws_iam_policy_document.cloud_templates_bucket_write_policy.json

  tags = { Name = "CloudTemplatesBucketWritePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_templates_bucket_delete_policy" {
  policy_id = "cloud_templates_bucket_delete_policy"

  statement {
    actions = [
      "s3:DeleteObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_templates_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_templates_bucket_delete_policy" {
  name_prefix = "CloudTemplatesBucketDeletePolicy-"
  path        = "/"
  description = "Policy for Cloud Templates Bucket Delete Access"
  policy      = data.aws_iam_policy_document.cloud_templates_bucket_delete_policy.json

  tags = { Name = "CloudTemplatesBucketDeletePolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "cloud_templates_bucket_list_policy" {
  policy_id = "cloud_templates_bucket_list_policy"

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"

    resources = [
      module.cloud_templates_bucket.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "cloud_templates_bucket_list_policy" {
  name_prefix = "CloudTemplatesBucketListPolicy-"
  path        = "/"
  description = "Policy for Cloud Templates Bucket List Access"
  policy      = data.aws_iam_policy_document.cloud_templates_bucket_list_policy.json

  tags = { Name = "CloudTemplatesBucketListPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}
