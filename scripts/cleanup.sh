#!/bin/bash

# ArgoCD on EKS Workshop - Cleanup Script
# This script cleans up all workshop resources

set -e

echo "🧹 Starting cleanup of ArgoCD on EKS Workshop resources..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "⚠️  kubectl not configured or cluster not accessible"
    echo "Proceeding with Terraform destroy only..."
else
    echo "🗑️  Removing ArgoCD applications..."
    
    # Remove all applications
    kubectl delete applications --all -n argocd --timeout=60s || true
    
    # Wait a bit for applications to be removed
    echo "⏳ Waiting for applications to be cleaned up..."
    sleep 30
    
    # Remove any remaining finalizers if stuck
    kubectl patch applications -n argocd --type json --patch='[{"op": "remove", "path": "/metadata/finalizers"}]' --all || true
fi

echo "🏗️  Destroying ArgoCD infrastructure..."
if [ -d "argocd-bootstrap-helm" ]; then
    cd argocd-bootstrap-helm
    terraform destroy -auto-approve || true
    cd ..
fi

if [ -d "argocd-bootstrap-gitops-bridge" ]; then
    cd argocd-bootstrap-gitops-bridge
    terraform destroy -auto-approve || true
    cd ..
fi

echo "🏗️  Destroying Gitea infrastructure..."
if [ -d "gitea-bootstrap" ]; then
    cd gitea-bootstrap
    terraform destroy -auto-approve || true
    cd ..
fi

echo "🧽 Cleaning up local Terraform files..."
rm -rf argocd-bootstrap-helm/.terraform* argocd-bootstrap-helm/terraform.tfstate*
rm -rf argocd-bootstrap-gitops-bridge/.terraform* argocd-bootstrap-gitops-bridge/terraform.tfstate*
rm -rf gitea-bootstrap/.terraform* gitea-bootstrap/terraform.tfstate*

echo "✅ Cleanup complete!"
echo ""
echo "💰 Cost Reminder:"
echo "- Verify in AWS Console that all resources are deleted"
echo "- Check for any remaining Load Balancers, NAT Gateways, or EIPs"
echo "- Review your AWS bill to ensure no unexpected charges"