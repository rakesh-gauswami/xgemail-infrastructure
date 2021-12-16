locals {
  cloud_connections_bucket_logical_name    = "cloud-${local.input_param_account_name}-connections"
}

module "cloud_connections_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_connections_bucket_logical_name
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
}
