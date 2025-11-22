# ArgoCD Bootstrap for EKS Blueprints Workshop

This directory contains Terraform configuration to install and bootstrap ArgoCD on your existing EKS cluster, following the AWS EKS Blueprints Workshop pattern.

## What This Does

1. **Installs ArgoCD** via Helm chart
2. **Creates ArgoCD namespace**
3. **Bootstraps GitOps** by creating ArgoCD Applications that point to your Gitea repositories:
   - `gitops-apps` → eks-blueprints-workshop-gitops-apps
   - `gitops-platform` → eks-blueprints-workshop-gitops-platform
   - `gitops-addons` → eks-blueprints-workshop-gitops-addons

## Prerequisites

- Existing EKS cluster (already created)
- Gitea installed and running (from parent directory)
- kubectl configured to access your cluster
- Terraform >= 1.0

## Installation Steps

### 1. Configure Variables

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your cluster name
# The cluster_name should match your existing cluster
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

This will show:

- ArgoCD namespace creation
- ArgoCD Helm release
- 3 ArgoCD Applications (if gitops_bootstrap is enabled)

### 4. Apply Configuration

```bash
terraform apply
```

Wait for ArgoCD to be fully deployed (~2-3 minutes).

### 5. Verify Installation

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD applications
kubectl get applications -n argocd

# All pods should be Running
# Applications should show as Synced
```

## Accessing ArgoCD

### Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### Access UI

```bash
# Start port-forward (keep this running)
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Open browser to: http://localhost:8080
# Note: HTTP (not HTTPS) - ArgoCD is configured in insecure mode for workshop
# Username: admin
# Password: (from command above)
```

### Using ArgoCD CLI (Optional)

```bash
# Install ArgoCD CLI
brew install argocd  # macOS
# or download from https://argo-cd.readthedocs.io/en/stable/cli_installation/

# Login
argocd login localhost:8080 --insecure

# List applications
argocd app list

# Get application details
argocd app get gitops-apps
```

## GitOps Bootstrap

When `enable_gitops_bootstrap = true`, Terraform creates 3 ArgoCD Applications:

### 1. gitops-apps

- **Repository:** eks-blueprints-workshop-gitops-apps
- **Purpose:** Application workloads
- **Path:** Root directory
- **Sync:** Automated with prune and self-heal

### 2. gitops-platform

- **Repository:** eks-blueprints-workshop-gitops-platform
- **Purpose:** Platform configurations
- **Path:** Root directory
- **Sync:** Automated with prune and self-heal

### 3. gitops-addons

- **Repository:** eks-blueprints-workshop-gitops-addons
- **Purpose:** Cluster addons
- **Path:** Root directory
- **Sync:** Automated with prune and self-heal

## Configuration

### ArgoCD Values

The `argocd-values.yaml` file configures:

- **Insecure mode** - No TLS (for workshop simplicity)
- **Resource limits** - Optimized for workshop environment
- **Repository credentials** - Pre-configured for Gitea
- **Automated sync** - Applications sync automatically

### Customization

To customize ArgoCD:

1. Edit `argocd-values.yaml`
2. Run `terraform apply`

## Workshop Workflow

After ArgoCD is installed:

1. **Make changes** to Gitea repositories
2. **Commit and push** to Gitea
3. **ArgoCD automatically syncs** the changes to your cluster
4. **View in ArgoCD UI** to see sync status

## Troubleshooting

### ArgoCD pods not starting

```bash
kubectl describe pods -n argocd
kubectl logs -n argocd deployment/argocd-server
```

### Applications not syncing

```bash
# Check application status
kubectl describe application gitops-apps -n argocd

# Check if ArgoCD can reach Gitea
kubectl exec -n argocd deployment/argocd-server -- curl -v http://gitea-http.gitea.svc.cluster.local:3000
```

### Cannot access UI

```bash
# Verify service
kubectl get svc -n argocd argocd-server

# Check port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Repository connection issues

```bash
# Check repository credentials in ArgoCD
kubectl get secret -n argocd argocd-repo-creds -o yaml

# Test Gitea connectivity from ArgoCD pod
kubectl exec -n argocd deployment/argocd-repo-server -- curl http://gitea-http.gitea.svc.cluster.local:3000
```

## Cleanup

To remove ArgoCD:

```bash
terraform destroy
```

This will:

- Delete all ArgoCD Applications
- Uninstall ArgoCD Helm release
- Remove ArgoCD namespace

**Note:** This does NOT delete the applications deployed by ArgoCD. To clean those up, delete them before destroying ArgoCD.

## Integration with Workshop

This setup follows the AWS EKS Blueprints Workshop pattern:

1. **Bootstrap Phase** (this directory)

   - Install ArgoCD
   - Create initial Applications

2. **GitOps Phase** (Gitea repositories)

   - Define applications in Git
   - ArgoCD syncs from Git to cluster

3. **Development Phase**
   - Make changes in Git
   - ArgoCD applies changes automatically

## Next Steps

1. ✅ ArgoCD installed
2. ✅ GitOps repositories connected
3. 🎯 Add applications to Gitea repositories
4. 🎯 Watch ArgoCD sync them automatically
5. 🎯 Follow workshop labs

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
