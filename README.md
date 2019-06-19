<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| dmarc\_rua | Email address for capturing DMARC aggregate reports. | string | n/a | yes |
| domain\_name | The domain name to configure SES. | string | n/a | yes |
| enable\_verification | Control whether or not to verify SES DNS records. | string | `"true"` | no |
| from\_addresses | List of email addresses to catch bounces and rejections | list(string) | n/a | yes |
| mail\_from\_domain | Subdomain (of the route53 zone) which is to be used as MAIL FROM address | string | n/a | yes |
| receive\_s3\_bucket | Name of the S3 bucket to store received emails. | string | n/a | yes |
| receive\_s3\_prefix | The key prefix of the S3 bucket to store received emails. | string | n/a | yes |
| route53\_zone\_id | Route53 host zone ID to enable SES. | string | n/a | yes |
| ses\_rule\_set | Name of the SES rule set to associate rules with. | string | n/a | yes |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
