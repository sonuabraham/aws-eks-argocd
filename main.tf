terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

################################################################################
# Data Sources for Existing Resources
################################################################################
data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  name = var.cluster_name
}

data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.existing.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.existing.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.existing.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.existing.token
  }
}

# Note: Using existing EKS cluster and VPC created in separate directories

# Note: EKS Blueprints Addons are assumed to be already installed on the existing cluster
# If you need to install additional addons, uncomment and modify the section below:

# ################################################################################
# # EKS Blueprints Addons (Optional)
# ################################################################################
# module "eks_blueprints_addons" {
#   source  = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.0"
#
#   cluster_name      = data.aws_eks_cluster.existing.name
#   cluster_endpoint  = data.aws_eks_cluster.existing.endpoint
#   cluster_version   = data.aws_eks_cluster.existing.version
#   oidc_provider_arn = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer
#
#   # Add any additional addons you need here
#   tags = var.tags
# }

################################################################################
# Gitea - Local Git Server for Workshop
################################################################################
resource "helm_release" "gitea" {
  count = var.enable_gitea ? 1 : 0

  name             = "gitea"
  repository       = "https://dl.gitea.io/charts/"
  chart            = "gitea"
  version          = "10.1.4"
  namespace        = "gitea"
  create_namespace = true

  values = [
    file("${path.module}/gitea-values.yaml")
  ]

  # Ensure the cluster is accessible before deploying
  depends_on = [data.aws_eks_cluster.existing]
}
