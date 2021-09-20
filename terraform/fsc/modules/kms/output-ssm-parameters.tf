locals {
  kms_alias_path = "${var.ssm_root_path}/kms/alias"
  kms_key_path   = "${var.ssm_root_path}/kms/key"
}

module "output_string_parameters" {
  source = "../output_string_parameters"
  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = local.kms_alias_path
      value       = aws_kms_alias.alias.arn
      description = "KMS alias ARN"
    },

    {
      name        = local.kms_key_path
      value       = aws_kms_key.key.arn
      description = "KMS key ARN"
    }
  ]
}
