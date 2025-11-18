variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
}

variable "enable_gitops_bootstrap" {
  description = "Enable GitOps bootstrap with Gitea repositories"
  type        = bool
  default     = true
}

variable "gitea_url" {
  description = "Gitea service URL (internal cluster URL)"
  type        = string
  default     = "http://gitea-http.gitea.svc.cluster.local:3000"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "workshop"
    Project     = "argocd-bootstrap"
  }
}
