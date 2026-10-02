variable "aws_region" {
  description = "AWS region for the deployer role's provider configuration."
  type        = string
  default     = "eu-west-1"
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "Repository allowed to assume the role (name only, without the org)."
  type        = string
}

variable "allowed_environment" {
  description = "GitHub Actions environment whose jobs may assume the role (e.g. production)."
  type        = string
  default     = "production"
}

variable "max_session_seconds" {
  description = "Maximum session length for the short-lived credentials."
  type        = number
  default     = 900 # 15 minutes
}

variable "deploy_bucket_arn" {
  description = "ARN of the S3 bucket the pipeline is allowed to deploy artifacts to."
  type        = string
}
