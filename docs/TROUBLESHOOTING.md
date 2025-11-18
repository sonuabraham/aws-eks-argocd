# Troubleshooting Guide

## Common Issues and Solutions

### 1. Helm Release Failed - Storage Issues

**Error:**

```
Warning: Helm release "" was created but has a failed status
Error: context deadline exceeded
```

**Symptoms:**

- Pods stuck in `Pending` state
- PVCs not binding
- Error: "provisioner is not supported" or "no nodes available to schedule pods"

**Cause:**
EKS Auto Mode or certain cluster configurations don't support the `gp2` storage class or have different storage requirements.

**Solution:**
The gitea-values.yaml has been configured to disable persistence by default. This means:

- ✅ Gitea will start quickly without storage issues
- ⚠️ Data will be lost if the pod restarts
- 💡 For production, configure proper storage for your cluster type

**To enable persistence (if your cluster supports it):**

Edit `gitea-values.yaml`:

```yaml
persistence:
  enabled: true
  size: 10Gi
  storageClass: "gp3" # or your cluster's storage class
```

Check available storage classes:

```bash
kubectl get storageclass
```

### 2. Cannot Access Gitea

**Issue:** Port-forward command doesn't work

**Solution:**

```bash
# Check if Gitea pod is running
kubectl get pods -n gitea

# If pod is running, try port-forward
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Access in browser: http://localhost:3000
```

**Issue:** "Connection refused" when accessing localhost:3000

**Solutions:**

1. Make sure port-forward is running in a separate terminal
2. Check if another service is using port 3000:
   ```bash
   lsof -i :3000  # macOS/Linux
   netstat -ano | findstr :3000  # Windows
   ```
3. Use a different port:
   ```bash
   kubectl port-forward svc/gitea-http -n gitea 8080:3000
   # Access at http://localhost:8080
   ```

### 3. Setup Script Fails

**Error:** `jq: command not found`

**Solution:**

```bash
# macOS
brew install jq

# Linux
sudo apt install jq  # Ubuntu/Debian
sudo yum install jq  # RHEL/CentOS

# Windows (WSL)
sudo apt install jq
```

**Error:** Cannot create API token

**Solution:**

```bash
# Wait for Gitea to be fully ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gitea -n gitea --timeout=300s

# Check Gitea logs
kubectl logs -n gitea deployment/gitea

# Try accessing Gitea manually first
kubectl port-forward svc/gitea-http -n gitea 3000:3000
# Open http://localhost:3000 and verify it loads
```

### 4. Cluster Access Issues

**Error:** "error: You must be logged in to the server (Unauthorized)"

**Solution:**

```bash
# Re-configure kubectl
aws eks update-kubeconfig --region us-east-1 --name your-cluster-name

# Verify AWS credentials
aws sts get-caller-identity

# Check if you have the right permissions
kubectl auth can-i get pods --all-namespaces
```

**Error:** "The connection to the server was refused"

**Solution:**

```bash
# Check if cluster is running
aws eks describe-cluster --name your-cluster-name --region us-east-1 --query 'cluster.status'

# Verify VPN/network connectivity if using private endpoint
# Check security groups allow your IP
```

### 5. Terraform Issues

**Error:** "Error: Kubernetes cluster unreachable"

**Solution:**

```bash
# Ensure kubectl is configured
kubectl get nodes

# If not, configure it
aws eks update-kubeconfig --region us-east-1 --name your-cluster-name

# Then retry terraform
terraform apply
```

**Error:** "Error: vpc_id is required"

**Solution:**

```bash
# Get VPC ID from your cluster
aws eks describe-cluster --name your-cluster-name --region us-east-1 --query 'cluster.resourcesVpcConfig.vpcId' --output text

# Add to terraform.tfvars
echo 'vpc_id = "vpc-xxxxxxxxx"' >> terraform.tfvars
```

### 6. Data Loss After Pod Restart

**Issue:** Gitea repositories disappear after pod restart

**Cause:** Persistence is disabled by default to avoid storage issues

