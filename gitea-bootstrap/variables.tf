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
