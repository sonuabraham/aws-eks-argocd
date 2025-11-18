# ✅ ArgoCD Installation Successful!

ArgoCD has been successfully installed and configured on your EKS cluster!

## Installation Summary

- **Namespace:** argocd
- **Status:** All pods Running
- **Applications:** 3 GitOps applications created and synced
- **Time:** Deployed in ~1.5 minutes

## Access Information

### Admin Credentials

- **Username:** `admin`
- **Password:** `sEZfbctCglfQqjRu`

### Access ArgoCD UI

**Step 1: Start Port Forward**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Step 2: Open Browser**

```
http://localhost:8080
```

**Step 3: Login**

- Username: `admin`
- Password: `sEZfbctCglfQqjRu`

## Deployed Applications

Three GitOps applications are now running and syncing from your Gitea repositories:

| Application         | Repository                              | Status              |
| ------------------- | --------------------------------------- | ------------------- |
| **gitops-apps**     | eks-blueprints-workshop-gitops-apps     | ✅ Synced & Healthy |
| **gitops-platform** | eks-blueprints-workshop-gitops-platform | ✅ Synced & Healthy |
| **gitops-addons**   | eks-blueprints-workshop-gitops-addons   | ✅ Synced & Healthy |

## Verify Installation

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check applications
kubectl get applications -n argocd

# View application details
kubectl describe application gitops-apps -n argocd
```

## What's Next?

### 1. Access ArgoCD UI

Start the port-forward and login to see your applications:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open http://localhost:8080 and explore the UI.

### 2. Deploy the Guestbook Application

The guestbook app is already in your Gitea repository. Let's deploy it:

```bash
# Check what's in the gitops-apps repository
curl -s http://localhost:3000/gitea/eks-blueprints-workshop-gitops-apps/src/branch/main/guestbook

# The guestbook manifests are already there!
# ArgoCD should have already deployed it
kubectl get all -n default | grep guestbook
```

### 3. Make Changes via GitOps

Try modifying the guestbook application:

1. Go to http://localhost:3000
2. Navigate to `eks-blueprints-workshop-gitops-apps` repository
3. Edit `guestbook/deployment.yaml`
4. Change replicas from 1 to 2
5. Commit the change
6. Watch ArgoCD automatically sync the change!

```bash
# Watch the sync happen
kubectl get applications -n argocd -w
```

### 4. View in ArgoCD UI

In the ArgoCD UI:

- Click on `gitops-apps` application
- See the resource tree
- Watch sync status
- View application health

## GitOps Workflow

Now you have a complete GitOps setup:

```
┌─────────────┐
│   Gitea     │  ← Make changes here
│ (localhost) │
└──────┬──────┘
       │
       │ Git Push
       ▼
┌─────────────┐
│   ArgoCD    │  ← Automatically syncs
│  (cluster)  │
└──────┬──────┘
       │
       │ Apply
       ▼
┌─────────────┐
│ Kubernetes  │  ← Applications deployed
│  (cluster)  │
└─────────────┘
```

## Useful Commands

```bash
# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Port forward Gitea
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# List applications
kubectl get applications -n argocd

# Sync an application manually
kubectl patch application gitops-apps -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# View application details
kubectl describe application gitops-apps -n argocd

# Check deployed resources
kubectl get all -n default
```

## Workshop Labs

You can now follow the AWS EKS Blueprints Workshop labs:

1. ✅ **Lab 1:** Environment Setup - COMPLETE
2. ✅ **Lab 2:** Gitea Installation - COMPLETE
3. ✅ **Lab 3:** ArgoCD Installation - COMPLETE
4. 🎯 **Lab 4:** Deploy Applications via GitOps
5. 🎯 **Lab 5:** Modify Applications
6. 🎯 **Lab 6:** App of Apps Pattern

## Troubleshooting

### Can't Access ArgoCD UI

```bash
# Check pods
kubectl get pods -n argocd

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Applications Not Syncing

```bash
# Check application status
kubectl describe application gitops-apps -n argocd

# Check ArgoCD can reach Gitea
kubectl exec -n argocd deployment/argocd-server -- curl -v http://gitea-http.gitea.svc.cluster.local:3000
```

### Forgot Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

## Architecture

Your complete setup:

```
┌─────────────────────────────────────────────────────────┐
│                    EKS Cluster                          │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │    Gitea     │  │   ArgoCD     │  │     Apps     │ │
│  │  (namespace) │  │  (namespace) │  │  (deployed)  │ │
│  │              │  │              │  │              │ │
│  │ • 3 repos    │→ │ • 3 apps     │→ │ • guestbook  │ │
│  │ • SQLite     │  │ • Auto sync  │  │ • ...more    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
         ↑                    ↑
         │                    │
    Port 3000            Port 8080
         │                    │
    ┌────┴────────────────────┴────┐
    │      Your Laptop              │
    │  • Gitea UI                   │
    │  • ArgoCD UI                  │
    └───────────────────────────────┘
```

## Resources

- [ARGOCD_INSTALLATION.md](ARGOCD_INSTALLATION.md) - Installation guide
- [argocd-bootstrap/README.md](argocd-bootstrap/README.md) - Technical docs
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)

---

🎉 **Congratulations! Your GitOps environment is ready!**

Access:

- Gitea: http://localhost:3000 (gitea/gitea123)
- ArgoCD: http://localhost:8080 (admin/sEZfbctCglfQqjRu)
