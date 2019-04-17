output "ses_identity_arn" {
  description = "The created SES identity arn."
  value       = "${aws_ses_domain_identity.main.arn}"
}
