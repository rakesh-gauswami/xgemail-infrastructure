
variable "parameters" {
  type = list(object({
    name        = string
    value       = string
    description = string
  }))

  description = "tuples of parameters to drop into the parameter store"
}
