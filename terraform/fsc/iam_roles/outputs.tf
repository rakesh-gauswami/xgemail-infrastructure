output "zzz_output_parameter_names" {
  value = keys(
    merge(
      module.output_string_parameters.parameters
    )
  )
}
