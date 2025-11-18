# Documentation Index

Complete documentation for deploying the EKS Blueprints Workshop on your local laptop.

## Quick Start Guides

### 🚀 [README_DEPLOYMENT.md](README_DEPLOYMENT.md)

Quick reference guide with essential commands and access information.

### 📘 [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md)

**START HERE** - Complete step-by-step deployment guide covering:

- Prerequisites and setup
- Gitea deployment
- ArgoCD installation
- Verification steps
- Troubleshooting
- Cleanup procedures

### 🎯 [GETTING_STARTED.md](GETTING_STARTED.md)

Quick start guide for deploying on an existing EKS cluster.

## Installation Guides

### 🔧 [ARGOCD_INSTALLATION.md](ARGOCD_INSTALLATION.md)

Detailed ArgoCD installation guide with:

- Step-by-step installation
- Configuration options
- Access instructions
- Verification steps

### 💻 [LOCAL_LAPTOP_SETUP.md](LOCAL_LAPTOP_SETUP.md)

Complete guide for setting up the workshop environment on your local laptop.

## Success & Verification

### ✅ [ARGOCD_SUCCESS.md](ARGOCD_SUCCESS.md)

ArgoCD deployment success guide with:

- Access credentials
- Verification steps
- GitOps workflow
- Next steps

### ✅ [DEPLOYMENT_SUCCESS.md](DEPLOYMENT_SUCCESS.md)

Gitea deployment success guide with:

- Access information
- Repository details
- Next steps

### ✅ [SETUP_COMPLETE.md](SETUP_COMPLETE.md)

Complete setup checklist and verification guide.

## Troubleshooting & Configuration

### 🔍 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Comprehensive troubleshooting guide covering:

- Common issues and solutions
- Gitea problems
- ArgoCD issues
- Port-forward problems
- Data persistence
- Diagnostic commands

## Document Purpose

| Document                         | Purpose                      | When to Use           |
| -------------------------------- | ---------------------------- | --------------------- |
| **COMPLETE_DEPLOYMENT_GUIDE.md** | Full deployment instructions | First-time deployment |
| **README_DEPLOYMENT.md**         | Quick reference              | Quick lookup          |
| **ARGOCD_INSTALLATION.md**       | ArgoCD setup                 | Installing ArgoCD     |
| **TROUBLESHOOTING.md**           | Problem solving              | When issues occur     |
| **ARGOCD_SUCCESS.md**            | Post-deployment              | After ArgoCD install  |
| **DEPLOYMENT_SUCCESS.md**        | Post-deployment              | After Gitea install   |
| **LOCAL_LAPTOP_SETUP.md**        | Environment setup            | Initial setup         |
| **GETTING_STARTED.md**           | Quick start                  | Existing cluster      |
| **SETUP_COMPLETE.md**            | Verification                 | Final checks          |

## Recommended Reading Order

### For First-Time Deployment

1. [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md) - Read this first
2. [DEPLOYMENT_SUCCESS.md](DEPLOYMENT_SUCCESS.md) - After Gitea deployment
3. [ARGOCD_SUCCESS.md](ARGOCD_SUCCESS.md) - After ArgoCD deployment
4. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - If issues occur

### For Quick Reference

1. [README_DEPLOYMENT.md](README_DEPLOYMENT.md) - Quick commands
2. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

### For Redeployment

1. [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md) - Follow deployment steps
2. [README_DEPLOYMENT.md](README_DEPLOYMENT.md) - Quick reference

## Key Information

### Access URLs

- **Gitea:** http://localhost:3000 (gitea/gitea123)
- **ArgoCD:** http://localhost:8080 (admin/PASSWORD)

### Port-Forward Commands

```bash
# Gitea
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# ArgoCD (note: port 80, not 443)
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Get ArgoCD Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Important Notes

⚠️ **ArgoCD uses HTTP** - Port-forward to port 80, access via http://localhost:8080

⚠️ **Gitea data is ephemeral** - Data lost on pod restart (by design for EKS Auto Mode)

⚠️ **Workshop configuration** - Not production-ready, simplified for learning

## Additional Resources

- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Gitea Documentation](https://docs.gitea.io/)
- [Technical README](../argocd-bootstrap/README.md) - ArgoCD bootstrap details

---

**Need Help?** Start with [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### ⚙️ [LOADBALANCER_CONFIGURATION.md](LOADBALANCER_CONFIGURATION.md)

LoadBalancer configuration and troubleshooting guide:

- Internet-facing vs internal LoadBalancers
- AWS annotations and configuration
- Common LoadBalancer issues
- Alternative access methods (port-forward, NodePort, Ingress)
- Cost considerations
- Security best practices

### 📁 [APPLICATIONS_FOLDER_GUIDE.md](APPLICATIONS_FOLDER_GUIDE.md)

Understanding the applications/ folder structure:

- Purpose of each subfolder (guestbook, guestbook-gitea, etc.)
- How ArgoCD Applications work
- Which applications to use for the workshop
- Creating your own applications
- Relationship with Gitea repositories

### 🔄 [GITEA_WORKFLOW_GUIDE.md](GITEA_WORKFLOW_GUIDE.md)

Complete Gitea workflow guide:

- Cloning Gitea repositories to your laptop
- Making and pushing changes
- Updating repositories after redeployment
- Best practices and common workflows
- Backup and restore procedures
