# Gitea Bootstrap

This directory contains Terraform configuration to install Gitea (a self-hosted Git service) on an existing EKS cluster.

## Overview

Gitea provides a lightweight, self-hosted Git service that can be used as a local Git repository for workshop and development purposes. This is useful for testing GitOps workflows with ArgoCD without requiring external Git services.

## Prerequisites

- An existing EKS cluster
- AWS CLI configured with appropriate credentials
- kubectl configured to access your EKS cluster
- Terraform >= 1.0

## Required Providers

- AWS Provider ~> 5.0
- Kubernetes Provider ~> 2.20
- Helm Provider ~> 2.15

## Usage

1. Copy the example variables file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your cluster and VPC details:

   ```hcl
   cluster_name = "your-eks-cluster-name"
   vpc_id       = "vpc-xxxxx"
   region       = "us-west-2"
   enable_gitea = true
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

- Gitea Helm chart (version 10.1.4) in the `gitea` namespace
- Gitea service accessible via LoadBalancer or NodePort (depending on configuration)

## Accessing Gitea

After installation, get the Gitea service URL:

```bash
kubectl -n gitea get svc gitea-http -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Or for NodePort:

```bash
kubectl -n gitea get svc gitea-http
```

Default credentials are typically configured in `gitea-values.yaml`.

## Configuration

Customize Gitea installation by editing `gitea-values.yaml`. Common configurations include:

- Service type (LoadBalancer, NodePort, ClusterIP)
- Persistence settings
- Admin user credentials
- Database configuration

## Disabling Gitea

To skip Gitea installation, set `enable_gitea = false` in your `terraform.tfvars`.

## Cleanup

To remove Gitea:

```bash
terraform destroy
```

## Notes

- This configuration assumes an existing EKS cluster and VPC
- The cluster should have the necessary addons (like AWS Load Balancer Controller) already installed
- Gitea data persistence depends on the storage class configured in your cluster
