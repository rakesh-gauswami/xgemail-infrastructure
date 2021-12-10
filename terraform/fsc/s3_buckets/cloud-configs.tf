locals {
  cloud_configs_bucket_logical_name    = "cloud-configs"
}

module "cloud_configs_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_configs_bucket_logical_name
}

data "aws_iam_policy_document" "cloud_configs_bucket_read_policy" {
  policy_id = "cloud_configs_bucket_read_policy"

  statement {
    actions = [
      "s3:GetObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_configs_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_configs_bucket_read_policy" {
  name_prefix = "CloudConfigsBucketReadPolicy-"
  path        = "/"
  description = "Policy for Cloud Configs Bucket Read Access"
  policy      = data.aws_iam_policy_document.cloud_configs_bucket_read_policy.json

  tags = { Name = "CloudConfigsBucketReadPolicy" }
}

data "aws_iam_policy_document" "cloud_configs_bucket_write_policy" {
  policy_id = "cloud_configs_bucket_write_policy"

  statement {
    actions = [
      "s3:PutObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_configs_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_configs_bucket_write_policy" {
  name_prefix = "CloudConfigsBucketWritePolicy-"
  path        = "/"
  description = "Policy for Cloud Configs Bucket Write Access"
  policy      = data.aws_iam_policy_document.cloud_configs_bucket_write_policy.json

  tags = { Name = "CloudConfigsBucketWritePolicy" }
}

data "aws_iam_policy_document" "cloud_configs_bucket_delete_policy" {
  policy_id = "cloud_configs_bucket_delete_policy"

  statement {
    actions = [
      "s3:DeleteObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_configs_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_configs_bucket_delete_policy" {
  name_prefix = "CloudConfigsBucketDeletePolicy-"
  path        = "/"
  description = "Policy for Cloud Configs Bucket Delete Access"
  policy      = data.aws_iam_policy_document.cloud_configs_bucket_delete_policy.json

  tags = { Name = "CloudConfigsBucketDeletePolicy" }
}

data "aws_iam_policy_document" "cloud_configs_bucket_list_policy" {
  policy_id = "cloud_configs_bucket_list_policy"

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"

    resources = [
      module.cloud_configs_bucket.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "cloud_configs_bucket_list_policy" {
  name_prefix = "CloudConfigsBucketListPolicy-"
  path        = "/"
  description = "Policy for Cloud Configs Bucket List Access"
  policy      = data.aws_iam_policy_document.cloud_configs_bucket_list_policy.json

  tags = { Name = "CloudConfigsBucketListPolicy" }
}
