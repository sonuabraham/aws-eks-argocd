################################################################################
# AWS Secrets Manager - Create and Populate Secrets for GitOps Repositories
################################################################################

locals {
  gitea_url    = var.enable_gitea ? "http://gitea-http.gitea.svc.cluster.local:3000" : var.git_server_url
  git_username = var.git_username
  git_password = var.git_password
  git_revision = var.git_revision

  # Repository names
  platform_repo  = "eks-blueprints-workshop-gitops-platform"
  workloads_repo = "eks-blueprints-workshop-gitops-apps"
  addons_repo    = "eks-blueprints-workshop-gitops-addons"
}

################################################################################
# Platform Repository Secret
################################################################################
resource "aws_secretsmanager_secret" "gitops_platform" {
  name                    = var.secret_name_git_data_platform
  description             = "GitOps Platform repository metadata and credentials"
  recovery_window_in_days = 0 # Set to 0 for immediate deletion (workshop only)

  tags = merge(
    var.tags,
    {
      Name = var.secret_name_git_data_platform
      Type = "gitops-repository"
    }
  )
}

resource "aws_secretsmanager_secret_version" "gitops_platform" {
  secret_id = aws_secretsmanager_secret.gitops_platform.id
  secret_string = jsonencode({
    basepath = ""
    org      = local.gitea_url
    password = local.git_password
    path     = "bootstrap"
    repo     = "${local.git_username}/${local.platform_repo}"
    revision = local.git_revision
    url      = "${local.gitea_url}/${local.git_username}/${local.platform_repo}"
    username = local.git_username
  })
}

################################################################################
# Workloads Repository Secret
################################################################################
resource "aws_secretsmanager_secret" "gitops_workloads" {
  name                    = var.secret_name_git_data_workloads
  description             = "GitOps Workloads repository metadata and credentials"
  recovery_window_in_days = 0 # Set to 0 for immediate deletion (workshop only)

  tags = merge(
    var.tags,
    {
      Name = var.secret_name_git_data_workloads
      Type = "gitops-repository"
    }
  )
}

resource "aws_secretsmanager_secret_version" "gitops_workloads" {
  secret_id = aws_secretsmanager_secret.gitops_workloads.id
  secret_string = jsonencode({
    basepath = ""
    org      = local.gitea_url
    password = local.git_password
    path     = "workloads"
    repo     = "${local.git_username}/${local.workloads_repo}"
    revision = local.git_revision
    url      = "${local.gitea_url}/${local.git_username}/${local.workloads_repo}"
    username = local.git_username
  })
}

################################################################################
# Addons Repository Secret
################################################################################
resource "aws_secretsmanager_secret" "gitops_addons" {
  name                    = var.secret_name_git_data_addons
  description             = "GitOps Addons repository metadata and credentials"
  recovery_window_in_days = 0 # Set to 0 for immediate deletion (workshop only)

  tags = merge(
    var.tags,
    {
      Name = var.secret_name_git_data_addons
      Type = "gitops-repository"
    }
  )
}

resource "aws_secretsmanager_secret_version" "gitops_addons" {
  secret_id = aws_secretsmanager_secret.gitops_addons.id
  secret_string = jsonencode({
    basepath = ""
    org      = local.gitea_url
    password = local.git_password
    path     = "."
    repo     = "${local.git_username}/${local.addons_repo}"
    revision = local.git_revision
    url      = "${local.gitea_url}/${local.git_username}/${local.addons_repo}"
    username = local.git_username
  })
}
