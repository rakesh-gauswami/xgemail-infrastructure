locals {
  eip_rotation_prefix = "log-shipping-firehose-stream-"
  stream_name   = "${local.eip_rotation_prefix}${local.input_param_primary_region}-${local.input_param_account_type}"
}