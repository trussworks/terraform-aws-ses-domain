variable "test_name" {
  type = string
}

variable "region" {
  type = string
}

variable "ses_bucket" {
  type = string
}

variable "enable_spf_record" {
  type = bool
}

variable "extra_ses_records" {
  type    = list(string)
  default = []
}