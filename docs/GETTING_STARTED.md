# Quick Start Guide - Gitea Deployment on Existing EKS Cluster

This guide helps you deploy Gitea on your existing EKS cluster that was created using separate environment/vpc and environment/hub directories.

## Prerequisites

- **Existing EKS cluster** (created via environment/vpc and environment/hub)
- **AWS CLI** configured with appropriate permissions
- **kubectl** configured to access your EKS cluster
- **Terraform** >= 1.0 installed

## Step 1: Find Your Existing Resources

First, identify your existing cluster and VPC details:

```bash
# List your EKS clusters
aws eks list-clusters --region <your-region>

# Get cluster details including VPC ID
aws eks describe-cluster --name <your-cluster-name> --region <your-region>

# Or get VPC ID directly
aws eks describe-cluster --name <your-cluster-name> --region <your-region> --query 'cluster.resourcesVpcConfig.vpcId' --output text
```

## Step 2: Configure Your Environment

```bash
# Copy and edit the variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual cluster details
nano terraform.tfvars
```

**Required settings to update:**

- `region`: AWS region where your existing cluster is located
- `cluster_name`: **Your actual existing cluster name**
- `vpc_id`: **Your actual existing VPC ID**
- `enable_gitea`: Set to `true` to deploy Gitea
- `enable_argocd`: Set to `false` if ArgoCD is already installed

## Step 3: Deploy Gitea

```bash
# Initialize Terraform
terraform init

# Review the plan (should only show Gitea resources)
terraform plan

# Deploy Gitea (takes ~5-10 minutes)
terraform apply
```

## Step 4: Verify kubectl Access

```bash
# Ensure kubectl is configured for your existing cluster
kubectl get nodes

# If not configured, update kubeconfig
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
```

## Step 5: Access Gitea

```bash
# Check Gitea deployment status
kubectl get pods -n gitea

# Access Gitea UI via port-forward
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Or via LoadBalancer (if configured)
kubectl get svc -n gitea gitea-http
```

**Gitea Default Credentials:**

- Username: `gitea`
- Password: `gitea123`
- URL: http://localhost:3000 (via port-forward)

## Step 6: Setup Gitea Repositories (Optional)

```bash
# If you have setup scripts, run them to populate Gitea with workshop content
./scripts/setup-gitea-repos.sh
```

## Step 7: Next Steps

With Gitea deployed on your existing cluster, you can now:

1. **Create Git repositories** in Gitea for your applications
2. **Configure ArgoCD** (if not already done) to use Gitea as a source
3. **Follow GitOps workflows** using your existing cluster infrastructure

## What This Configuration Deploys

- ✅ **Gitea** - Local Git server on your existing EKS cluster
- ✅ **Gitea namespace** - Isolated namespace for Gitea resources
- ✅ **LoadBalancer service** - External access to Gitea (if AWS Load Balancer Controller is installed)
- ✅ **Persistent storage** - 10Gi EBS volume for Gitea data

## Quick Commands Reference

```bash
# Check Gitea status
kubectl get pods -n gitea
kubectl get svc -n gitea

# Access Gitea UI
kubectl port-forward svc/gitea-http -n gitea 3000:3000
# Username: gitea, Password: gitea123

# Check Gitea logs
kubectl logs -n gitea deployment/gitea

# Get cluster information
kubectl get nodes
kubectl cluster-info

# Check existing ArgoCD (if installed)
kubectl get pods -n argocd

# Setup Gitea repositories (if script exists)
./scripts/setup-gitea-repos.sh

# Remove only Gitea (keeps existing cluster)
terraform destroy
```

## Troubleshooting

**Issue**: Cannot find existing cluster

```bash
# List all clusters in your region
aws eks list-clusters --region <your-region>

# Check if kubectl is configured correctly
kubectl config current-context
```

**Issue**: Gitea pods not starting

```bash
kubectl describe pods -n gitea
kubectl logs -n gitea deployment/gitea
```

**Issue**: LoadBalancer service pending

```bash
kubectl get svc -n gitea
kubectl describe svc gitea-http -n gitea

# Check if AWS Load Balancer Controller is installed
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

**Issue**: VPC ID not found

```bash
# Get VPC ID from your existing cluster
aws eks describe-cluster --name <cluster-name> --region <region> --query 'cluster.resourcesVpcConfig.vpcId'
```

## Cost Impact

Since this uses your **existing cluster**, the additional cost is minimal:

- **Gitea pod**: ~$0.01-0.05 USD/hour
- **EBS volume**: ~$0.10 USD/month for 10Gi
- **LoadBalancer**: ~$0.025 USD/hour (if using NLB)

**Cleanup**: Run `terraform destroy` to remove only Gitea (keeps your existing cluster intact)

---

🎉 **Gitea is now ready on your existing cluster!** You can start creating repositories and integrating with your GitOps workflows.
