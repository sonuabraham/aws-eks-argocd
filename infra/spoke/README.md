# EKS Spoke Cluster

This directory contains Terraform configuration to provision an EKS spoke cluster following the AWS EKS Blueprints workshop pattern.

## Overview

The spoke cluster is a separate EKS cluster that can be managed by ArgoCD running on the hub cluster. This enables a hub-and-spoke architecture for multi-cluster management.

**Key Differences from Hub Cluster:**

- Cluster name: `spoke-${terraform.workspace}` (e.g., `spoke-staging`)
- Labels: `environment=<workspace>`, `fleet_member=spoke`
- No ArgoCD installed (managed from hub cluster)
- No GitOps Bridge bootstrap
- Reuses the same VPC as hub cluster

## Architecture

- **VPC**: Reuses existing VPC from `../vpc` (shared with hub cluster)
- **EKS Cluster**: Managed Kubernetes cluster with Auto Mode
- **Compute**: Auto Mode with general-purpose and system node pools
- **Add-ons**: Minimal addons (no ArgoCD, managed from hub)

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.4.0
- kubectl installed
- **VPC must be created first** - Run `terraform apply` in `../vpc` directory
- **Hub cluster should be created** - Run `terraform apply` in `../hub` directory

## Usage

### 1. Create Terraform Workspace

The spoke cluster uses Terraform workspaces to support multiple environments:

```bash
cd infra/spoke
terraform workspace new staging
```

Or switch to an existing workspace:

```bash
terraform workspace select staging
```

The cluster will be named `spoke-staging` (or `spoke-<workspace-name>`).

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if needed. Default values should work for most cases.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

This will create:

- EKS spoke cluster named `spoke-staging` (reusing existing VPC from ../vpc)
- Auto Mode compute with node pools
- ArgoCD service account and RBAC on spoke cluster
- Security group rule allowing hub cluster → spoke cluster API access
- Cluster secret in ArgoCD on hub cluster (automatic registration)

**Automation**: The spoke cluster is automatically registered with ArgoCD on the hub cluster - no manual `argocd cluster add` command needed!

- Minimal cluster configuration

**Note**: The VPC, subnets, and NAT Gateway are reused from the existing VPC infrastructure.

### 6. Configure kubectl

After the cluster is created, configure kubectl to access it:

```bash
aws eks update-kubeconfig --region us-east-1 --name spoke-staging
```

Or use the output command:

```bash
terraform output -raw configure_kubectl | bash
```

### 7. Verify Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Connecting to Hub Cluster

The spoke cluster is **automatically registered** with ArgoCD on the hub cluster during Terraform apply. This includes:

1. ✅ Creating ArgoCD service account on spoke cluster
2. ✅ Creating security group rule to allow hub → spoke communication
3. ✅ Registering spoke cluster secret in ArgoCD namespace on hub cluster

After `terraform apply`, the spoke cluster will appear in ArgoCD:

```bash
argocd cluster list
```

You can now deploy applications to the spoke cluster via ArgoCD on the hub cluster!

## Terraform Workspaces

The spoke cluster uses workspaces to support multiple environments:

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new production

# Switch workspace
terraform workspace select staging

# Show current workspace
terraform workspace show
```

Each workspace creates a separate cluster:

- `staging` workspace → `spoke-staging` cluster
- `production` workspace → `spoke-production` cluster

## Configuration Options

### Kubernetes Version

Change the Kubernetes version in `terraform.tfvars`:

```hcl
kubernetes_version = "1.31"
```

### Using Existing VPC

This spoke cluster reuses the VPC created in `../vpc`. The VPC details are retrieved via Terraform remote state. Make sure the VPC is created before deploying the spoke cluster.

## Outputs

After applying, you'll get:

- `cluster_name`: Name of the EKS cluster (e.g., spoke-staging)
- `cluster_endpoint`: API server endpoint
- `cluster_oidc_provider_arn`: OIDC provider ARN for IRSA
- `vpc_id`: VPC ID (from remote state)
- `configure_kubectl`: Command to configure kubectl

## Cost Considerations

Running this spoke cluster will incur costs for:

- EKS control plane (~$0.10/hour)
- Auto Mode compute (pay for what you use)
- Shared VPC costs (NAT Gateway, etc.)

Estimated cost: ~$80-120/month for default configuration

## Cleanup

To destroy the spoke cluster:

```bash
# Make sure you're in the correct workspace
terraform workspace select staging

# Destroy
terraform destroy
```

**Warning**: This will delete the cluster and all resources. Make sure to backup any important data first.

To delete the workspace after destroying:

```bash
terraform workspace select default
terraform workspace delete staging
```

## Troubleshooting

### Cluster Creation Fails

- Check AWS service quotas (VPCs, EIPs, etc.)
- Verify IAM permissions
- Check CloudWatch logs for detailed errors
- Ensure VPC remote state is accessible

### Nodes Not Ready

```bash
kubectl get nodes
kubectl describe node <node-name>
```

### Remote State Not Found

Make sure the VPC has been created:

```bash
cd ../vpc
terraform apply
```

### Wrong Workspace

Make sure you're in the correct workspace:

```bash
terraform workspace show
terraform workspace select staging
```

## Additional Documentation

- **[QUICK_START.md](QUICK_START.md)** - Quick reference for deploying spoke cluster
- **[AUTOMATION.md](AUTOMATION.md)** - Detailed explanation of automation
- **[manual-registration.sh](manual-registration.sh)** - Script for manual registration (troubleshooting)

## References

- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)
- [EKS Blueprints Terraform Module](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/auto-mode.html)
- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [ArgoCD Cluster Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters)
