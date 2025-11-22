# Spoke Cluster Quick Start

## Prerequisites

✅ VPC created (`cd infra/vpc && terraform apply`)  
✅ Hub cluster created (`cd infra/hub && terraform apply`)  
✅ ArgoCD running on hub cluster

## Deploy Spoke Cluster

```bash
cd infra/spoke

# Create workspace
terraform workspace new staging

# Initialize
terraform init

# Apply
terraform apply
```

## Verify

```bash
# Check spoke cluster
aws eks list-clusters --region us-east-1

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name spoke-staging

# Check nodes
kubectl get nodes

# Switch to hub cluster
kubectl config use-context hub-cluster

# Verify spoke cluster in ArgoCD
argocd cluster list
```

## Deploy Application to Spoke Cluster

```bash
# Create application targeting spoke cluster
argocd app create guestbook-spoke \
  --repo http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git \
  --path guestbook \
  --dest-server https://<SPOKE-CLUSTER-ENDPOINT> \
  --dest-namespace guestbook \
  --sync-policy automated

# Or get the endpoint from Terraform
SPOKE_ENDPOINT=$(cd infra/spoke && terraform output -raw cluster_endpoint)

argocd app create guestbook-spoke \
  --repo http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git \
  --path guestbook \
  --dest-server $SPOKE_ENDPOINT \
  --dest-namespace guestbook \
  --sync-policy automated
```

## Cleanup

```bash
cd infra/spoke

# Make sure you're in the right workspace
terraform workspace select staging

# Destroy
terraform destroy

# Delete workspace
terraform workspace select default
terraform workspace delete staging
```

## Troubleshooting

### Spoke cluster not showing in ArgoCD

```bash
# Check security group rule
aws ec2 describe-security-groups --group-ids <spoke-sg> --region us-east-1

# Check ArgoCD secret
kubectl -n argocd get secrets | grep spoke

# Re-run manual registration
./manual-registration.sh spoke-staging hub-cluster us-east-1
```

### Can't connect to spoke cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name spoke-staging

# Test connection
kubectl get nodes

# Check cluster status
aws eks describe-cluster --name spoke-staging --region us-east-1
```

## Next Steps

- Deploy applications to spoke cluster via ArgoCD
- Create ApplicationSets for multi-cluster deployments
- Set up monitoring and logging
- Configure cluster-specific policies
