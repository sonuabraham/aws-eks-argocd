# ArgoCD Installation Guide

This guide walks you through installing ArgoCD on your existing EKS cluster, following the AWS EKS Blueprints Workshop pattern.

## Overview

The `argocd-bootstrap/` directory contains Terraform configuration that:

1. Installs ArgoCD via Helm
2. Configures ArgoCD to work with your Gitea repositories
3. Bootstraps GitOps by creating ArgoCD Applications

## Quick Start

### Step 1: Navigate to Bootstrap Directory

```bash
cd argocd-bootstrap
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Review Configuration

The `terraform.tfvars` file is already configured with your cluster details:

- Region: us-east-1
- Cluster: hub-cluster
- Gitea URL: http://gitea-http.gitea.svc.cluster.local:3000

### Step 4: Deploy ArgoCD

```bash
# Review what will be created
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted. This will take ~2-3 minutes.

### Step 5: Wait for ArgoCD to be Ready

```bash
# Watch pods come up
kubectl get pods -n argocd -w

# Wait for all pods to be Running (Ctrl+C to stop watching)
```

### Step 6: Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

Save this password - you'll need it to login.

### Step 7: Access ArgoCD UI

```bash
# Start port-forward (keep this terminal open)
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open your browser to: **http://localhost:8080**

**Note:** Use HTTP (not HTTPS) - ArgoCD is configured in insecure mode for the workshop.

- Username: `admin`
- Password: (from Step 6)

## What You'll See in ArgoCD

After logging in, you should see 3 applications:

1. **gitops-apps** - Syncing from eks-blueprints-workshop-gitops-apps
2. **gitops-platform** - Syncing from eks-blueprints-workshop-gitops-platform
3. **gitops-addons** - Syncing from eks-blueprints-workshop-gitops-addons

These applications are automatically syncing from your Gitea repositories.

## Verify Installation

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD applications
kubectl get applications -n argocd

# Check application status
kubectl describe application gitops-apps -n argocd
```

## Using ArgoCD

### View Applications

In the ArgoCD UI:

1. Click on an application to see details
2. View the resource tree
3. See sync status and health

### Manual Sync

If needed, you can manually sync an application:

```bash
# Via UI: Click "Sync" button on application

# Via CLI:
kubectl patch application gitops-apps -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Add New Applications

To add a new application:

1. Add manifests to one of your Gitea repositories
2. Commit and push to Gitea
3. ArgoCD will automatically detect and sync

Or create a new ArgoCD Application:

```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git
    targetRevision: HEAD
    path: my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## Workshop Integration

Now that ArgoCD is installed, you can follow the workshop labs:

1. **Lab 1:** Deploy applications via GitOps
2. **Lab 2:** Modify applications in Git
3. **Lab 3:** Watch ArgoCD sync changes
4. **Lab 4:** Use App of Apps pattern

## Troubleshooting

### Pods Not Starting

```bash
kubectl describe pods -n argocd
kubectl logs -n argocd deployment/argocd-server
```

### Can't Access UI

```bash
# Check service
kubectl get svc -n argocd

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Applications Not Syncing

```bash
# Check application status
kubectl describe application gitops-apps -n argocd

# Check ArgoCD can reach Gitea
kubectl exec -n argocd deployment/argocd-server -- curl http://gitea-http.gitea.svc.cluster.local:3000
```

### Forgot Admin Password

```bash
# Get password again
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

## Cleanup

To remove ArgoCD:

```bash
cd argocd-bootstrap
terraform destroy
```

## Next Steps

1. ✅ ArgoCD installed
2. ✅ Connected to Gitea repositories
3. 🎯 Deploy the guestbook application
4. 🎯 Modify application in Git
5. 🎯 Watch ArgoCD sync automatically

## Resources

- [argocd-bootstrap/README.md](argocd-bootstrap/README.md) - Detailed documentation
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/en-US/030-base/060-install-argocd)

---

🎉 **Ready to start your GitOps journey!**
