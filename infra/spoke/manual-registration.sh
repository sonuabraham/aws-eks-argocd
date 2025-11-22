#!/bin/bash
# Manual Spoke Cluster Registration with ArgoCD
# This script documents the manual steps that Terraform automates
# Use this for troubleshooting or if you need to register manually

set -e

SPOKE_CLUSTER_NAME="${1:-spoke-staging}"
HUB_CLUSTER_NAME="${2:-hub-cluster}"
REGION="${3:-us-east-1}"

echo "🔧 Manual Registration of Spoke Cluster with ArgoCD"
echo "Spoke Cluster: $SPOKE_CLUSTER_NAME"
echo "Hub Cluster: $HUB_CLUSTER_NAME"
echo "Region: $REGION"
echo ""

# Step 1: Update kubeconfig for both clusters
echo "📋 Step 1: Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $SPOKE_CLUSTER_NAME
aws eks update-kubeconfig --region $REGION --name $HUB_CLUSTER_NAME

# Step 2: Get security group IDs
echo "📋 Step 2: Getting security group IDs..."
HUB_SG=$(aws eks describe-cluster --name $HUB_CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
SPOKE_SG=$(aws eks describe-cluster --name $SPOKE_CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)

echo "Hub SG: $HUB_SG"
echo "Spoke SG: $SPOKE_SG"

# Step 3: Add security group rule
echo "📋 Step 3: Adding security group rule..."
aws ec2 authorize-security-group-ingress \
  --group-id $SPOKE_SG \
  --protocol tcp \
  --port 443 \
  --source-group $HUB_SG \
  --region $REGION || echo "Rule may already exist"

# Step 4: Switch to hub cluster context
echo "📋 Step 4: Switching to hub cluster context..."
kubectl config use-context arn:aws:eks:$REGION:$(aws sts get-caller-identity --query Account --output text):cluster/$HUB_CLUSTER_NAME

# Step 5: Add spoke cluster to ArgoCD
echo "📋 Step 5: Adding spoke cluster to ArgoCD..."
argocd cluster add arn:aws:eks:$REGION:$(aws sts get-caller-identity --query Account --output text):cluster/$SPOKE_CLUSTER_NAME \
  --name $SPOKE_CLUSTER_NAME \
  --yes

# Step 6: Verify
echo "📋 Step 6: Verifying cluster registration..."
argocd cluster list

echo ""
echo "✅ Spoke cluster registration complete!"
echo ""
echo "You can now deploy applications to $SPOKE_CLUSTER_NAME from ArgoCD on $HUB_CLUSTER_NAME"
