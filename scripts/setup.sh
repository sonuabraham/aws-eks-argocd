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

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✅ Please edit terraform.tfvars with your preferred settings"
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

echo "✅ Setup complete! Next steps:"
echo "1. Edit terraform.tfvars with your settings"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
echo "4. Run: ./scripts/setup-gitea-repos.sh (after terraform apply)"
echo "5. Follow the workshop labs in README.md"