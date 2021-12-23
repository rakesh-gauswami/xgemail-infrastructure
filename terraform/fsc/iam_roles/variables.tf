variable "encryption_instances_instance_role_arn" {
  type        = string
  description = "The Encryption Instances Instance Role Arn"
}

variable "inbound_delivery_instance_role_arn" {
  type        = string
  description = "The Inbound Delivery Instance Role Arn"
}

variable "inbound_submit_instance_role_arn" {
  type        = string
  description = "The Inbound Submit Instance Role Arn"
}

variable "outbound_delivery_instance_role_arn" {
  type        = string
  description = "The Outbound Delivery Instance Role Arn"
}

variable "outbound_submit_instance_role_arn" {
  type        = string
  description = "The Outbound Submit Instance Role Arn"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
