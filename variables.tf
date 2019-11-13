variable "dmarc_rua" {
  description = "Email address for capturing DMARC aggregate reports."
  type        = string
}

variable "domain_name" {
  description = "The domain name to configure SES."
  type        = string
}

variable "enable_verification" {
  description = "Control whether or not to verify SES DNS records."
  type        = string
  default     = true
}

variable "from_addresses" {
  description = "List of email addresses to catch bounces and rejections"
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
  description = "Control whether or not to handle incoming emails"
  type        = "string"
  default     = true
}

variable "custom_spf" {
  description = "If you use other third-party email services, you might use this to ensure you only have a single DNS SPF record"
  type        = "string"
  default     = "v=spf1 include:amazonses.com -all"
}

