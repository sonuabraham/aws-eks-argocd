# Complete Deployment Guide - EKS Blueprints Workshop on Local Laptop

This guide provides complete step-by-step instructions to deploy the entire EKS Blueprints Workshop environment on your local laptop using an existing EKS cluster.

## Overview

This setup creates a complete GitOps environment with:

- **Gitea** - Local Git server with workshop repositories
- **ArgoCD** - GitOps controller for automated deployments
- **3 GitOps Repositories** - Apps, Platform, and Addons configurations

## Prerequisites

### Required Tools

- AWS CLI (configured with credentials)
- kubectl (configured for your EKS cluster)
- Terraform >= 1.0
- git
- curl
- jq (optional but recommended)

### Existing Infrastructure

- **EKS Cluster** - Already created (e.g., via environment/hub)
- **VPC** - Associated with the EKS cluster
- **AWS Load Balancer Controller** - Optional (for LoadBalancer services)

## Part 1: Deploy Gitea

### Step 1: Configure Gitea Deployment

```bash
# Navigate to project directory
cd argocd-eks

# Create terraform.tfvars with your cluster details
cat > terraform.tfvars <<EOF
region       = "us-east-1"
cluster_name = "hub-cluster"
vpc_id       = "vpc-xxxxxxxxx"
enable_gitea = true
EOF
```

**Replace:**

- `region` - Your AWS region
- `cluster_name` - Your actual EKS cluster name
- `vpc_id` - Your actual VPC ID

**To find your values:**

```bash
# List clusters
aws eks list-clusters --region us-east-1

# Get VPC ID
aws eks describe-cluster --name YOUR_CLUSTER --region us-east-1 --query 'cluster.resourcesVpcConfig.vpcId' --output text
```

### Step 2: Deploy Gitea

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy Gitea
terraform apply

# Wait for Gitea to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gitea -n gitea --timeout=300s
```

### Step 3: Access Gitea

```bash
# Start port-forward (keep this running in a separate terminal)
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

Open browser: http://localhost:3000

- Username: `gitea`
- Password: `gitea123`

### Step 4: Populate Gitea Repositories

```bash
# Run the setup script
chmod +x scripts/setup-gitea-repos.sh
./scripts/setup-gitea-repos.sh
```

This creates 3 repositories:

- `eks-blueprints-workshop-gitops-apps`
- `eks-blueprints-workshop-gitops-platform`
- `eks-blueprints-workshop-gitops-addons`

**Verify in browser:** http://localhost:3000 - You should see 3 repositories.

## Part 2: Deploy ArgoCD

### Step 1: Navigate to Bootstrap Directory

```bash
cd argocd-bootstrap
```

### Step 2: Configure ArgoCD

The `terraform.tfvars` file is already configured with your cluster details from Part 1.

### Step 3: Deploy ArgoCD

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy ArgoCD
terraform apply

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 4: Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

**Save this password!** You'll need it to login.

### Step 5: Access ArgoCD UI

```bash
# Start port-forward (keep this running in a separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open browser: **http://localhost:8080** (note: HTTP not HTTPS)

- Username: `admin`
- Password: (from Step 4)

## Verification

### Check All Components

```bash
# Gitea
kubectl get pods -n gitea
kubectl get svc -n gitea

# ArgoCD
kubectl get pods -n argocd
kubectl get svc -n argocd

# ArgoCD Applications
kubectl get applications -n argocd
```

Expected output:

- All pods should be `Running`
- 3 ArgoCD applications should be `Synced` and `Healthy`

### Access URLs

Keep these terminals running:

**Terminal 1: Gitea**

```bash
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

**Terminal 2: ArgoCD**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Access:**

- Gitea: http://localhost:3000 (gitea/gitea123)
- ArgoCD: http://localhost:8080 (admin/YOUR_PASSWORD)

## Configuration Details

### Gitea Configuration

- **Database:** SQLite (embedded)
- **Persistence:** Disabled (ephemeral storage)
- **Service:** ClusterIP (access via port-forward)
- **Reason:** Avoids storage issues with EKS Auto Mode

### ArgoCD Configuration

- **Mode:** Insecure (HTTP, no TLS)
- **Service:** ClusterIP on port 80
- **Reason:** Simplified for workshop environment
- **GitOps:** Auto-sync enabled with prune and self-heal

### Repository Structure

**eks-blueprints-workshop-gitops-apps:**

```
guestbook/
├── deployment.yaml
└── service.yaml
```

**eks-blueprints-workshop-gitops-platform:**

```
README.md
.gitkeep
```

**eks-blueprints-workshop-gitops-addons:**

