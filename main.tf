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

resource "aws_sesv2_email_identity" "main" {
  email_identity = local.stripped_domain_name
}

#
# SES DKIM Verification
#

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.route53_zone_id
  name    = "${aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]

  depends_on = [aws_sesv2_email_identity.main]
}

#
# SES MAIL FROM Domain
#

resource "aws_sesv2_email_identity_mail_from_attributes" "main" {
  email_identity   = aws_sesv2_email_identity.main.email_identity
  mail_from_domain = local.stripped_mail_from_domain

  depends_on = [aws_sesv2_email_identity.main]
}

# SPF validation record
resource "aws_route53_record" "spf_mail_from" {
  count = var.enable_spf_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.main.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# Sending MX Record
data "aws_region" "current" {
}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = var.route53_zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.main.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

# Receiving MX Record
resource "aws_route53_record" "mx_receive" {
  count = var.enable_incoming_email ? 1 : 0

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
  count = var.enable_dmarc ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1; p=${var.dmarc_p}; rua=mailto:${var.dmarc_rua};"]
}

#
# SES Receipt Rule
#

resource "aws_ses_receipt_rule" "main" {
  count = var.enable_incoming_email ? 1 : 0

  name          = format("%s-s3-rule", local.dash_domain)
  rule_set_name = var.ses_rule_set
  recipients    = var.from_addresses
  enabled       = true
  scan_enabled  = true

  s3_action {
    position = 1

    bucket_name       = var.receive_s3_bucket
    object_key_prefix = var.receive_s3_prefix
    kms_key_arn       = var.receive_s3_kms_key_arn
  }
}
