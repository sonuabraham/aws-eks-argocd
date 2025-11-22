# EKS Blueprints Workshop - Local Laptop Deployment

Deploy the complete AWS EKS Blueprints Workshop environment on your local laptop using an existing EKS cluster.

## Overview

This project provides Terraform configurations to deploy:

- **Gitea** - Local Git server with workshop repositories
- **ArgoCD** - GitOps continuous delivery tool
- **Workshop Repositories** - Pre-configured with example applications

## Quick Start

### Prerequisites

- Existing EKS cluster
- AWS CLI configured
- kubectl configured
- Terraform >= 1.0

### Deploy in 3 Steps

**1. Deploy Gitea**

```bash
cd gitea-bootstrap

# Configure your cluster details
cat > terraform.tfvars <<EOF
region       = "us-east-1"
cluster_name = "hub-cluster"
vpc_id       = "vpc-xxxxxxxxx"
enable_gitea = true
EOF

# Deploy
terraform init && terraform apply

# Setup repositories
cd ..
./scripts/setup-gitea-repos.sh
```

**2. Deploy ArgoCD**

Choose one of the two methods:

**Option A: Using Helm (simpler)**

```bash
cd argocd-bootstrap-helm
terraform init && terraform apply
```

**Option B: Using GitOps Bridge (AWS best practices)**

```bash
cd argocd-bootstrap-gitops-bridge
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your cluster details
terraform init && terraform apply
```

**3. Access Services**

```bash
# Terminal 1: Gitea
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Terminal 2: ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Access URLs:**

- Gitea: http://localhost:3000 (gitea/gitea123)
- ArgoCD: http://localhost:8080 (admin/PASSWORD)

Get ArgoCD password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Documentation

### Getting Started

- **[docs/COMPLETE_DEPLOYMENT_GUIDE.md](docs/COMPLETE_DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment guide
- **[docs/README_DEPLOYMENT.md](docs/README_DEPLOYMENT.md)** - Quick reference guide
- **[docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)** - Quick start for existing cluster

### Installation Guides

- **[docs/ARGOCD_INSTALLATION.md](docs/ARGOCD_INSTALLATION.md)** - ArgoCD installation guide
- **[docs/LOCAL_LAPTOP_SETUP.md](docs/LOCAL_LAPTOP_SETUP.md)** - Local laptop setup guide

### Success & Verification

- **[docs/ARGOCD_SUCCESS.md](docs/ARGOCD_SUCCESS.md)** - ArgoCD deployment success guide
- **[docs/DEPLOYMENT_SUCCESS.md](docs/DEPLOYMENT_SUCCESS.md)** - Gitea deployment success guide
- **[docs/SETUP_COMPLETE.md](docs/SETUP_COMPLETE.md)** - Setup completion checklist

### Troubleshooting & Configuration

- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[docs/LOADBALANCER_CONFIGURATION.md](docs/LOADBALANCER_CONFIGURATION.md)** - LoadBalancer setup and troubleshooting
- **[docs/APPLICATIONS_FOLDER_GUIDE.md](docs/APPLICATIONS_FOLDER_GUIDE.md)** - Understanding applications/ folder
- **[docs/GITEA_WORKFLOW_GUIDE.md](docs/GITEA_WORKFLOW_GUIDE.md)** - Working with Gitea repositories

### Technical Documentation

- **[gitea-bootstrap/README.md](gitea-bootstrap/README.md)** - Gitea bootstrap technical docs
- **[argocd-bootstrap-helm/README.md](argocd-bootstrap-helm/README.md)** - ArgoCD Helm bootstrap technical docs
- **[argocd-bootstrap-gitops-bridge/README.md](argocd-bootstrap-gitops-bridge/README.md)** - ArgoCD GitOps Bridge technical docs

## Project Structure

```
argocd-eks/
├── README.md                          # This file
├── docs/                              # Documentation
│   ├── COMPLETE_DEPLOYMENT_GUIDE.md   # Full deployment guide
│   ├── ARGOCD_INSTALLATION.md         # ArgoCD setup
│   ├── TROUBLESHOOTING.md             # Common issues
│   └── ...                            # Other guides
├── gitea-bootstrap/                   # Gitea deployment
│   ├── main.tf                        # Gitea Terraform
│   ├── variables.tf                   # Gitea variables
│   ├── outputs.tf                     # Gitea outputs
│   ├── terraform.tfvars               # Your configuration
│   ├── gitea-values.yaml              # Gitea Helm values
│   └── README.md                      # Gitea technical docs
├── argocd-bootstrap-helm/             # ArgoCD deployment (Helm)
│   ├── main.tf                        # ArgoCD Terraform
│   ├── variables.tf                   # ArgoCD variables
│   ├── outputs.tf                     # ArgoCD outputs
│   ├── terraform.tfvars               # ArgoCD configuration
│   ├── argocd-values.yaml             # ArgoCD Helm values
│   └── README.md                      # ArgoCD technical docs
├── argocd-bootstrap-gitops-bridge/    # ArgoCD deployment (GitOps Bridge)
│   ├── main.tf                        # GitOps Bridge Terraform
│   ├── variables.tf                   # GitOps Bridge variables
│   ├── outputs.tf                     # GitOps Bridge outputs
│   ├── terraform.tfvars.example       # Example configuration
│   └── README.md                      # GitOps Bridge docs
├── scripts/
│   └── setup-gitea-repos.sh           # Repository setup script
├── applications/                      # Sample ArgoCD applications
│   ├── eks-workshop-app-dev/
│   └── eks-workshop-gitops-dev/
└── infra/                             # Infrastructure configurations
```

## What Gets Deployed

### Gitea (Git Server)

- **Namespace:** gitea
- **Service:** ClusterIP (access via port-forward)
- **Storage:** Ephemeral (no persistence)
- **Repositories:** 3 workshop repositories
  - eks-blueprints-workshop-gitops-apps
  - eks-blueprints-workshop-gitops-platform
  - eks-blueprints-workshop-gitops-addons

### ArgoCD (GitOps Controller)

- **Namespace:** argocd
- **Service:** ClusterIP on port 80 (HTTP)
- **Mode:** Insecure (for workshop simplicity)
- **Applications:** 3 auto-syncing applications

## Configuration

### Gitea Configuration

Edit `gitea-values.yaml` to customize:

- Persistence settings
- Service type
- Resource limits

### ArgoCD Configuration

Edit `argocd-bootstrap/argocd-values.yaml` to customize:

- Security settings
- Resource limits
- Sync policies

## Important Notes

### ⚠️ Workshop Configuration

This is configured for workshop/testing purposes:

- **Gitea data is ephemeral** - Lost on pod restart
- **ArgoCD uses HTTP** - No TLS encryption
- **Default passwords** - Change for production

### 🔒 For Production

- Enable persistence for Gitea
- Enable TLS for ArgoCD
- Use proper secrets management
- Configure RBAC
- Use external databases

## Common Commands

```bash
# Gitea
kubectl get pods -n gitea
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# ArgoCD
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# List Gitea repositories
curl -s -u gitea:gitea123 http://localhost:3000/api/v1/user/repos | jq -r '.[].name'
```

## Cleanup

```bash
# Remove ArgoCD (choose the method you used)
cd argocd-bootstrap-helm  # or argocd-bootstrap-gitops-bridge
terraform destroy

