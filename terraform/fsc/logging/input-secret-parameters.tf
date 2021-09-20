locals {
  input_secret_api_token = module.api_token_secret.secret_string
}

module "api_token_secret" {
  source = "../modules/secret"

  providers = {
    aws = aws
  }

  secret_id = "/central/logging/api-token"
}
