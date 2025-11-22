output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = data.aws_eks_cluster.existing.endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = data.aws_eks_cluster.existing.name
}

output "cluster_version" {
  description = "Kubernetes Cluster Version"
  value       = data.aws_eks_cluster.existing.version
}

output "cluster_region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = data.aws_vpc.existing.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = data.aws_subnets.private.ids
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${data.aws_eks_cluster.existing.name}"
}

output "argocd_server_url" {
  description = "ArgoCD server URL (use port-forward to access)"
  value       = var.enable_argocd ? "kubectl port-forward svc/argocd-server -n argocd 8080:80" : "ArgoCD not enabled"
}

output "argocd_admin_password" {
  description = "Command to get ArgoCD admin password"
  value       = var.enable_argocd ? "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : "ArgoCD not enabled"
  sensitive   = true
}

output "gitea_url" {
  description = "Gitea server URL (use port-forward to access)"
  value       = var.enable_gitea ? "kubectl port-forward svc/gitea-http -n gitea 3000:3000" : "Gitea not enabled"
}

output "gitea_credentials" {
  description = "Gitea login credentials"
  value = var.enable_gitea ? {
    username = "gitea"
    password = "gitea123"
    url      = "Access via LoadBalancer or port-forward to localhost:3000"
  } : null
}

################################################################################
# GitOps Repository Secrets Outputs
################################################################################
output "gitops_secrets_created" {
  description = "AWS Secrets Manager secrets created for GitOps repositories"
  value = {
    platform  = aws_secretsmanager_secret.gitops_platform.name
    workloads = aws_secretsmanager_secret.gitops_workloads.name
    addons    = aws_secretsmanager_secret.gitops_addons.name
  }
}

output "gitops_platform_metadata" {
  description = "GitOps platform repository metadata"
  value       = jsondecode(aws_secretsmanager_secret_version.gitops_platform.secret_string)
  sensitive   = true
}

output "gitops_workloads_metadata" {
  description = "GitOps workloads repository metadata"
  value       = jsondecode(aws_secretsmanager_secret_version.gitops_workloads.secret_string)
  sensitive   = true
}

output "gitops_addons_metadata" {
  description = "GitOps addons repository metadata"
  value       = jsondecode(aws_secretsmanager_secret_version.gitops_addons.secret_string)
  sensitive   = true
}
