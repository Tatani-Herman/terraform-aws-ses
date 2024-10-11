# terraform-aws-ses
This Terraform module sets up an Amazon SES (Simple Email Service) identity, including DKIM, configuration sets, and optional bounce and complaint monitoring with SNS and CloudWatch. It follows best practices for managing email domains, handling bounces and complaints, and monitoring SES reputation.


## Features

- **SES Domain Identity**: Creates an SES domain identity and enables DKIM for email authentication.
- **TLS Policy**: Configures TLS policy for email delivery (optional or enforced).
- **Verified Email Identities**: Adds SES email identities for sandbox environments.
- **Bounce/Complaint Remediation**: (Optional) Sets up SNS topics and Lambda for automatic handling of bounces and complaints.
- **CloudWatch Alarms**: (Optional) Monitors SES bounce and complaint rates using CloudWatch alarms.
- **Route53 DNS Records**: Configures DKIM, MX, and SPF records for the domain in Route 53.


## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.9 |
| aws | >= 5.70.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.70.0 |


## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ses_domain_identity.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity) | resource |
| [aws_ses_domain_dkim.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_dkim) | resource |
| [aws_ses_configuration_set.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_configuration_set) | resource |
| [aws_ses_email_identity.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_email_identity) | resource |
| [aws_route53_record.dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mail_mx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mail_txt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_iam_policy_document.sns_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_sns_topic_subscription.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_ses_event_destination.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_event_destination) | resource |
| [aws_sns_topic_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_cloudwatch_metric_alarm.ses_bounce_rate_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ses_complaint_rate_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_event_rule.ses_reputation_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| route53_zone | Route 53 Zone to add the subdomain | ```object({ id = string name = string })``` | n/a | yes |
| domain | The domain of the SES identity | `string` | n/a | yes |
| tls_policy | TLS policy used on the ses configuration set | `string` | `"Optional"` | no |
| monitor_reputation | Used to conditionally monitor or not the SES account reputation | `bool` | `false` | no |
| ses_reputation_monitoring_topic | SNS topic ARN used to receive cloudwatch alarms changes monitoring SES bounces and complaints | `string` | n/a | no |
| bounce_complaint_remediation_topic | SNS topic ARN used to receive bounces and complaints from SES configuration set | `string` | n/a | no |
| remediation_lambda | Lambda ARN used to process bounces and complaints from the SNS topic | `string` | n/a | no |
| alarm_period | Period for CloudWatch alarms | `number` | `3600` | no |
| verified_emails | List of authorized emails to receive emails (Only if ses stay in sandbox mode). | `set(string)` | `[]` | no |


## Outputs

| Name | Description |
|------|-------------|
| arn | SES domain identity ARN |
| configuration_set | Object representing SES configuration set name and arn |


## Usage

```hcl
module "ses" {
  source                             = "./terraform-aws-ses"
  domain                             = "example.com"
  route53_zone                       = { id = "Z1234567890", name = "example.com" }
  tls_policy                         = "Require"
  monitor_reputation                 = true
  ses_reputation_monitoring_topic    = "arn:aws:sns:region:account-id:ses-reputation-topic"
  bounce_complaint_remediation_topic = "arn:aws:sns:region:account-id:ses-bounce-topic"
  remediation_lambda                 = "arn:aws:lambda:region:account-id:function:remediation-lambda"
  verified_emails                    = ["user@example.com"]
}
