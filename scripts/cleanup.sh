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

echo "🏗️  Destroying Terraform infrastructure..."
terraform destroy -auto-approve

echo "🧽 Cleaning up local files..."
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform/

echo "✅ Cleanup complete!"
echo ""
echo "💰 Cost Reminder:"
echo "- Verify in AWS Console that all resources are deleted"
echo "- Check for any remaining Load Balancers, NAT Gateways, or EIPs"
echo "- Review your AWS bill to ensure no unexpected charges"