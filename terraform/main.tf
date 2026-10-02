# GitHub's OIDC identity provider. One per AWS account.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Trust policy: only jobs from one repository AND one protected environment can assume the role.
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Exact match (not StringLike with wildcards) so forks, other branches
    # and other environments cannot obtain credentials.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:environment:${var.allowed_environment}"]
    }
  }
}

resource "aws_iam_role" "github_deployer" {
  name                 = "github-deployer-${var.github_repo}"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600 # AWS minimum; the workflow requests var.max_session_seconds
  description          = "Short-lived OIDC role for ${var.github_org}/${var.github_repo} (${var.allowed_environment})"
}

# Least privilege: the pipeline may only write release artifacts to one bucket.
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "WriteReleaseArtifacts"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = [var.deploy_bucket_arn, "${var.deploy_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy-artifacts"
  role   = aws_iam_role.github_deployer.id
  policy = data.aws_iam_policy_document.deploy.json
}
