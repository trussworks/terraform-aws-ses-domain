<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Configures a domain hosted on Route53 to work with AWS Simple Email Service (SES)

Creates the following resources:

* MX record pointing to AWS's SMTP endpoint
* TXT record for SPF validation
* Custom MAIL FROM domain
* CNAME records for DKIM verification
* SES Verfication for the domain

NOTE: SES is only available in us-east-1, us-west-2, and eu-west-1

## Usage

```hcl
module "ses_domain" {
  source = "../../modules/aws-ses-domain"

  domain_name      = "example.com"
  mail_from_domain = "email.example.com"
  route53_zone_id  = "Z123456789"
}
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| domain_name | The domain name to configure SES. | string | - | yes |
| enable_verification | Control whether or not to verify SES DNS records. | string | `true` | no |
| mail_from_domain | Subdomain (of the route53 zone) which is to be used as MAIL FROM address | string | - | yes |
| route53_zone_id | Route53 host zone ID to enable SES. | string | - | yes |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
