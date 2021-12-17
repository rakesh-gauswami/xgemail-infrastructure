variable "ami_branch" {
  type        = string
  description = "AMI Bitbucket branch"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}