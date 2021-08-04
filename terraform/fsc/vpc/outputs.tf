##################################################################################
# Outputs
##################################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_full_name" {
  value = local.vpc_full_name
}

output "default_security_group_id" {
  value = module.vpc.default_security_group_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  value = module.vpc.public_subnets_cidr_blocks
}

output "igw_id" {
  value = module.vpc.igw_id
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
