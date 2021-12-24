variable "ami_branch" {
  type        = string
  description = "AMI Bitbucket branch"
}

variable "build_branch" {
  type        = string
  description = "Bitbucket Branch"
}

variable "build_number" {
  type        = string
  description = "Build Number"
}

variable "build_result_key" {
  type        = string
  description = "Build Result Key"
}


variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}