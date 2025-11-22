output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = var.argocd_namespace
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = data.aws_eks_cluster.cluster.name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
