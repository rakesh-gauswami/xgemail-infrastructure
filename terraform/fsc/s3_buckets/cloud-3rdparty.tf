locals {
  cloud_3rdparty_bucket_logical_name    = "cloud-3rdparty"
}

module "cloud_3rdparty_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_3rdparty_bucket_logical_name
}

data "aws_iam_policy_document" "cloud_3rdparty_bucket_read_policy" {
  policy_id = "cloud_3rdparty_bucket_read_policy"

  statement {
    actions = [
      "s3:GetObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_3rdparty_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_3rdparty_bucket_read_policy" {
  name_prefix = "Cloud3rdpartyBucketReadPolicy-"
  path        = "/"
  description = "Policy for Cloud 3rdparty Bucket Read Access"
  policy      = data.aws_iam_policy_document.cloud_3rdparty_bucket_read_policy.json

  tags = { Name = "Cloud3rdpartyBucketReadPolicy" }
}

data "aws_iam_policy_document" "cloud_3rdparty_bucket_write_policy" {
  policy_id = "cloud_3rdparty_bucket_write_policy"

  statement {
    actions = [
      "s3:PutObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_3rdparty_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_3rdparty_bucket_write_policy" {
  name_prefix = "Cloud3rdpartyBucketWritePolicy-"
  path        = "/"
  description = "Policy for Cloud 3rdparty Bucket Write Access"
  policy      = data.aws_iam_policy_document.cloud_3rdparty_bucket_write_policy.json

  tags = { Name = "Cloud3rdpartyBucketWritePolicy" }
}

data "aws_iam_policy_document" "cloud_3rdparty_bucket_delete_policy" {
  policy_id = "cloud_3rdparty_bucket_delete_policy"

  statement {
    actions = [
      "s3:DeleteObject",
    ]

    effect = "Allow"

    resources = [
      "${module.cloud_3rdparty_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_3rdparty_bucket_delete_policy" {
  name_prefix = "Cloud3rdpartyBucketDeletePolicy-"
  path        = "/"
  description = "Policy for Cloud 3rdparty Bucket Delete Access"
  policy      = data.aws_iam_policy_document.cloud_3rdparty_bucket_delete_policy.json

  tags = { Name = "Cloud3rdpartyBucketDeletePolicy" }
}

data "aws_iam_policy_document" "cloud_3rdparty_bucket_list_policy" {
  policy_id = "cloud_3rdparty_bucket_list_policy"

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    effect = "Allow"

    resources = [
      module.cloud_3rdparty_bucket.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "cloud_3rdparty_bucket_list_policy" {
  name_prefix = "Cloud3rdpartyBucketListPolicy-"
  path        = "/"
  description = "Policy for Cloud 3rdparty Bucket List Access"
  policy      = data.aws_iam_policy_document.cloud_3rdparty_bucket_list_policy.json

  tags = { Name = "Cloud3rdpartyBucketListPolicy" }
}
