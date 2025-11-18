# ✅ Gitea Deployment Successful!

Gitea has been successfully deployed to your EKS cluster.

## Deployment Summary

- **Cluster:** hub-cluster
- **Region:** us-east-1
- **Namespace:** gitea
- **Status:** Running
- **Configuration:** SQLite database, no persistence (ephemeral)

## Access Gitea

### Step 1: Start Port Forward

In a terminal window, run:

```bash
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

Keep this terminal open while using Gitea.

### Step 2: Access in Browser

Open your browser and go to:

```
http://localhost:3000
```

### Step 3: Login

Use these credentials:

- **Username:** `gitea`
- **Password:** `gitea123`

## Next Steps

### 1. Populate Gitea with Workshop Content

Run the setup script to create repositories with ArgoCD examples:

```bash
chmod +x scripts/setup-gitea-repos.sh
./scripts/setup-gitea-repos.sh
```

This will create 4 repositories:

- `argocd-example-apps` - Complete ArgoCD examples
- `guestbook` - Simple Kubernetes app
- `helm-guestbook` - Helm-based app
- `apps` - Application of Applications

### 2. Deploy ArgoCD Applications

After populating Gitea, deploy applications:

```bash
# Deploy guestbook
kubectl apply -f applications/guestbook/application.yaml

# Check status
kubectl get applications -n argocd
```

### 3. Access ArgoCD (if installed)

```bash
# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access at http://localhost:8080
```

## Important Notes

### ⚠️ Data Persistence

**Current Configuration:**

- Persistence is **DISABLED**
- Data will be **LOST** if the Gitea pod restarts
- This is intentional to avoid storage issues with EKS Auto Mode

**Why?**

- EKS Auto Mode has specific storage requirements
- The `gp2` storage class caused deployment failures
- Disabling persistence ensures Gitea starts successfully

**For Production Use:**
If you need persistent storage:

1. Check available storage classes: `kubectl get storageclass`
2. Edit `gitea-values.yaml` and enable persistence with a supported storage class
3. Redeploy: `terraform apply`

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#6-data-loss-after-pod-restart) for details.

### 💡 Recommendations

**For Workshop/Testing:**

- Current configuration is perfect
- Quick to deploy and tear down
- No storage costs

**For Production:**

- Enable persistence with proper storage
- Use external database (PostgreSQL/MySQL)
- Configure backups
- Use ingress with TLS instead of port-forward

## Useful Commands

```bash
# Check Gitea status
kubectl get pods -n gitea
kubectl logs -n gitea deployment/gitea

# Restart Gitea (will lose data!)
kubectl rollout restart deployment/gitea -n gitea

# Access Gitea shell
kubectl exec -it -n gitea deployment/gitea -- /bin/sh

# Port forward (keep running)
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

## Troubleshooting

If you encounter issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to common problems.

## Cleanup

When you're done with the workshop:

```bash
# Remove Gitea (keeps cluster)
terraform destroy

# Or just delete the namespace
kubectl delete namespace gitea
```

## Resources

- [README.md](README.md) - Main documentation
- [LOCAL_LAPTOP_SETUP.md](LOCAL_LAPTOP_SETUP.md) - Laptop setup guide
- [GETTING_STARTED.md](GETTING_STARTED.md) - Quick start guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions

---

🎉 **You're all set! Start using Gitea for your GitOps workflows!**
