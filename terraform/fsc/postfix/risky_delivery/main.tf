
locals {
  account_id = data.aws_caller_identity.current.account_id
  instance_type = "risky-delivery"
}

data "aws_caller_identity" "current" {}
