# Spoke Cluster Automation

This document explains how the spoke cluster is automatically registered with ArgoCD on the hub cluster.

## What Gets Automated

When you run `terraform apply` in the spoke cluster directory, the following happens automatically:

### 1. Security Group Configuration

- Creates an ingress rule on the spoke cluster's security group
- Allows traffic from the hub cluster's security group on port 443
- Enables ArgoCD pods on the hub cluster to reach the spoke cluster API

### 2. ArgoCD Service Account on Spoke Cluster

- Creates `argocd-manager` service account in `kube-system` namespace
- Creates `argocd-manager-role` ClusterRole with full cluster permissions
- Creates `argocd-manager-role-binding` ClusterRoleBinding
- Creates long-lived token secret for authentication

### 3. Cluster Registration in ArgoCD

- Creates a secret in the `argocd` namespace on the hub cluster
- Secret contains spoke cluster endpoint, CA certificate, and bearer token
- ArgoCD automatically discovers and manages the spoke cluster

## Terraform Resources

### Security Group Rule

```hcl
resource "aws_security_group_rule" "hub_to_spoke_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.hub.outputs.cluster_security_group_id
  security_group_id        = module.eks.cluster_security_group_id
}
```

### Kubernetes Resources on Spoke Cluster

```hcl
resource "kubernetes_service_account" "argocd_manager"
resource "kubernetes_cluster_role" "argocd_manager"
resource "kubernetes_cluster_role_binding" "argocd_manager"
resource "kubernetes_secret" "argocd_manager_token"
```

### ArgoCD Cluster Secret on Hub Cluster

```hcl
resource "kubernetes_secret" "spoke_cluster_secret" {
  provider = kubernetes.hub
  # Creates secret in argocd namespace on hub cluster
}
```

## Prerequisites

Before applying the spoke cluster Terraform:

1. **Hub cluster must be deployed** - The spoke cluster references hub cluster outputs
2. **Hub cluster outputs must include** - `cluster_security_group_id`, `cluster_endpoint`, `cluster_certificate_authority_data`
3. **ArgoCD must be running on hub cluster** - The `argocd` namespace must exist

## Verification

After `terraform apply`, verify the spoke cluster is registered:

```bash
# Switch to hub cluster context
kubectl config use-context hub-cluster

# Check ArgoCD clusters
argocd cluster list

# You should see both hub-cluster and spoke-staging
```

## Manual Registration (Alternative)

If you prefer to register manually or need to troubleshoot, use the provided script:

```bash
cd infra/spoke
./manual-registration.sh spoke-staging hub-cluster us-east-1
```

## Troubleshooting

### Spoke cluster shows "Failed" status in ArgoCD

**Check security group rule:**

```bash
aws ec2 describe-security-groups \
  --group-ids <spoke-sg-id> \
  --region us-east-1 \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`443`]'
```

**Check service account token:**

```bash
kubectl config use-context spoke-staging
kubectl -n kube-system get secret argocd-manager-long-lived-token
```

**Check ArgoCD secret on hub:**

```bash
kubectl config use-context hub-cluster
kubectl -n argocd get secret spoke-staging-cluster -o yaml
```

### Hub cluster outputs not found

Make sure you've applied the hub cluster Terraform and it includes the required outputs:

```bash
cd infra/hub
terraform output cluster_security_group_id
terraform output cluster_endpoint
terraform output cluster_certificate_authority_data
```

If missing, add them to `infra/hub/outputs.tf` and run `terraform apply`.

### ArgoCD namespace doesn't exist on hub

Make sure ArgoCD is installed on the hub cluster:

```bash
kubectl get namespace argocd
kubectl get pods -n argocd
```

## Benefits of Automation

1. **Consistency** - Same process every time, no manual errors
2. **Security** - Proper RBAC and network rules configured automatically
3. **Speed** - Cluster ready to use immediately after Terraform apply
4. **Documentation** - Infrastructure as code documents the setup
5. **Repeatability** - Easy to create multiple spoke clusters

## Cost Implications

The automation adds minimal cost:

- Security group rules: Free
- Kubernetes service accounts: Free
- Secrets: Free

The only costs are from the spoke cluster itself (EKS control plane, compute, etc.).

## References

- [ArgoCD Cluster Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters)
- [EKS Security Groups](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)
- [Kubernetes Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
