data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

#
# SES Ruleset
#

# SES only allows one (just like Highlander and Lord of the Rings) rule set to
# be active at any point in time. So this will live in the app-global state file.
locals {
  ses_bucket_prefix       = "ses"
  infra_test_truss_coffee = "infra-test.truss.coffee"
  temp_domain             = "${var.test_name}.${local.infra_test_truss_coffee}"
}

resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = var.test_name
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
}

#
# S3 bucket for receiving bounces
#

data "aws_iam_policy_document" "s3_allow_ses_puts" {
  statement {
    sid    = "allow-ses-puts"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.ses_bucket}/${local.ses_bucket_prefix}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:Referer"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "ses_bucket" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 2"

  bucket                   = var.ses_bucket
  use_account_alias_prefix = false
  custom_bucket_policy     = data.aws_iam_policy_document.s3_allow_ses_puts.json
  logging_bucket           = module.s3_logs.aws_logs_bucket
}

#
# S3 Logging Bucket
#

module "s3_logs" {
  source  = "trussworks/logs/aws"
  version = "~> 4"

  s3_bucket_name = "${var.test_name}-logs"
  region         = var.region

  default_allow = false
}

#
# Route53
#

data "aws_route53_zone" "infra_test_truss_coffee" {
  name = local.infra_test_truss_coffee
}

resource "aws_route53_zone" "temp_domain" {
  name = local.temp_domain
}

resource "aws_route53_record" "temp_domain_ns_records" {
  zone_id = data.aws_route53_zone.infra_test_truss_coffee.zone_id
  name    = local.temp_domain
  type    = "NS"
  ttl     = "30"

  records = aws_route53_zone.temp_domain.name_servers
}

#
# SES Domain
#

module "ses_domain" {
  source = "../../"

  domain_name     = local.temp_domain
  route53_zone_id = aws_route53_zone.temp_domain.zone_id

  from_addresses   = ["no-reply@${local.temp_domain}"]
  mail_from_domain = "email.${local.temp_domain}"

  dmarc_rua = "email@hurts.com"

  receive_s3_bucket = module.ses_bucket.id
  receive_s3_prefix = local.ses_bucket_prefix

  ses_rule_set = aws_ses_receipt_rule_set.main.rule_set_name
}
