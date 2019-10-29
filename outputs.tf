output "ses_identity_arn" {
  description = "SES identity ARN."
  value       = aws_ses_domain_identity.main.arn
}
