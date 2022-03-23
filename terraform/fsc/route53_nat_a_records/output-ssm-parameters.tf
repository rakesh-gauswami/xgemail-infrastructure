module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/vpc/nat-public-ip-a"
      value       = local.nat_public_ip_a
      description = "AZ A NAT Gateway Public IP"
    },

    {
      name        = "/central/vpc/nat-public-ip-b"
      value       = local.nat_public_ip_b
      description = "AZ B NAT Gateway Public IP"
    },

    {
      name        = "/central/vpc/nat-public-ip-c"
      value       = local.nat_public_ip_c
      description = "AZ C NAT Gateway Public IP"
    },

    {
      name        = "/central/vpc/nat-dns-record-a"
      value       = local.nat_dns_record_a
      description = "AZ A NAT Gateway DNS A Record"
    },

    {
      name        = "/central/vpc/nat-dns-record-b"
      value       = local.nat_dns_record_b
      description = "AZ B NAT Gateway DNS A Record"
    },

    {
      name        = "/central/vpc/nat-dns-record-c"
      value       = local.nat_dns_record_c
      description = "AZ C NAT Gateway DNS A Record"
    }
  ]
}
