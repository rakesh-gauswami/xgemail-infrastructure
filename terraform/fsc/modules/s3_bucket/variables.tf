variable "bucket_name" {
  type        = string
  description = "Name name with PoP account number.  Will be used in SSM parameter store"
}

variable "enable_versioning" {
  type = bool

  default = false
}

variable "force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"

  default = false
}

variable "lifecycle_rules" {
  type = list(object({
    id      = string,
    enabled = bool

    # If you don't want prefix set it to null
    selector_prefix = string
    # If you don't want tags set it to null
    selector_tags = map(string)

    abort_incomplete_multipart_upload_days = number

    # If you don't want to define expiration rules, set this to []
    expiration = list(object({
      date                         = string
      days                         = number
      expired_object_delete_marker = bool
    }))

    # If you don't want to define noncurrent_version_expiration rules, set this to []
    noncurrent_version_expiration = list(object({
      days = number
    }))

    # If you don't want to define noncurrent_version_transition rules, set this to []
    noncurrent_version_transition = list(object({
      days          = number
      storage_class = string
    }))

    # If you don't want to define transition rules, set this to []
    transition = list(object({
      date          = string
      days          = number
      storage_class = string
    }))
  }))

  default = []
}

variable "logging_target_bucket" {
  type        = string
  description = "The name of the bucket that will receive the log objects"
  default     = null
}

variable "logging_target_prefix" {
  type        = string
  description = "Specifies a key prefix for log objects."
  default     = null
}

variable "should_block_public_access" {
  type        = bool
  description = "Whether any kind of public access to the objects in this bucket should be blocked"
  default     = true
}

variable "should_create_kms_key" {
  type        = bool
  description = "Whether to create corresponding kms key or use Amazon S3-managed keys (SSE-S3)"
  default     = true
}
