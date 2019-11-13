/**
 * Configures a domain hosted on Route53 to work with AWS Simple Email Service (SES).
 *
 * ## Prerequisites
 *
 * * Ensure [terraform](https://www.terraform.io/intro/getting-started/install.html) is installed
 * * Ensure domain is registered in [route53](https://aws.amazon.com/route53/)
 * * Ensure an s3 bucket exists and SES has write permissions to it
 * * If you have an existing rule set you can skip creating the dependent resource
 * * Route53 zone id can be obtained by looking up the domain in route53 service
 *
 * ## Getting Started
 *
 * 1. Import the module called `ses_domain` and update its source property to `trussworks/ses-domain/aws` and run `terrafrom init`
 * 2. The next step is to configure the module with [minimum values](#usage) for SES to start working
 * 3. Once fully configured run `terraform plan` to see the execution plan and `terrafrom apply` to stand up SES
 *
 * Creates the following resources:
 *
 * * MX record pointing to AWS's SMTP endpoint
 * * TXT record(s) for SPF validation
 * * Custom MAIL FROM domain
 * * CNAME records for DKIM verification
 * * SES Verfication for the domain
 *
 * ### NOTES
 *
 * * SES is only available in us-east-1, us-west-2, and eu-west-1
 * * SES out of the box locks the service in development mode; please see this documentation on how to make it production ready. Until the service is in production mode you can only send emails to confirmed email accounts denoted in `from_addresses`
 *
 * ## Usage
 *
 * ```hcl
 * module "ses_domain" {
 *   source             = "trussworks/ses-domain/aws"
 *   domain_name        = "example.com"
 *   mail_from_domain   = "email.example.com"
 *   route53_zone_id    = data.aws_route53_zone.SES_domain.zone_id
 *   from_addresses     = ["email1@example.com", "email2@example.com"]
 *   dmarc_rua          = "something@example.com"
 *   receive_s3_bucket  = "S3_bucket_with_write_permissions"
 *   receive_s3_prefix  = "path_to_store_recieved_emails"
 *   ses_rule_set       = "name-of-the-ruleset"
 * }
 *
 * resource "aws_ses_receipt_rule_set" "name-of-the-ruleset" {
 *   rule_set_name = "name-of-the-ruleset"
 * }
 *
 * data "aws_route53_zone" "SES_domain" {
 *   name = "example.com"
 * }
 * ```
 */

locals {
  # some ses resources don't allow for the terminating '.' in the domain name
  # so use a replace function to strip it out
  stripped_domain_name = replace(var.domain_name, "/[.]$/", "")

  stripped_mail_from_domain = replace(var.mail_from_domain, "/[.]$/", "")
  dash_domain               = replace(var.domain_name, ".", "-")
}

#
# SES Domain Verification
#

resource "aws_ses_domain_identity" "main" {
  domain = local.stripped_domain_name
}

resource "aws_ses_domain_identity_verification" "main" {
  count = var.enable_verification ? 1 : 0

  domain = aws_ses_domain_identity.main.id

  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.main.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.main.verification_token]
}

#
# SES DKIM Verification
#

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name = format(
    "%s._domainkey.%s",
    element(aws_ses_domain_dkim.main.dkim_tokens, count.index),
    var.domain_name,
  )
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

#
# SES MAIL FROM Domain
#

resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = local.stripped_mail_from_domain
}

# SPF validaton record
resource "aws_route53_record" "spf_mail_from" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["${var.custom_spf}"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = "600"
  records = ["${var.custom_spf}"]
}

# Sending MX Record
data "aws_region" "current" {
}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

# Receiving MX Record
resource "aws_route53_record" "mx_receive" {
  count   = var.enable_incoming_email ? 1 : 0
  name    = var.domain_name
  zone_id = var.route53_zone_id
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}

#
# DMARC TXT Record
#
resource "aws_route53_record" "txt_dmarc" {
  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1; p=none; rua=mailto:${var.dmarc_rua};"]
}

#
# SES Receipt Rule
#

resource "aws_ses_receipt_rule" "main" {
  name          = format("%s-s3-rule", local.dash_domain)
  count         = var.enable_incoming_email ? 1 : 0
  rule_set_name = var.ses_rule_set
  recipients    = var.from_addresses
  enabled       = true
  scan_enabled  = true

  s3_action {
    position = 1

    bucket_name       = var.receive_s3_bucket
    object_key_prefix = var.receive_s3_prefix
  }
}

