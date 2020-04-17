variable "dmarc_p" {
  description = "DMARC Policy for organizational domains (none, quarantine, reject)."
  type        = string
  default     = "none"

  validation {
    condition     = var.dmarc_p == "none" || var.dmarc_p == "quarantine" || var.dmarc_p == "reject"
    error_message = "This module only supports only policy domains none, quarantine, and reject."
  }
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
}

variable "mail_from_domain" {
  description = " Subdomain (of the route53 zone) which is to be used as MAIL FROM address"
  type        = string
}

variable "receive_s3_bucket" {
  description = "Name of the S3 bucket to store received emails."
  type        = string
}

variable "receive_s3_prefix" {
  description = "The key prefix of the S3 bucket to store received emails."
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 host zone ID to enable SES."
  type        = string
}

variable "ses_rule_set" {
  description = "Name of the SES rule set to associate rules with."
  type        = string
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
