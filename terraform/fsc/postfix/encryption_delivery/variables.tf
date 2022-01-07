variable "build_branch" {
  type        = string
  description = "Bitbucket Branch"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
