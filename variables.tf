variable "dmarc_p" {
  description = "DMARC Policy for organizational domains (none, quarantine, reject)."
  type        = string
  default     = "none"
}

variable "dmarc_rua" {
  description = "DMARC Reporting URI of aggregate reports, expects an email address."
  type        = string
}

variable "domain_name" {
  description = "The domain name to configure SES."
  type        = string
}

variable "enable_verification" {
  description = "Control whether or not to verify SES DNS records."
  type        = bool
  default     = true
}

variable "from_addresses" {
  description = "List of email addresses to catch bounces and rejections."
  type        = list(string)
  default     = null
}

variable "mail_from_domain" {
  description = " Subdomain (of the route53 zone) which is to be used as MAIL FROM address"
  type        = string
}

variable "receive_s3_bucket" {
  description = "Name of the S3 bucket to store received emails (required if enable_incoming_email is true)."
  type        = string
  default     = ""
}

variable "receive_s3_prefix" {
  description = "The key prefix of the S3 bucket to store received emails (required if enable_incoming_email is true)."
  type        = string
  default     = ""
}

variable "receive_s3_kms_key_arn" {
  description = "The ARN of the KMS key for S3 objects of received emails (effective if enable_incoming_email is true)."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 host zone ID to enable SES."
  type        = string
}

variable "ses_rule_set" {
  description = "Name of the SES rule set to associate rules with."
  type        = string
  default     = null
}

variable "enable_incoming_email" {
  description = "Control whether or not to handle incoming emails."
  type        = bool
  default     = true
}

variable "enable_spf_record" {
  description = "Control whether or not to set SPF records."
  type        = bool
  default     = true
}

variable "extra_ses_records" {
  description = "Extra records to add to the _amazonses TXT record."
  type        = list(string)
  default     = []
}
