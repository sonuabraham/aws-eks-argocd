# Scripts

Helper scripts for managing the ArgoCD on EKS Workshop environment.

## Available Scripts

### setup.sh

Initializes the workshop environment by:

- Checking prerequisites (AWS CLI, Terraform, kubectl)
- Creating terraform.tfvars files from examples
- Initializing Terraform in all bootstrap folders
- Providing next steps guidance

**Usage:**

```bash
./scripts/setup.sh
```

### setup-gitea-repos.sh

Sets up Gitea repositories with sample content for the workshop:

- Creates three workshop repositories (apps, platform, addons)
- Populates them with initial configurations
- Configures sample guestbook application

**Usage:**

```bash
./scripts/setup-gitea-repos.sh
```

**Note:** Run this after deploying Gitea with Terraform.

### get-argocd-password.sh

Retrieves the ArgoCD admin password and displays access information.

**Usage:**

```bash
./scripts/get-argocd-password.sh
```

**Output:**

- Admin username and password
- LoadBalancer URL (if available)
- Port-forward command for local access

### cleanup.sh

Cleans up all workshop resources:

- Removes ArgoCD applications
- Destroys Terraform infrastructure (ArgoCD and Gitea)
- Cleans up local Terraform state files

**Usage:**

```bash
./scripts/cleanup.sh
```

**Warning:** This will destroy all deployed resources. Make sure you want to proceed before running.

## Typical Workflow

1. **Initial Setup:**

   ```bash
   ./scripts/setup.sh
   ```

2. **Edit Configuration:**
   Edit the terraform.tfvars files in:

   - `gitea-bootstrap/terraform.tfvars`
   - `argocd-bootstrap-helm/terraform.tfvars` (or gitops-bridge)

3. **Deploy Gitea:**

   ```bash
   cd gitea-bootstrap
   terraform apply
   cd ..
   ```

4. **Setup Repositories:**

   ```bash
   ./scripts/setup-gitea-repos.sh
   ```

5. **Deploy ArgoCD:**

   ```bash
   cd argocd-bootstrap-helm  # or argocd-bootstrap-gitops-bridge
   terraform apply
   cd ..
   ```

6. **Get ArgoCD Password:**

   ```bash
   ./scripts/get-argocd-password.sh
   ```

7. **Cleanup (when done):**
   ```bash
   ./scripts/cleanup.sh
   ```

## Prerequisites

All scripts assume:

- AWS CLI is configured with valid credentials
- kubectl is configured to access your EKS cluster
- Terraform is installed (>= 1.0)
- You have appropriate AWS permissions

## Troubleshooting

If scripts fail:

1. Check that all prerequisites are installed
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Verify kubectl access: `kubectl cluster-info`
4. Check script permissions: `chmod +x scripts/*.sh`
