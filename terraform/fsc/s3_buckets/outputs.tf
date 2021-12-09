output "zzz_output_parameter_names" {
  value = keys(
  merge(
  module.output_string_parameters.parameters,
  module.cloud_3rdparty_bucket.output_parameters,
  module.cloud_configs_bucket.output_parameters,
  module.cloud_connections_bucket.output_parameters,
  module.cloud_lambda_bucket.output_parameters,
  module.cloud_logs_bucket.output_parameters
  )
  )
}
