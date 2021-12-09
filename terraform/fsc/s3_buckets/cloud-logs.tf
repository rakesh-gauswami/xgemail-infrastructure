locals {
  cloud_logs_bucket_logical_name    = "cloud-${var.pop_name}-logs"
}

module "cloud_logs_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_logs_bucket_logical_name
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
}
