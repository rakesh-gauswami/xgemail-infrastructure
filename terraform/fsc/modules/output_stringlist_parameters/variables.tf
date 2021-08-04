
variable "parameters" {
  type = list(object({
    name        = string
    value       = list(string)
    description = string
  }))

  description = "tuples of list parameters to drop into the parameter store"
}
