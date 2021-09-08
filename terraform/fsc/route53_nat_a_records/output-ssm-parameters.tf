locals {
  ssm_root_path = "/central/vpc"
}

module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "${local.ssm_root_path}/nat_public_ip_a"
      value       = local.nat_public_ip_a
      description = "AZ A NAT Gateway Public IP"
    },

    {
      name        = "${local.ssm_root_path}/nat_public_ip_b"
      value       = local.nat_public_ip_b
      description = "AZ B NAT Gateway Public IP"
    },

    {
      name        = "${local.ssm_root_path}/nat_public_ip_c"
      value       = local.nat_public_ip_c
      description = "AZ C NAT Gateway Public IP"
    },

    {
      name        = "${local.ssm_root_path}/nat_dns_record_a"
      value       = local.nat_dns_record_a
      description = "AZ A NAT Gateway DNS A Record"
    },

    {
      name        = "${local.ssm_root_path}/nat_dns_record_b"
      value       = local.nat_dns_record_b
      description = "AZ B NAT Gateway DNS A Record"
    },

    {
      name        = "${local.ssm_root_path}/nat_dns_record_c"
      value       = local.nat_dns_record_c
      description = "AZ C NAT Gateway DNS A Record"
    }
  ]
}
