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
      name        = "/central/iam/policies/cloud-3rdparty-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_3rdparty_s3_kms_policy.arn
      description = "Cloud 3rdparty S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-connections-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_connections_s3_kms_policy.arn
      description = "Cloud Connections S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-lambda-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_lambda_s3_kms_policy.arn
      description = "Cloud Lambda S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-logs-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_logs_s3_kms_policy.arn
      description = "Cloud Logs S3 bucket KMS policy ARN"
    },

    {
      name        = "/central/iam/policies/cloud-templates-s3-kms-policy/arn"
      value       = aws_iam_policy.cloud_templates_s3_kms_policy.arn
      description = "Cloud Templates S3 bucket KMS policy ARN"
    }
  ]
}