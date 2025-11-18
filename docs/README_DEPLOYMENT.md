# EKS Blueprints Workshop - Local Deployment

Complete GitOps environment for AWS EKS Blueprints Workshop on your local laptop.

## Quick Start

### 1. Deploy Gitea

```bash
cd argocd-eks
terraform init && terraform apply
./scripts/setup-gitea-repos.sh
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

### 2. Deploy ArgoCD

```bash
cd argocd-bootstrap
terraform init && terraform apply
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### 3. Access

- **Gitea:** http://localhost:3000 (gitea/gitea123)
- **ArgoCD:** http://localhost:8080 (admin/PASSWORD)

Get ArgoCD password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Important Notes

- **ArgoCD uses HTTP** (not HTTPS) - Port forward to port 80: `8080:80`
- **Gitea data is ephemeral** - Will be lost on pod restart
- **Keep port-forwards running** - Use separate terminals

## Documentation

- **[COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md)** - Full deployment instructions
- **[ARGOCD_INSTALLATION.md](ARGOCD_INSTALLATION.md)** - ArgoCD setup guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions

## Configuration Files

- `terraform.tfvars` - Your cluster configuration
- `gitea-values.yaml` - Gitea Helm values
- `argocd-bootstrap/argocd-values.yaml` - ArgoCD Helm values

## Cleanup

```bash
cd argocd-bootstrap && terraform destroy
cd .. && terraform destroy
```
