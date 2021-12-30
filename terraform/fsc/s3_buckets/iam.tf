data "aws_iam_policy_document" "cloud_configs_s3_kms_policy" {
  policy_id = "cloud_configs_s3_kms_policy"

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      module.cloud_configs_bucket.bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "cloud_configs_s3_kms_policy" {
  name_prefix = "cloud-configs-s3-kms-"
  path        = "/"
  description = "Policy for Cloud Configs to decrypt KMS keys on accessible buckets"
  policy      = data.aws_iam_policy_document.cloud_configs_s3_kms_policy.json

  tags = { Name = "cloud-configs-s3-kms" }
}

data "aws_iam_policy_document" "cloud_connections_s3_kms_policy" {
  policy_id = "cloud_connections_s3_kms_policy"

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      module.cloud_connections_bucket.bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "cloud_connections_s3_kms_policy" {
  name_prefix = "cloud-connections-s3-kms-"
  path        = "/"
  description = "Policy for Cloud Connections to decrypt KMS keys on accessible buckets"
  policy      = data.aws_iam_policy_document.cloud_connections_s3_kms_policy.json

  tags = { Name = "cloud-connections-s3-kms" }
}

data "aws_iam_policy_document" "cloud_templates_s3_kms_policy" {
  policy_id = "cloud_templates_s3_kms_policy"

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      module.cloud_templates_bucket.bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "cloud_templates_s3_kms_policy" {
  name_prefix = "cloud-templates-s3-kms-"
  path        = "/"
  description = "Policy for Cloud Templates to decrypt KMS keys on accessible buckets"
  policy      = data.aws_iam_policy_document.cloud_templates_s3_kms_policy.json

  tags = { Name = "cloud-templates-s3-kms" }
}