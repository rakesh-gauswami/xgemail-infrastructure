variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}

variable "pop_name" {
  description = "Email PoP Account Name for S3 buckets"
  default     = "eml000cmh"
}