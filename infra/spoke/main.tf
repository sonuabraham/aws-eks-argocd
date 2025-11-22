data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

locals {
  context_prefix  = var.project_context_prefix
  name            = "spoke-${terraform.workspace}"
  region          = data.aws_region.current.id
  cluster_version = var.kubernetes_version
  enable_irsa     = var.enable_irsa

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  authentication_mode = var.authentication_mode

  tags = {
    Blueprint    = local.name
    GithubRepo   = "github.com/aws-samples/eks-blueprints-for-terraform-workshop"
    environment  = terraform.workspace
    fleet_member = "spoke"
  }
}

data "aws_iam_role" "eks_admin_role_name" {
  name = var.eks_admin_role_name
}

################################################################################
# EKS Cluster
################################################################################
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.34.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  authentication_mode = local.authentication_mode

  enable_irsa = local.enable_irsa

  # Combine root account, current user/role and additional roles to be able to access the cluster KMS key - required for terraform updates
  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]
  ))

  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # One access entry with a policy associated
    eks_admin = {
      principal_arn = data.aws_iam_role.eks_admin_role_name.arn
      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }

  tags = local.tags
}

################################################################################
# Security Group Rule - Allow Hub Cluster to access Spoke Cluster API
################################################################################
resource "aws_security_group_rule" "hub_to_spoke_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.hub.outputs.cluster_security_group_id
  security_group_id        = module.eks.cluster_security_group_id
  description              = "Allow hub cluster to access spoke cluster API"
}

################################################################################
# ArgoCD Service Account for Spoke Cluster Management
################################################################################
resource "kubernetes_service_account" "argocd_manager" {
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "argocd_manager" {
  metadata {
    name = "argocd-manager-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "argocd_manager" {
  metadata {
    name = "argocd-manager-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argocd_manager.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.argocd_manager.metadata[0].name
    namespace = kubernetes_service_account.argocd_manager.metadata[0].namespace
  }
}

resource "kubernetes_secret" "argocd_manager_token" {
  metadata {
    name      = "argocd-manager-long-lived-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.argocd_manager.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

################################################################################
# Register Spoke Cluster with ArgoCD on Hub Cluster
################################################################################
provider "kubernetes" {
  alias = "hub"

  host                   = data.terraform_remote_state.hub.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.hub.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.hub.outputs.cluster_name, "--region", local.region]
  }
}

resource "kubernetes_secret" "spoke_cluster_secret" {
  provider = kubernetes.hub

  metadata {
    name      = "${local.name}-cluster"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = local.name
    server = module.eks.cluster_endpoint
    config = jsonencode({
      bearerToken = kubernetes_secret.argocd_manager_token.data["token"]
      tlsClientConfig = {
        insecure = false
        caData   = module.eks.cluster_certificate_authority_data
      }
    })
  }

  depends_on = [
    kubernetes_secret.argocd_manager_token,
    aws_security_group_rule.hub_to_spoke_api
  ]
}
