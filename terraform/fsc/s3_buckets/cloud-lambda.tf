locals {
  cloud_lambda_bucket_logical_name    = "cloud-${local.input_param_account_name}-lambda"
}

module "cloud_lambda_bucket" {
  source = "../modules/s3_bucket"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  bucket_logical_name = local.cloud_lambda_bucket_logical_name
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
}
