#!/bin/bash

# ArgoCD on EKS Workshop - Setup Script
# This script sets up the local environment for the workshop

set -e

echo "🚀 Setting up ArgoCD on EKS Workshop environment..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI v2"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform"
    exit 1
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi

echo "✅ All prerequisites met!"

# Setup Gitea bootstrap
echo "🔧 Setting up Gitea bootstrap..."
if [ ! -f gitea-bootstrap/terraform.tfvars ]; then
    echo "📝 Creating gitea-bootstrap/terraform.tfvars from example..."
    cp gitea-bootstrap/terraform.tfvars.example gitea-bootstrap/terraform.tfvars
    echo "⚠️  Please edit gitea-bootstrap/terraform.tfvars with your cluster settings"
else
    echo "✅ gitea-bootstrap/terraform.tfvars already exists"
fi

cd gitea-bootstrap
terraform init
cd ..

# Setup ArgoCD bootstrap (Helm method)
echo "🔧 Setting up ArgoCD bootstrap (Helm)..."
if [ ! -f argocd-bootstrap-helm/terraform.tfvars ]; then
    echo "📝 Creating argocd-bootstrap-helm/terraform.tfvars from example..."
    cp argocd-bootstrap-helm/terraform.tfvars.example argocd-bootstrap-helm/terraform.tfvars
    echo "⚠️  Please edit argocd-bootstrap-helm/terraform.tfvars with your cluster settings"
else
    echo "✅ argocd-bootstrap-helm/terraform.tfvars already exists"
fi

cd argocd-bootstrap-helm
terraform init
cd ..

# Setup ArgoCD bootstrap (GitOps Bridge method)
echo "🔧 Setting up ArgoCD bootstrap (GitOps Bridge)..."
if [ ! -f argocd-bootstrap-gitops-bridge/terraform.tfvars ]; then
    echo "📝 Creating argocd-bootstrap-gitops-bridge/terraform.tfvars from example..."
    cp argocd-bootstrap-gitops-bridge/terraform.tfvars.example argocd-bootstrap-gitops-bridge/terraform.tfvars
    echo "⚠️  Please edit argocd-bootstrap-gitops-bridge/terraform.tfvars with your cluster settings"
else
    echo "✅ argocd-bootstrap-gitops-bridge/terraform.tfvars already exists"
fi

cd argocd-bootstrap-gitops-bridge
terraform init
cd ..

echo ""
echo "✅ Setup complete! Next steps:"
echo ""
echo "1. Edit configuration files with your cluster details:"
echo "   - gitea-bootstrap/terraform.tfvars"
echo "   - argocd-bootstrap-helm/terraform.tfvars (if using Helm method)"
echo "   - argocd-bootstrap-gitops-bridge/terraform.tfvars (if using GitOps Bridge method)"
echo ""
echo "2. Deploy Gitea:"
echo "   cd gitea-bootstrap"
echo "   terraform plan"
echo "   terraform apply"
echo "   cd .."
echo ""
echo "3. Setup Gitea repositories:"
echo "   ./scripts/setup-gitea-repos.sh"
echo ""
echo "4. Deploy ArgoCD (choose one method):"
echo "   Option A - Helm (simpler):"
echo "     cd argocd-bootstrap-helm"
echo "     terraform plan"
echo "     terraform apply"
echo ""
echo "   Option B - GitOps Bridge (AWS best practices):"
echo "     cd argocd-bootstrap-gitops-bridge"
echo "     terraform plan"
echo "     terraform apply"
echo ""
echo "5. Follow the workshop labs in README.md"