variable "route53_zone" {
  description = "Route 53 Zone to add the subdomain"
  type = object({
    id   = string
    name = string
  })
}

variable "domain" {
  description = "The domain of the SES identity"
  type        = string
}

variable "tls_policy" {
  description = "Used to specify Whether messages that use the configuration set are required to use Transport Layer Security"
  type        = string
  default     = "Optional"

  validation {
    condition     = contains(["Optional", "Require"], var.tls_policy)
    error_message = "TLS policy must be either 'Optional' or 'Require'."
  }
}

variable "monitor_reputation" {
  description = "Used to conditionally monitor or not the SES account reputation"
  type        = bool
  default     = false
}

variable "ses_reputation_monitoring_topic" {
  description = "ARN of the SNS topic connected on the cloudwatch alarms which monitor SES reputation"
  type        = string
  default     = null
}

variable "bounce_complaint_remediation_topic" {
  description = "ARN of the SNS topic which will receive bounces and complaints feedebacks from the ses configuration set"
  type        = string
  default     = null
}

variable "remediation_lambda" {
  description = "ARN of the lambda function which will process messages of the SNS remediation topic"
  type        = string
  default     = null
}

variable "alarm_period" {
  description = "Period for CloudWatch alarms"
  type        = number
  default     = 3600
}

variable "verified_emails" {
  description = "List of authorized emails to receive emails (Only if ses stay in sandbox mode)."
  type        = set(string)
  default     = []
}
