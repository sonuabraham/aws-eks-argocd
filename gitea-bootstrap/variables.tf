variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
  default     = "eks-blueprints-workshop"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "workshop"
}

variable "enable_argocd" {
  description = "Enable ArgoCD installation"
  type        = bool
  default     = true
}

variable "enable_gitea" {
  description = "Enable Gitea installation (local Git server for workshop)"
  type        = bool
  default     = true
}

# Note: These addons are assumed to be already installed on the existing cluster
# variable "enable_aws_load_balancer_controller" {
#   description = "Enable AWS Load Balancer Controller"
#   type        = bool
#   default     = true
# }

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "workshop"
    Project     = "eks-blueprints"
  }
}

variable "secret_name_git_data_addons" {
  description = "Secret name for Git data addons"
  type        = string
  default     = "eks-blueprints-workshop-gitops-addons"
}

variable "secret_name_git_data_platform" {
  description = "Secret name for Git data platform"
  type        = string
  default     = "eks-blueprints-workshop-gitops-platform"
}

variable "secret_name_git_data_workloads" {
  description = "Secret name for Git data workloads"
  type        = string
  default     = "eks-blueprints-workshop-gitops-workloads"
}

variable "git_server_url" {
  description = "Git server URL (used when Gitea is disabled)"
  type        = string
  default     = "https://github.com"
}

variable "git_username" {
  description = "Git username for repository access"
  type        = string
  default     = "gitea"
}

variable "git_password" {
  description = "Git password or token for repository access"
  type        = string
  default     = "gitea123"
  sensitive   = true
}

variable "git_revision" {
  description = "Git revision/branch to use"
  type        = string
  default     = "HEAD"
}
