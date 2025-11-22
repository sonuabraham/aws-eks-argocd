# ArgoCD Bootstrap with GitOps Bridge

This directory contains Terraform configuration to bootstrap ArgoCD on an EKS cluster using the GitOps Bridge pattern.

## Overview

The GitOps Bridge pattern provides a standardized way to bootstrap ArgoCD and manage addons and applications through a metadata-driven approach. This implementation follows the AWS EKS Blueprints workshop methodology.

## Prerequisites

- An existing EKS cluster
- AWS CLI configured with appropriate credentials
- kubectl configured to access your EKS cluster
- Terraform >= 1.0

## Required Providers

- AWS Provider >= 5.0
- Kubernetes Provider >= 2.20
- Kubectl Provider >= 1.14

## Usage

1. Copy the example variables file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your cluster details:

   ```hcl
   cluster_name = "your-eks-cluster-name"
   environment  = "dev"
   ```

3. Initialize Terraform:

   ```bash
   terraform init
   ```

4. Review the plan:

   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## What Gets Installed

- ArgoCD in the specified namespace (default: `argocd`)
- GitOps Bridge metadata for managing addons and applications
- App of Apps pattern for managing ArgoCD applications

## Accessing ArgoCD

After installation, get the ArgoCD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Get the ArgoCD server URL:

```bash
kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Configuration Options

### ArgoCD Values

You can customize ArgoCD installation by providing Helm values in the `argocd_values` variable:

```hcl
argocd_values = {
  server = {
    service = {
      type = "LoadBalancer"
    }
  }
}
```

### Addons

Enable and configure addons through the `addons` variable:

```hcl
addons = {
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
}
```

### Applications

Define applications to be managed by ArgoCD through the `apps` variable.

## References

- [EKS Blueprints Workshop - Bootstrap ArgoCD](https://catalog.workshops.aws/eks-blueprints-terraform/en-US/030-base/060-install-argocd/010-bootstrap-argocd)
- [GitOps Bridge Terraform Module](https://github.com/gitops-bridge-dev/gitops-bridge)

## Cleanup

To remove ArgoCD and all resources:

```bash
terraform destroy
```
