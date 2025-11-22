output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "The ID of the VPC (from remote state)"
  value       = local.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets (from remote state)"
  value       = local.private_subnets
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
}

output "argocd_cluster_registered" {
  description = "Spoke cluster registered with ArgoCD on hub cluster"
  value       = "Cluster ${local.name} registered with ArgoCD as ${kubernetes_secret.spoke_cluster_secret.metadata[0].name}"
}
