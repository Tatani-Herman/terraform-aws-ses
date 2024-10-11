output "arn" {
  value = aws_ses_domain_identity.main.arn
}

output "configuration_set" {
  value = {
    name = aws_ses_configuration_set.main.name
    arn  = aws_ses_configuration_set.main.arn
  }
}
