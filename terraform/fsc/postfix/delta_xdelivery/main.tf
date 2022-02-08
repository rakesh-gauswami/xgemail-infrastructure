
locals {
  account_id    = data.aws_caller_identity.current.account_id
  instance_type = "delta-xdelivery"
}

data "aws_caller_identity" "current" {}
