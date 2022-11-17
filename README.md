Configures a domain hosted on Route53 to work with AWS Simple Email Service (SES).

## Prerequisites

- Ensure [terraform](https://www.terraform.io/intro/getting-started/install.html) is installed
- Ensure domain is registered in [route53](https://aws.amazon.com/route53/)
- Ensure an s3 bucket exists and SES has write permissions to it
- If you have an existing rule set you can skip creating the dependent resource
- Route53 zone id can be obtained by looking up the domain in route53 service

## Getting Started

1. Import the module called `ses_domain` and update its source property to `trussworks/ses-domain/aws` and run `terrafrom init`
2. The next step is to configure the module with [minimum values](#usage) for SES to start working
3. Once fully configured run `terraform plan` to see the execution plan and `terrafrom apply` to stand up SES

Creates the following resources:

- MX record pointing to AWS's SMTP endpoint
- TXT record for SPF validation
- Custom MAIL FROM domain
- CNAME records for DKIM verification
- SES Verfication for the domain

### NOTES

- SES is only available in a [limited number of AWS Regions](https://docs.aws.amazon.com/general/latest/gr/ses.html).
- SES out of the box locks the service in development mode; please see this documentation on how to make it production ready. Until the service is in production mode you can only send emails to confirmed email accounts denoted in `from_addresses`

## Terraform Versions

Terraform 0.13 and newer. Pin module version to ~> 3.X. Submit pull-requests to master branch.

Terraform 0.12. Pin module version to ~> 2.X. Submit pull-requests to terraform012 branch.

## Usage

See [examples](examples/) for functional examples on how to use this module.

```hcl
module "ses_domain" {
  source             = "trussworks/ses-domain/aws"
  domain_name        = "example.com"
  mail_from_domain   = "email.example.com"
  route53_zone_id    = data.aws_route53_zone.ses_domain.zone_id
  from_addresses     = ["email1@example.com", "email2@example.com"]
  dmarc_rua          = "something@example.com"
  receive_s3_bucket  = "S3_bucket_with_write_permissions"
  receive_s3_prefix  = "path_to_store_received_emails"
  ses_rule_set       = "name-of-the-ruleset"
}

resource "aws_ses_receipt_rule_set" "name-of-the-ruleset" {
  rule_set_name = "name-of-the-ruleset"
}

data "aws_route53_zone" "ses_domain" {
  name = "example.com"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 0.13.0 |
| aws       | >= 3.0    |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | >= 3.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                      | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_route53_record.dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                     | resource    |
| [aws_route53_record.mx_receive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                               | resource    |
| [aws_route53_record.mx_send_mail_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                        | resource    |
| [aws_route53_record.ses_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                         | resource    |
| [aws_route53_record.spf_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                               | resource    |
| [aws_route53_record.spf_mail_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                            | resource    |
| [aws_route53_record.txt_dmarc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                | resource    |
| [aws_ses_domain_dkim.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_dkim)                                   | resource    |
| [aws_ses_domain_identity.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity)                           | resource    |
| [aws_ses_domain_identity_verification.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity_verification) | resource    |
| [aws_ses_domain_mail_from.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_mail_from)                         | resource    |
| [aws_ses_receipt_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule)                                 | resource    |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                               | data source |

## Inputs

| Name                   | Description                                                                                            | Type           | Default  | Required |
| ---------------------- | ------------------------------------------------------------------------------------------------------ | -------------- | -------- | :------: |
| dmarc_p                | DMARC Policy for organizational domains (none, quarantine, reject).                                    | `string`       | `"none"` |    no    |
| dmarc_rua              | DMARC Reporting URI of aggregate reports, expects an email address.                                    | `string`       | n/a      |   yes    |
| domain_name            | The domain name to configure SES.                                                                      | `string`       | n/a      |   yes    |
| enable_dmarc           | Control whether to create DMARC TXT record.                                                            | `bool`         | `true`   |    no    |
| enable_incoming_email  | Control whether or not to handle incoming emails.                                                      | `bool`         | `true`   |    no    |
| enable_spf_record      | Control whether or not to set SPF records.                                                             | `bool`         | `true`   |    no    |
| enable_verification    | Control whether or not to verify SES DNS records.                                                      | `bool`         | `true`   |    no    |
| extra_ses_records      | Extra records to add to the \_amazonses TXT record.                                                    | `list(string)` | `[]`     |    no    |
| from_addresses         | List of email addresses to catch bounces and rejections.                                               | `list(string)` | `null`   |    no    |
| mail_from_domain       | Subdomain (of the route53 zone) which is to be used as MAIL FROM address                               | `string`       | n/a      |   yes    |
| receive_s3_bucket      | Name of the S3 bucket to store received emails (required if enable_incoming_email is true).            | `string`       | `""`     |    no    |
| receive_s3_kms_key_arn | The ARN of the KMS key for S3 objects of received emails (effective if enable_incoming_email is true). | `string`       | `null`   |    no    |
| receive_s3_prefix      | The key prefix of the S3 bucket to store received emails (required if enable_incoming_email is true).  | `string`       | `""`     |    no    |
| route53_zone_id        | Route53 host zone ID to enable SES.                                                                    | `string`       | n/a      |   yes    |
| ses_rule_set           | Name of the SES rule set to associate rules with.                                                      | `string`       | n/a      |   yes    |

## Outputs

| Name                   | Description                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| ses_identity_arn       | SES identity ARN.                                                                                                                                |
| ses_verification_token | A code which when added to the domain as a TXT record will signal to SES that the owner of the domain has authorised SES to act on their behalf. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Developer Setup

Install dependencies (macOS)

```shell
brew install pre-commit go terraform terraform-docs
```
