# GitOps Repository Secrets Management

This module automatically creates and populates AWS Secrets Manager secrets for your GitOps repositories.

## Overview

When you run `terraform apply`, this module will:

1. **Deploy Gitea** (if `enable_gitea = true`) - A local Git server for workshop purposes
2. **Create AWS Secrets Manager secrets** for three GitOps repositories:
   - `eks-blueprints-workshop-gitops-platform`
   - `eks-blueprints-workshop-gitops-workloads`
   - `eks-blueprints-workshop-gitops-addons`
3. **Populate the secrets** with repository metadata and credentials

## Secret Structure

Each secret contains the following fields:

```json
{
  "basepath": "",
  "org": "http://gitea-http.gitea.svc.cluster.local:3000",
  "password": "gitea123",
  "path": "bootstrap",
  "repo": "gitea/eks-blueprints-workshop-gitops-platform",
  "revision": "HEAD",
  "url": "http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-platform",
  "username": "gitea"
}
```

## Configuration Variables

### Required Variables

- `vpc_id` - The VPC ID where your EKS cluster is deployed

### Optional Variables (with defaults)

- `git_username` - Git username (default: "gitea")
- `git_password` - Git password/token (default: "gitea123")
- `git_server_url` - Git server URL when Gitea is disabled (default: "https://github.com")
- `git_revision` - Git branch/revision (default: "HEAD")
- `enable_gitea` - Deploy Gitea server (default: true)

## Usage

### Basic Usage (with Gitea)

```hcl
module "gitea_bootstrap" {
  source = "./gitea-bootstrap"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-xxxxx"
  region       = "us-east-1"
}
```

### Using External Git Server (GitHub/GitLab)

```hcl
module "gitea_bootstrap" {
  source = "./gitea-bootstrap"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-xxxxx"
  region       = "us-east-1"

  enable_gitea     = false
  git_server_url   = "https://github.com"
  git_username     = "my-github-user"
  git_password     = "ghp_xxxxxxxxxxxxx"  # GitHub Personal Access Token
}
```

### Using terraform.tfvars

Create a `terraform.tfvars` file:

```hcl
cluster_name = "hub-cluster"
vpc_id       = "vpc-0123456789abcdef"
region       = "us-east-1"

# Git configuration
git_username = "workshop-user"
git_password = "my-secure-token"
git_revision = "main"
```

## Outputs

After applying, you can retrieve the secret information:

```bash
# View all created secrets
terraform output gitops_secrets_created

# View platform repository metadata (sensitive)
terraform output -json gitops_platform_metadata

# Retrieve secret from AWS CLI
aws secretsmanager get-secret-value \
  --secret-id eks-blueprints-workshop-gitops-platform \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

## Repository Paths

The secrets are configured with different paths for each repository:

- **Platform**: `path: "bootstrap"` - Points to the bootstrap directory
- **Workloads**: `path: "."` - Points to the root directory
- **Addons**: `path: "."` - Points to the root directory

## Security Notes

1. **Sensitive Variables**: The `git_password` variable is marked as sensitive
2. **Recovery Window**: Secrets are configured with `recovery_window_in_days = 0` for immediate deletion (workshop only)
3. **Production Use**: For production, set a recovery window (e.g., 30 days) and use proper secret rotation

## Updating Secrets

To update the secrets with new credentials:

1. Update the variables in `terraform.tfvars`
2. Run `terraform apply`
3. The secret versions will be updated automatically

## Troubleshooting

### Secrets already exist

If secrets already exist from a previous deployment:

```bash
# Delete existing secrets
aws secretsmanager delete-secret --secret-id eks-blueprints-workshop-gitops-platform --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id eks-blueprints-workshop-gitops-workloads --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id eks-blueprints-workshop-gitops-addons --force-delete-without-recovery

# Then run terraform apply again
terraform apply
```

### Verify secrets were created

```bash
aws secretsmanager list-secrets --region us-east-1 | grep eks-blueprints-workshop-gitops
```

## Integration with ArgoCD

These secrets can be consumed by ArgoCD or other GitOps tools using:

1. **External Secrets Operator** - Sync secrets to Kubernetes
2. **Terraform Data Sources** - Read secrets in other Terraform modules
3. **AWS SDK** - Access secrets programmatically

Example Terraform data source usage:

```hcl
data "aws_secretsmanager_secret_version" "platform" {
  secret_id = "eks-blueprints-workshop-gitops-platform"
}

locals {
  platform_url = jsondecode(data.aws_secretsmanager_secret_version.platform.secret_string)["url"]
}
```
