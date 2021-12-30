module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/iam/policies/cloud-configs-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_configs_s3_kms_policy.arn
      description = "Cloud Configs S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-configs-bucket-delete/arn"
      value       = aws_iam_policy.cloud_configs_bucket_delete_policy.arn
      description = "Cloud Configs S3 bucket delete policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-configs-bucket-list/arn"
      value       = aws_iam_policy.cloud_configs_bucket_list_policy.arn
      description = "Cloud Configs S3 bucket list policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-configs-bucket-read/arn"
      value       = aws_iam_policy.cloud_configs_bucket_read_policy.arn
      description = "Cloud Configs S3 bucket read policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-configs-bucket-write/arn"
      value       = aws_iam_policy.cloud_configs_bucket_write_policy.arn
      description = "Cloud Configs S3 bucket write policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-3rdparty-bucket-delete/arn"
      value       = aws_iam_policy.cloud_3rdparty_bucket_delete_policy.arn
      description = "Cloud 3rdparty S3 bucket delete policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-3rdparty-bucket-list/arn"
      value       = aws_iam_policy.cloud_3rdparty_bucket_list_policy.arn
      description = "Cloud 3rdparty S3 bucket list policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-3rdparty-bucket-read/arn"
      value       = aws_iam_policy.cloud_3rdparty_bucket_read_policy.arn
      description = "Cloud 3rdparty S3 bucket read policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-3rdparty-bucket-write/arn"
      value       = aws_iam_policy.cloud_3rdparty_bucket_write_policy.arn
      description = "Cloud 3rdparty S3 bucket write policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-connections-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_connections_s3_kms_policy.arn
      description = "Cloud Connections S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-connections-bucket-delete/arn"
      value       = aws_iam_policy.cloud_connections_bucket_delete_policy.arn
      description = "Cloud Connections S3 bucket delete policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-connections-bucket-list/arn"
      value       = aws_iam_policy.cloud_connections_bucket_list_policy.arn
      description = "Cloud Connections S3 bucket list policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-connections-bucket-read/arn"
      value       = aws_iam_policy.cloud_connections_bucket_read_policy.arn
      description = "Cloud Connections S3 bucket read policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-connections-bucket-write/arn"
      value       = aws_iam_policy.cloud_connections_bucket_write_policy.arn
      description = "Cloud Connections S3 bucket write policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-lambda-bucket-delete/arn"
      value       = aws_iam_policy.cloud_lambda_bucket_delete_policy.arn
      description = "Cloud Lambda S3 bucket delete policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-lambda-bucket-list/arn"
      value       = aws_iam_policy.cloud_lambda_bucket_list_policy.arn
      description = "Cloud Lambda S3 bucket list policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-lambda-bucket-read/arn"
      value       = aws_iam_policy.cloud_lambda_bucket_read_policy.arn
      description = "Cloud Lambda S3 bucket read policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-lambda-bucket-write/arn"
      value       = aws_iam_policy.cloud_lambda_bucket_write_policy.arn
      description = "Cloud Lambda S3 bucket write policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-logs-bucket-delete/arn"
      value       = aws_iam_policy.cloud_logs_bucket_delete_policy.arn
      description = "Cloud Logs S3 bucket delete policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-logs-bucket-list/arn"
      value       = aws_iam_policy.cloud_logs_bucket_list_policy.arn
      description = "Cloud Logs S3 bucket list policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-logs-bucket-read/arn"
      value       = aws_iam_policy.cloud_logs_bucket_read_policy.arn
      description = "Cloud Logs S3 bucket read policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-logs-bucket-write/arn"
      value       = aws_iam_policy.cloud_logs_bucket_write_policy.arn
      description = "Cloud Logs S3 bucket write policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-templates-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_templates_s3_kms_policy.arn
      description = "Cloud Templates S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-templates-bucket-delete/arn"
      value       = aws_iam_policy.cloud_templates_bucket_delete_policy.arn
      description = "Cloud Templates S3 bucket delete policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-templates-bucket-list/arn"
      value       = aws_iam_policy.cloud_templates_bucket_list_policy.arn
      description = "Cloud Templates S3 bucket list policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-templates-bucket-read/arn"
      value       = aws_iam_policy.cloud_templates_bucket_read_policy.arn
      description = "Cloud Templates S3 bucket read policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-templates-bucket-write/arn"
      value       = aws_iam_policy.cloud_templates_bucket_write_policy.arn
      description = "Cloud Templates S3 bucket write policy ARN"
    }
  ]
}
