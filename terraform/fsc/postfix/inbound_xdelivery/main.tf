
locals {
  account_id = data.aws_caller_identity.current.account_id
  instance_type = "inbound-xdelivery"
}

data "aws_caller_identity" "current" {}
