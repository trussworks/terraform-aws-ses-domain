data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}
data "aws_partition" "current" {}

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

resource "aws_s3_bucket" "temp_bucket" {
  bucket        = var.ses_bucket
  acl           = "private"
  force_destroy = true
  policy        = data.aws_iam_policy_document.s3_allow_ses_puts.json

  logging {
    target_bucket = module.s3_logs.aws_logs_bucket
    target_prefix = "s3/${var.ses_bucket}/"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.temp_bucket.id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

#
# S3 Logging Bucket
#

module "s3_logs" {
  source  = "trussworks/logs/aws"
  version = "~> 8"

  s3_bucket_name = "${var.test_name}-logs"

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

resource "aws_route53_record" "temp_spf" {
  count   = var.enable_spf_record ? 0 : 1
  zone_id = aws_route53_zone.temp_domain.zone_id
  name    = local.temp_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:_spf.google.com include:servers.mcsv.net ~all"]
}

resource "aws_route53_record" "temp_verification" {
  count   = var.enable_verification ? 0 : 1
  zone_id = aws_route53_zone.temp_domain.zone_id
  name    = "_amazonses.${local.temp_domain}"
  type    = "TXT"
  ttl     = "600"
  records = [var.test_name]
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

  receive_s3_bucket   = aws_s3_bucket.temp_bucket.id
  receive_s3_prefix   = local.ses_bucket_prefix
  enable_verification = var.enable_verification
  enable_spf_record   = var.enable_spf_record
  extra_ses_records   = var.extra_ses_records


  ses_rule_set = aws_ses_receipt_rule_set.main.rule_set_name
}
