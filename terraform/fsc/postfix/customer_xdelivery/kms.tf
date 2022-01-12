module "kms_key" {
  source = "../../modules/kms"

  providers = {
    aws            = aws
    aws.parameters = aws.parameters
  }

  alias         = "${local.instance_type}/ebs"
  description   = "encryption key for <${local.instance_type}>"
  ssm_root_path = "/central/asg/${local.instance_type}/ebs"
}