```
README.md
.gitkeep
```

## GitOps Workflow

1. **Make changes** in Gitea repositories (http://localhost:3000)
2. **Commit and push** changes
3. **ArgoCD automatically syncs** (within 3 minutes)
4. **View in ArgoCD UI** (http://localhost:8080)

## Troubleshooting

### Gitea Issues

**Pods not starting:**

```bash
kubectl describe pods -n gitea
kubectl logs -n gitea deployment/gitea
```

**Port-forward fails:**

```bash
# Check if port is already in use
lsof -i :3000

# Kill existing port-forward
pkill -f "kubectl port-forward.*gitea"

# Restart
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

### ArgoCD Issues

**Can't access UI:**

```bash
# Check pods
kubectl get pods -n argocd

# Check service
kubectl get svc argocd-server -n argocd

# Restart port-forward (note: port 80, not 443)
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Applications not syncing:**

```bash
# Check application status
kubectl describe application gitops-apps -n argocd

# Test Gitea connectivity from ArgoCD
kubectl exec -n argocd deployment/argocd-server -- curl -v http://gitea-http.gitea.svc.cluster.local:3000
```

### Common Issues

**"Connection refused" on localhost:8080:**

- Make sure you're using **http://** not https://
- Verify port-forward is running: `lsof -i :8080`
- Check ArgoCD pods are ready: `kubectl get pods -n argocd`

**Gitea repositories empty:**

- Re-run setup script: `./scripts/setup-gitea-repos.sh`
- Check script output for errors

**Data lost after pod restart:**

- This is expected - persistence is disabled
- For production, enable persistence in gitea-values.yaml

## Cleanup

### Remove ArgoCD Only

```bash
cd argocd-bootstrap
terraform destroy
```

### Remove Gitea Only

```bash
cd argocd-eks
terraform destroy
```

### Remove Everything

```bash
# Remove ArgoCD
cd argocd-bootstrap
terraform destroy

# Remove Gitea
cd ..
terraform destroy
```

## Redeployment

To redeploy everything:

1. **Deploy Gitea** (Part 1)
2. **Populate repositories** (Part 1, Step 4)
3. **Deploy ArgoCD** (Part 2)
4. **Get new admin password** (Part 2, Step 4)

**Note:** Admin password changes with each deployment.

## Important Notes

### Data Persistence

⚠️ **Gitea data is ephemeral** - Will be lost if pod restarts

- Reason: Avoids storage issues with EKS Auto Mode
- For production: Enable persistence in `gitea-values.yaml`

### Security

⚠️ **This is a workshop configuration** - Not production-ready

- ArgoCD runs in insecure mode (HTTP)
- Gitea has no persistence
- Default passwords are used

For production:

- Enable TLS for ArgoCD
- Enable persistence for Gitea
- Use proper secrets management
- Configure RBAC properly

### Port Forwards

Port-forwards must stay running:

- Use separate terminal windows
- Or use tmux/screen
- Or run in background with `&`

## Quick Reference

### Essential Commands

```bash
# Gitea port-forward
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# ArgoCD port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# List applications
kubectl get applications -n argocd

# Check Gitea repos
curl -s -u gitea:gitea123 http://localhost:3000/api/v1/user/repos | jq -r '.[].name'
```

### Access Information

| Service | URL                   | Username | Password          |
| ------- | --------------------- | -------- | ----------------- |
| Gitea   | http://localhost:3000 | gitea    | gitea123          |
| ArgoCD  | http://localhost:8080 | admin    | (get from secret) |

### File Locations

```
argocd-eks/
├── main.tf                    # Gitea deployment
├── variables.tf               # Gitea variables
├── terraform.tfvars           # Your cluster config
├── gitea-values.yaml          # Gitea Helm values
├── scripts/
│   └── setup-gitea-repos.sh   # Repository setup script
└── argocd-bootstrap/
    ├── main.tf                # ArgoCD deployment
    ├── variables.tf           # ArgoCD variables
    ├── terraform.tfvars       # ArgoCD config
    └── argocd-values.yaml     # ArgoCD Helm values
```

## Next Steps

1. ✅ Gitea deployed and populated
2. ✅ ArgoCD deployed and syncing
3. 🎯 Deploy applications via GitOps
4. 🎯 Follow AWS EKS Blueprints Workshop labs
5. 🎯 Experiment with GitOps workflows

## Resources

- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Gitea Documentation](https://docs.gitea.io/)

---

**Last Updated:** Based on deployment with EKS Auto Mode cluster
**Tested With:** Terraform 1.0+, kubectl 1.28+, EKS 1.32
