locals {
  efs_volume_name = "Xgemail-Policy-EFS"

  DEFAULT_THROUGHPUT_MODE                 = "bursting"
  DEFAULT_PROVISIONED_THROUGHPUT_IN_MIBPS = "0"

  THROUGHPUT_MODE_BY_ENVIRONMENT = {
    qa   = "provisioned"
    prod = "provisioned"
  }

  PROVISIONED_THROUGHPUT_IN_MIBPS_BY_ENVIRONMENT = {
    qa   = 5
    prod = 10
  }
}

resource "aws_efs_file_system" "xgemail-policy-efs-volume" {

  encrypted        = "true"
  performance_mode = "generalPurpose"

  throughput_mode = lookup(
    local.THROUGHPUT_MODE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_THROUGHPUT_MODE
  )

  provisioned_throughput_in_mibps = lookup(
    local.PROVISIONED_THROUGHPUT_IN_MIBPS_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_PROVISIONED_THROUGHPUT_IN_MIBPS
  )

  tags = {
    Name = local.efs_volume_name
  }
}