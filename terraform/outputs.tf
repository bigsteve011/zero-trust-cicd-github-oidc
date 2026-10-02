output "role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN variable on the GitHub environment."
  value       = aws_iam_role.github_deployer.arn
}

output "session_seconds" {
  description = "Session length to request from STS in the workflow."
  value       = var.max_session_seconds
}
