
module "kms_key" {
  count = var.should_create_kms_key ? 1 : 0

  source = "../kms"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  alias         = local.ssm_root_path
  description   = "S3 bucket encryption key for <${var.bucket_name}> bucket"
  ssm_root_path = local.ssm_root_path
}
