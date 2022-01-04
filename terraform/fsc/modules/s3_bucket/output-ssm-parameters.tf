locals {
  ssm_root_path = "/central/s3/${var.bucket_name}"

  bucket_arn_path  = "${local.ssm_root_path}/arn"
  bucket_name_path = "${local.ssm_root_path}/name"

  bucket_full_name = aws_s3_bucket.bucket.id
}

module "output_string_parameters" {
  source = "../output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = local.bucket_arn_path
      value       = aws_s3_bucket.bucket.arn
      description = "Bucket ARN of <${local.bucket_full_name}> bucket"
    },

    {
      name        = local.bucket_name_path
      value       = local.bucket_full_name
      description = "Bucket name of <${local.bucket_full_name}> bucket"
    }
  ]
}
