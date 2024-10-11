data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_ses_domain_identity" "main" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_ses_configuration_set" "main" {
  name                       = "default"
  reputation_metrics_enabled = true
  delivery_options {
    tls_policy = var.tls_policy
  }
}

resource "aws_ses_email_identity" "main" {
  for_each = var.verified_emails

  email = each.key
}

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.route53_zone.id
  name    = "${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.main.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "mail_mx" {
  zone_id = var.route53_zone.id
  name    = var.route53_zone.name
  type    = "MX"
  ttl     = "1800"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}

resource "aws_route53_record" "mail_txt" {
  zone_id = var.route53_zone.id
  name    = var.route53_zone.name
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

#-----------------------------------------------------------------------------------------------------------------------
# OPTIONALLY CREATE RESOURCES FOR BOUNCES AND COMPLAINTS REMEDIATION
#-----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "sns_policy" {
  statement {
    actions = [
      "sns:Publish"
    ]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    resources = [var.bounce_complaint_remediation_topic]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [aws_ses_configuration_set.main.arn]
    }
  }
}

resource "aws_sns_topic_subscription" "main" {
  count     = var.bounce_complaint_remediation_topic != null ? 1 : 0
  topic_arn = var.bounce_complaint_remediation_topic
  protocol  = "lambda"
  endpoint  = var.remediation_lambda
}

resource "aws_ses_event_destination" "sns" {
  count                  = var.bounce_complaint_remediation_topic != null ? 1 : 0
  name                   = "event-destination-sns"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["bounce", "complaint"]

  sns_destination {
    topic_arn = var.bounce_complaint_remediation_topic
  }
}

resource "aws_sns_topic_policy" "main" {
  count  = var.bounce_complaint_remediation_topic != null ? 1 : 0
  arn    = var.bounce_complaint_remediation_topic
  policy = data.aws_iam_policy_document.sns_policy.json
}

#-----------------------------------------------------------------------------------------------------------------------
# OPTIONALLY CREATE CLOUDWATCH ALARMS TO MONITOR SES ACCOUNT REPUTATION
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate_alarm" {
  count               = var.monitor_reputation ? 1 : 0
  alarm_name          = "SES-BounceRate-Alarm"
  alarm_description   = "Monitor SES Bounce Rate"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  threshold           = 0.05 # 5% bounce rate threshold
  period              = var.alarm_period
  evaluation_periods  = 1
  treat_missing_data  = "ignore"

  ok_actions                = [var.ses_reputation_monitoring_topic]
  alarm_actions             = [var.ses_reputation_monitoring_topic]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate_alarm" {
  count               = var.monitor_reputation ? 1 : 0
  alarm_name          = "SES-ComplaintRate-Alarm"
  alarm_description   = "Monitor SES Complaint Rate"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.ComplaintRate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  threshold           = 0.001 # 0.1% complaint rate threshold
  period              = var.alarm_period
  evaluation_periods  = 1
  treat_missing_data  = "ignore"

  ok_actions                = var.ses_reputation_monitoring_topic != null ? [var.ses_reputation_monitoring_topic] : []
  alarm_actions             = var.ses_reputation_monitoring_topic != null ? [var.ses_reputation_monitoring_topic] : []
  insufficient_data_actions = []
}

locals {
  alarms = var.monitor_reputation ? [
    aws_cloudwatch_metric_alarm.ses_bounce_rate_alarm[0],
    aws_cloudwatch_metric_alarm.ses_complaint_rate_alarm[0]
  ] : []
  alarm_arns = join(", ", [
    for alarm in local.alarms : "\"${alarm.arn}\""
  ])
}

resource "aws_cloudwatch_event_rule" "ses_reputation_alarms" {
  count         = var.monitor_reputation ? 1 : 0
  name          = "SES-Reputation-Alarms"
  event_pattern = <<EOF
{
  "source": [
    "aws.cloudwatch"
  ],
  "detail-type": [
    "CloudWatch Alarm State Change"
  ],
  "resources": [${local.alarm_arns}]
}
EOF
}
