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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "aws" {
  region = var.region
}

################################################################################
# Data Sources for Existing Cluster
################################################################################
data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  name = var.cluster_name
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

provider "kubectl" {
  host                   = data.aws_eks_cluster.existing.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.existing.token
  load_config_file       = false
}

################################################################################
# ArgoCD Namespace
################################################################################
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

################################################################################
# ArgoCD Installation
################################################################################
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/argocd-values.yaml")
  ]

  depends_on = [kubernetes_namespace.argocd]
}

################################################################################
# ArgoCD Admin Password Secret (Optional - for custom password)
################################################################################
# Uncomment if you want to set a custom admin password
# resource "kubernetes_secret" "argocd_admin_password" {
#   metadata {
#     name      = "argocd-initial-admin-secret"
#     namespace = kubernetes_namespace.argocd.metadata[0].name
#   }
#
#   data = {
#     password = bcrypt(var.argocd_admin_password)
#   }
#
#   depends_on = [helm_release.argocd]
# }

################################################################################
# Bootstrap ArgoCD with GitOps Repositories
################################################################################

# Create ArgoCD Application for apps repository
resource "kubectl_manifest" "argocd_apps_application" {
  count = var.enable_gitops_bootstrap ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: gitops-apps
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: ${var.gitea_url}/gitea/eks-blueprints-workshop-gitops-apps.git
        targetRevision: HEAD
        path: .
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd]
}

# Create ArgoCD Application for platform repository
resource "kubectl_manifest" "argocd_platform_application" {
  count = var.enable_gitops_bootstrap ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: gitops-platform
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: ${var.gitea_url}/gitea/eks-blueprints-workshop-gitops-platform.git
        targetRevision: HEAD
        path: .
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd]
}

# Create ArgoCD Application for addons repository
resource "kubectl_manifest" "argocd_addons_application" {
  count = var.enable_gitops_bootstrap ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: gitops-addons
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: ${var.gitea_url}/gitea/eks-blueprints-workshop-gitops-addons.git
        targetRevision: HEAD
        path: .
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd]
}
