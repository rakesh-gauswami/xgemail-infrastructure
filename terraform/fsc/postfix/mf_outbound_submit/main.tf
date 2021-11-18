
locals {
  account_id = data.aws_caller_identity.current.account_id
  instance_type = "mf-outbound-submit"
}

data "aws_caller_identity" "current" {}
