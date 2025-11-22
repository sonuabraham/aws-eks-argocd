variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.32"
}

variable "eks_admin_role_name" {
  description = "EKS admin role"
  type        = string
  default     = "WSParticipantRole"
}

variable "addons" {
  description = "EKS addons"
  type        = any
  default     = {}
}

variable "project_context_prefix" {
  description = "Prefix for project"
  type        = string
  default     = "eks-blueprints-workshop"
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API"
}

variable "enable_irsa" {
  description = "Enable IRSA"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
