/**
 * Configures a domain hosted on Route53 to work with AWS Simple Email Service (SES)
 *
 * Creates the following resources:
 *
 * * MX record pointing to AWS's SMTP endpoint
 * * TXT record for SPF validation
 * * Custom MAIL FROM domain
 * * CNAME records for DKIM verification
 * * SES Verfication for the domain
 *
 * NOTE: SES is only available in us-east-1, us-west-2, and eu-west-1
 *
 * ## Usage
 *
 * ```hcl
 * module "ses_domain" {
 *   source = "../../modules/aws-ses-domain"
 *
 *   domain_name      = "example.com"
 *   mail_from_domain = "email.example.com"
 *   route53_zone_id  = "Z123456789"
 * }
 * ```
 */

locals {
  # some ses resources don't allow for the terminating '.' in the domain name
  # so use a replace function to strip it out
  stripped_domain_name = "${replace(var.domain_name, "/[.]$/", "")}"

  stripped_mail_from_domain = "${replace(var.mail_from_domain, "/[.]$/", "")}"
  dash_domain               = "${replace(var.domain_name, ".", "-")}"
}

#
# SES Domain Verification
#

resource "aws_ses_domain_identity" "main" {
  domain = "${local.stripped_domain_name}"
}

resource "aws_ses_domain_identity_verification" "main" {
  count = "${var.enable_verification ? 1 : 0}"

  domain = "${aws_ses_domain_identity.main.id}"

  depends_on = ["aws_route53_record.ses_verification"]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = "${var.route53_zone_id}"
  name    = "_amazonses.${aws_ses_domain_identity.main.id}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.main.verification_token}"]
}

#
# SES DKIM Verification
#

resource "aws_ses_domain_dkim" "main" {
  domain = "${aws_ses_domain_identity.main.domain}"
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = "${var.route53_zone_id}"
  name    = "${format("%s._domainkey.%s", element(aws_ses_domain_dkim.main.dkim_tokens, count.index), var.domain_name)}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

#
# SES MAIL FROM Domain
#

resource "aws_ses_domain_mail_from" "main" {
  domain           = "${aws_ses_domain_identity.main.domain}"
  mail_from_domain = "${local.stripped_mail_from_domain}"
}

# SPF validaton record
resource "aws_route53_record" "spf_mail_from" {
  zone_id = "${var.route53_zone_id}"
  name    = "${aws_ses_domain_mail_from.main.mail_from_domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# Sending MX Record
data "aws_region" "current" {}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = "${var.route53_zone_id}"
  name    = "${aws_ses_domain_mail_from.main.mail_from_domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

# Receiving MX Record
resource "aws_route53_record" "mx_receive" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.domain_name}"
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}

#
# SES Receipt Rule
#

resource "aws_ses_receipt_rule" "main" {
  name          = "${format("%s-s3-rule", local.dash_domain)}"
  rule_set_name = "${var.ses_rule_set}"
  recipients    = ["${var.from_addresses}"]
  enabled       = true
  scan_enabled  = true

  s3_action {
    position = 1

    bucket_name       = "${var.receive_s3_bucket}"
    object_key_prefix = "${var.receive_s3_prefix}"
  }
}
