variable "test_name" {
  type = string
}

variable "ses_bucket" {
  type = string
}

variable "enable_verification" {
  type = bool
}

variable "enable_spf_record" {
  type = bool
}

variable "extra_ses_records" {
  type    = list(string)
  default = []
}

variable "rule_set" {
  description = "Name of the SES rule set to associate rules with."
  type        = string
  default     = null
}

variable "addresses" {
  description = "List of email addresses to catch bounces and rejections."
  type        = string
  default     = null
}

variable "enable_incoming_email" {
  description = "Boolean value of weather incoming email should be enabled or not"
  type        = bool
  default     = true
}
