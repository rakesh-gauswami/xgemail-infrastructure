
locals {
  account_id = data.aws_caller_identity.current.account_id
  instance_type = "customer-submit"
}

data "aws_caller_identity" "current" {}
