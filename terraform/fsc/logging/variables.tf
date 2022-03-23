# vim: autoindent expandtab shiftwidth=2 filetype=terraform

variable "analytics_account_id" {
  default = "108865061851"
}

variable "analytics_session_duration" {
  # 5 hours
  default = 18000
}

variable "logs_transition_days" {
  type    = number
  default = 30
}

variable "elb_logs_transition_days" {
  type    = number
  default = 185
}

variable "logs_expiration_days" {
  type    = number
  default = 365
}

variable "stream_buffer_interval" {
  type    = number
  default = 60
}

variable "stream_buffer_size" {
  type    = number
  default = 50
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