**Solution:**

**Option A: Enable persistence (if your cluster supports it)**

```yaml
# In gitea-values.yaml
persistence:
  enabled: true
  size: 10Gi
  storageClass: "your-storage-class"
```

**Option B: Backup repositories regularly**

```bash
# Export all repositories
kubectl exec -n gitea deployment/gitea -- tar czf /tmp/gitea-backup.tar.gz /data

# Copy backup to local
kubectl cp gitea/gitea-pod-name:/tmp/gitea-backup.tar.gz ./gitea-backup.tar.gz
```

**Option C: Use external Git hosting**

- Use GitHub, GitLab, or Bitbucket instead
- Update ArgoCD application manifests to point to external repos

### 7. ArgoCD Cannot Access Gitea

**Error:** "Unable to connect to repository"

**Solution:**

**Check service connectivity:**

```bash
# From within the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://gitea-http.gitea.svc.cluster.local:3000

# Should return HTML content
```

**Add repository to ArgoCD:**

```bash
# Using internal cluster DNS
argocd repo add http://gitea-http.gitea.svc.cluster.local:3000/gitea/your-repo.git \
  --username gitea \
  --password gitea123
```

**Update application manifests:**

```yaml
spec:
  source:
    repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea/guestbook.git
```

### 8. Port Forward Keeps Disconnecting

**Issue:** Port-forward drops frequently

**Solution:**

**Use a reconnect loop:**

```bash
# Create a script: gitea-portforward.sh
#!/bin/bash
while true; do
  echo "Starting port-forward..."
  kubectl port-forward svc/gitea-http -n gitea 3000:3000
  echo "Port-forward disconnected, reconnecting in 2 seconds..."
  sleep 2
done
```

**Or use kubefwd (more stable):**

```bash
# Install kubefwd
brew install txn2/tap/kubefwd  # macOS

# Forward all services in gitea namespace
sudo kubefwd svc -n gitea
```

### 9. EKS Auto Mode Specific Issues

**Issue:** Pods not scheduling due to compute constraints

**Solution:**

```bash
# Check node status
kubectl get nodes

# Check pod events
kubectl describe pod -n gitea

# EKS Auto Mode automatically provisions nodes
# Wait a few minutes for nodes to be created
```

**Issue:** Storage class not supported

**Solution:**

```bash
# Check available storage classes
kubectl get storageclass

# For EKS Auto Mode, use the default storage class or disable persistence
# Already configured in gitea-values.yaml
```

### 10. Clean Up Failed Deployment

**Complete cleanup:**

```bash
# Delete Helm release
helm uninstall gitea -n gitea

# Delete PVCs
kubectl delete pvc --all -n gitea

# Delete namespace (if needed)
kubectl delete namespace gitea

# Clean Terraform state
terraform destroy

# Re-apply
terraform apply
```

## Getting Help

### Collect Diagnostic Information

```bash
# Gitea pod status
kubectl get pods -n gitea
kubectl describe pod -n gitea -l app.kubernetes.io/name=gitea

# Gitea logs
kubectl logs -n gitea deployment/gitea --tail=100

# Service status
kubectl get svc -n gitea

# PVC status (if persistence enabled)
kubectl get pvc -n gitea

# Helm release status
helm list -n gitea
helm status gitea -n gitea

# Cluster info
kubectl get nodes
kubectl cluster-info
```

### Debug Commands

```bash
# Test Gitea connectivity from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v http://gitea-http.gitea.svc.cluster.local:3000

# Check DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup gitea-http.gitea.svc.cluster.local

# Interactive shell in Gitea pod
kubectl exec -it -n gitea deployment/gitea -- /bin/sh
```

## Still Having Issues?

1. Check the [README.md](README.md) for configuration details
2. Review [LOCAL_LAPTOP_SETUP.md](LOCAL_LAPTOP_SETUP.md) for setup steps
3. Verify your cluster meets the prerequisites
4. Check AWS EKS documentation for cluster-specific requirements
