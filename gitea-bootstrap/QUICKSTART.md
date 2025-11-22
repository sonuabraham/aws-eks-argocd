# Quick Start Guide - GitOps Secrets Management

This guide shows you how to deploy Gitea and automatically create AWS Secrets Manager secrets for your GitOps repositories.

## What This Does

When you run `terraform apply`, this module will:

1. ✅ Deploy Gitea (local Git server) to your EKS cluster
2. ✅ Create 3 AWS Secrets Manager secrets with repository metadata:
   - `eks-blueprints-workshop-gitops-platform`
   - `eks-blueprints-workshop-gitops-workloads`
   - `eks-blueprints-workshop-gitops-addons`
3. ✅ Populate secrets with URLs, credentials, and paths

## Prerequisites

- Existing EKS cluster
- AWS CLI configured
- kubectl configured
- Terraform >= 1.0

## Step-by-Step

### 1. Configure Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

Update these required values:

```hcl
cluster_name = "hub-cluster"           # Your EKS cluster name
vpc_id       = "vpc-0123456789abcdef"  # Your VPC ID
region       = "us-east-1"             # Your AWS region
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

You should see:

- Gitea Helm release
- 3 AWS Secrets Manager secrets
- 3 AWS Secrets Manager secret versions

### 4. Apply

```bash
terraform apply
```

Type `yes` when prompted.

### 5. Verify Secrets Were Created

```bash
# List the secrets
aws secretsmanager list-secrets --region us-east-1 | grep eks-blueprints-workshop-gitops

# View a secret
aws secretsmanager get-secret-value \
  --secret-id eks-blueprints-workshop-gitops-platform \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

Expected output:

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

### 6. Access Gitea

```bash
# Port forward to Gitea
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Open browser to http://localhost:3000
# Login with:
#   Username: gitea
#   Password: gitea123
```

## Using with GitHub Instead of Gitea

If you want to use GitHub instead of the local Gitea server:

```hcl
# In terraform.tfvars
enable_gitea     = false
git_server_url   = "https://github.com"
git_username     = "your-github-username"
git_password     = "ghp_your_github_token"  # GitHub Personal Access Token
```

## Next Steps

After the secrets are created, you can:

1. **Use in ArgoCD** - Configure ArgoCD to read these secrets for repository access
2. **Use in other Terraform modules** - Reference these secrets using data sources
3. **Create the actual Git repositories** - Create the three repositories in Gitea/GitHub

## Outputs

View the created resources:

```bash
# Show all outputs
terraform output

# Show specific output
terraform output gitops_secrets_created

# Show sensitive output (repository metadata)
terraform output -json gitops_platform_metadata
```

## Cleanup

To destroy everything:

```bash
terraform destroy
```

This will:

- Remove Gitea from your cluster
- Delete the AWS Secrets Manager secrets (immediately, no recovery window)

## Troubleshooting

### Error: Secret already exists

If you get an error that secrets already exist:

```bash
# Force delete existing secrets
aws secretsmanager delete-secret \
  --secret-id eks-blueprints-workshop-gitops-platform \
  --force-delete-without-recovery \
  --region us-east-1

aws secretsmanager delete-secret \
  --secret-id eks-blueprints-workshop-gitops-workloads \
  --force-delete-without-recovery \
  --region us-east-1

aws secretsmanager delete-secret \
  --secret-id eks-blueprints-workshop-gitops-addons \
  --force-delete-without-recovery \
  --region us-east-1

# Then apply again
terraform apply
```

### Gitea not accessible

```bash
# Check Gitea pod status
kubectl get pods -n gitea

# Check Gitea service
kubectl get svc -n gitea

# View Gitea logs
kubectl logs -n gitea -l app.kubernetes.io/name=gitea
```

## Support

For more details, see:

- [SECRETS_README.md](./SECRETS_README.md) - Detailed documentation
- [terraform.tfvars.example](./terraform.tfvars.example) - Configuration examples
