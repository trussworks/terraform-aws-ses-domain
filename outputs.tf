output "ses_identity_arn" {
  description = "SES identity ARN."
  value       = aws_sesv2_email_identity.main.arn
}