# Remove Gitea
cd ../gitea-bootstrap
terraform destroy
```

## Troubleshooting

### Can't Access ArgoCD

- Use **http://** not https://
- Port-forward to port **80** not 443: `kubectl port-forward svc/argocd-server -n argocd 8080:80`
- Check pods: `kubectl get pods -n argocd`

### Gitea Repositories Empty

- Re-run setup script: `./scripts/setup-gitea-repos.sh`
- Check Gitea is accessible: `curl http://localhost:3000`

### Port-Forward Issues

```bash
# Check what's using the port
lsof -i :8080

# Kill existing port-forward
pkill -f "kubectl port-forward"

# Restart
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

See **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** for more solutions.

## GitOps Workflow

1. **Make changes** in Gitea (http://localhost:3000)
2. **Commit and push** to repository
3. **ArgoCD syncs** automatically (within 3 minutes)
4. **View in ArgoCD UI** (http://localhost:8080)

## Resources

- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Gitea Documentation](https://docs.gitea.io/)

## Support

For issues and questions:

1. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review [docs/COMPLETE_DEPLOYMENT_GUIDE.md](docs/COMPLETE_DEPLOYMENT_GUIDE.md)
3. Check pod logs: `kubectl logs -n <namespace> <pod-name>`

## License

This project is for educational purposes as part of the AWS EKS Blueprints Workshop.

---

**Quick Links:**

- [Complete Deployment Guide](docs/COMPLETE_DEPLOYMENT_GUIDE.md)
- [ArgoCD Installation](docs/ARGOCD_INSTALLATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
