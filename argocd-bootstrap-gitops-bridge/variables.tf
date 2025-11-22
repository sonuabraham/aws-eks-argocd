variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "argocd_namespace" {
  description = "Namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.8.13"
}

variable "addons_metadata" {
  description = "Metadata for addons"
  type        = any
  default     = {}
}

variable "addons" {
  description = "Addons configuration"
  type        = any
  default     = {}
}

variable "apps" {
  description = "Applications configuration"
  type        = any
  default     = {}
}
