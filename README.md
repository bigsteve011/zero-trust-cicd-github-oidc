# Zero-Trust CI/CD: Hardening GitHub Actions with OIDC Federated Cloud Roles & Cosign Image Signing

> Eliminating static, long-lived AWS/Azure secret keys from CI/CD runners by configuring short-lived OpenID Connect (OIDC) identity federation, signed software supply chains with Sigstore Cosign, and automated CycloneDX SBOM generation.

Companion repository for the article **[Zero-Trust CI/CD: Hardening GitHub Actions with OIDC Federated Cloud Roles & Cosign Image Signing](https://stephen-omowumi.pages.dev/articles/devops-oidc-github-actions)** by Stephen Omowumi.

## The problem

Hardcoded cloud credentials in CI/CD secrets represent one of the most exploited attack vectors. Long-lived credentials can be leaked through pull request injection, debug logs, or runner compromise with broad account privileges.

## Solution architecture

Implement GitHub Actions identity tokens exchanging short-lived JWTs directly with AWS IAM and Azure Entra ID trust policies. Enforce strict repository, branch, and environment claims matching. Integrate pre-deployment image signing and provenance validation.

## How it works

1. **OIDC Identity Token Generation** — Runner requests an OIDC JWT signed by GitHub token service containing claim sub: repo:org/repo:ref:refs/heads/main.
2. **Cloud STS / Entra ID Federation** — AWS STS / Azure Entra ID validates GitHub JWKS signature and evaluates federated IAM trust policy.
3. **Short-Lived Ephemeral Token Issue** — Issue a 15-minute temporary credential scoped strictly to required infrastructure deployment actions.
4. **Supply Chain Provenance Verification** — Sigstore Cosign signs container digest; gatekeeper verifies cryptographic signature before Kubernetes deployment.

## Repository layout

```
terraform/            OIDC provider + least-privilege deployer role (exact repo + environment trust)
.github/workflows/
  secure-deploy.yml   IaC scan -> build -> SBOM -> Cosign keyless sign/attest -> verify -> OIDC deploy
  validate.yml        terraform fmt / validate on every PR
app/                  tiny example workload to build and sign
```

## Usage

1. `cd terraform && cp terraform.tfvars.example terraform.tfvars` and fill in your org, repo and release bucket.
2. `terraform init && terraform apply`
3. In GitHub, create a protected **production** environment and set the variables `AWS_DEPLOY_ROLE_ARN` (from the Terraform output) and `RELEASE_BUCKET`.
4. Push to `main`. No AWS access keys are stored anywhere: the job exchanges its OIDC token for 15-minute credentials.

Verify an image yourself:
```bash
cosign verify ghcr.io/<org>/<repo>/app@sha256:<digest> \
  --certificate-identity-regexp '^https://github.com/<org>/<repo>/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Outcomes (as described in the article)

| Measure | Result |
|---|---|
| Static Secrets In CI/CD | 0 |
| Token Lifespan | 15 Mins |
| SLSA Supply Chain Level | Level 3 |

## Key takeaways

- Eliminated 100% of static cloud access keys in CI/CD pipeline vaults
- Short-lived session duration capped at 15 minutes reduces lateral movement blast radius
- Enforced cryptographic container image verification preventing supply chain tampering

## Notes

This is a reference implementation. Names, account IDs, regions and allow-lists are placeholders: review and adapt them, and test in a non-production environment before rolling out.

## License

MIT — see [LICENSE](LICENSE).
