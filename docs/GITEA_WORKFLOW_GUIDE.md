# Gitea Workflow Guide

Complete guide for cloning, updating, and managing Gitea repositories for GitOps workflows.

## Overview

Gitea hosts your application code and Kubernetes manifests. When you update files in Gitea, ArgoCD automatically syncs the changes to your cluster.

## Gitea Repositories

Your Gitea instance has 3 repositories:

| Repository                                  | Purpose          | Contents                      |
| ------------------------------------------- | ---------------- | ----------------------------- |
| **eks-blueprints-workshop-gitops-apps**     | Applications     | Guestbook and other apps      |
| **eks-blueprints-workshop-gitops-platform** | Platform configs | Platform-level configurations |
| **eks-blueprints-workshop-gitops-addons**   | Cluster addons   | Addon configurations          |

## Initial Setup (One-Time)

### 1. Ensure Gitea Port-Forward is Running

```bash
# Check if port 3000 is in use
lsof -i :3000

# If not running, start port-forward
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

### 2. Configure Git (If Not Already Done)

```bash
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Store credentials (for convenience)
git config --global credential.helper store
```

## Cloning Gitea Repositories

### Method 1: Clone All Repositories

```bash
# Create a workspace directory
mkdir -p ~/gitea-repos
cd ~/gitea-repos

# Clone all three repositories
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-platform.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-addons.git

# Verify
ls -la
```

### Method 2: Clone Specific Repository

```bash
# Clone just the apps repository
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git

# Or without credentials in URL (will prompt)
git clone http://localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
# Username: gitea
# Password: gitea123
```

### Method 3: Clone via Gitea UI

1. Open http://localhost:3000
2. Login (gitea/gitea123)
3. Click on repository
4. Click "Clone" button
5. Copy HTTPS URL
6. Run: `git clone <URL>`

## Repository Structure

### eks-blueprints-workshop-gitops-apps

```
eks-blueprints-workshop-gitops-apps/
├── README.md
└── guestbook/
    ├── deployment.yaml    # Guestbook deployment
    └── service.yaml       # Guestbook service
```

**This is the main repository you'll work with.**

### eks-blueprints-workshop-gitops-platform

```
eks-blueprints-workshop-gitops-platform/
├── README.md
└── .gitkeep
```

**For platform-level configurations** (currently empty, ready for your configs).

### eks-blueprints-workshop-gitops-addons

```
eks-blueprints-workshop-gitops-addons/
├── README.md
└── .gitkeep
```

**For cluster addons** (currently empty, ready for your addon configs).

## Making Changes to Gitea Repositories

### Basic Workflow

```bash
# 1. Navigate to repository
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps

# 2. Make sure you're on main branch
git checkout main

# 3. Pull latest changes
git pull origin main

# 4. Make your changes
# Edit files with your favorite editor

# 5. Check what changed
git status
git diff

# 6. Stage changes
git add .

# 7. Commit changes
git commit -m "Description of changes"

# 8. Push to Gitea
git push origin main

# 9. ArgoCD will auto-sync within 3 minutes
```

### Example: Update Guestbook Replicas

```bash
# Navigate to repository
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps

# Edit deployment
nano guestbook/deployment.yaml
# Change: replicas: 1
# To: replicas: 3

# Commit and push
git add guestbook/deployment.yaml
git commit -m "Scale guestbook to 3 replicas"
git push origin main

# Watch ArgoCD sync
kubectl get applications guestbook -n argocd -w
```

### Example: Add New Application

```bash
# Navigate to repository
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps

# Create new application folder
mkdir -p nginx-demo

# Create deployment
cat > nginx-demo/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Create service
cat > nginx-demo/service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx-demo
EOF

# Commit and push
git add nginx-demo/
git commit -m "Add nginx demo application"
git push origin main

# Create ArgoCD Application to deploy it
cat > ~/argocd-eks/applications/nginx-demo/application.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-demo
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git
    targetRevision: HEAD
    path: nginx-demo
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# Deploy it
kubectl apply -f ~/argocd-eks/applications/nginx-demo/application.yaml
```

## Updating Gitea Repositories on Redeployment

### Scenario: You Redeployed Gitea and Lost Data

Since Gitea has no persistence, data is lost on pod restart. Here's how to repopulate:

### Method 1: Run Setup Script (Recommended)

```bash
# Navigate to project
cd ~/argocd-eks

# Run setup script
./scripts/setup-gitea-repos.sh

# This recreates all 3 repositories with default content
```

### Method 2: Manual Repository Recreation

```bash
# 1. Create repositories via Gitea UI
# Open http://localhost:3000
# Click "+" → "New Repository"
# Create: eks-blueprints-workshop-gitops-apps

# 2. Clone your local backup (if you have one)
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps

# 3. Update remote URL
git remote set-url origin http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git

# 4. Push to new Gitea
git push -u origin main
```

### Method 3: Restore from Backup

```bash
# If you backed up your repositories
cd ~/gitea-repos-backup/eks-blueprints-workshop-gitops-apps

# Push to new Gitea instance
git remote set-url origin http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
git push -u origin main --force
```

## Best Practices

### 1. Keep Local Clones

```bash
# Always keep local clones of your repositories
mkdir -p ~/gitea-repos
cd ~/gitea-repos

# Clone all repositories
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-platform.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-addons.git
```

### 2. Backup Important Changes

```bash
# Create backup directory
mkdir -p ~/gitea-backups/$(date +%Y%m%d)

# Backup repositories
cp -r ~/gitea-repos/* ~/gitea-backups/$(date +%Y%m%d)/

# Or use git bundle
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps
git bundle create ~/gitea-backups/apps-$(date +%Y%m%d).bundle --all
```

### 3. Use Branches for Experiments

```bash
# Create feature branch
git checkout -b feature/new-app

# Make changes
# ... edit files ...

# Commit to branch
git add .
git commit -m "Add new application"
git push origin feature/new-app

# Merge when ready
git checkout main
git merge feature/new-app
git push origin main
```

### 4. Write Good Commit Messages

```bash
# Good commit messages
git commit -m "Scale guestbook to 3 replicas for load testing"
git commit -m "Add nginx demo application with 2 replicas"
git commit -m "Fix guestbook service LoadBalancer annotations"

# Bad commit messages
git commit -m "update"
git commit -m "fix"
git commit -m "changes"
```

## Common Workflows

### Workflow 1: Update Existing Application

```bash
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps
git pull origin main
# Edit files
git add .
git commit -m "Update application configuration"
git push origin main
# ArgoCD syncs automatically
```

### Workflow 2: Add New Application

```bash
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps
mkdir my-new-app
# Create manifests in my-new-app/
git add my-new-app/
git commit -m "Add my-new-app"
git push origin main
# Create ArgoCD Application manifest
# kubectl apply -f applications/my-new-app/application.yaml
```

### Workflow 3: Rollback Changes

```bash
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps

# View commit history
git log --oneline

# Rollback to previous commit
git revert HEAD
git push origin main

# Or rollback to specific commit
git revert <commit-hash>
git push origin main

# ArgoCD will sync the rollback
```

### Workflow 4: Sync Multiple Repositories

```bash
# Update all repositories
cd ~/gitea-repos

for repo in */; do
  cd "$repo"
  echo "Updating $repo"
  git pull origin main
  cd ..
done
```

## Troubleshooting

### Cannot Clone Repository

```bash
# Check Gitea is accessible
curl http://localhost:3000

# Check port-forward is running
lsof -i :3000

# Restart port-forward if needed
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

### Authentication Failed

```bash
# Use credentials in URL
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git

# Or configure credential helper
git config --global credential.helper store
# Then clone (will prompt once and save)
git clone http://localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
```

### Push Rejected

```bash
# Pull latest changes first
git pull origin main

# Resolve conflicts if any
# Edit conflicted files
git add .
git commit -m "Resolve conflicts"

# Push again
git push origin main
```

### Repository Not Found

```bash
# Check repository exists in Gitea
curl -u gitea:gitea123 http://localhost:3000/api/v1/user/repos | jq -r '.[].name'

# If missing, run setup script
cd ~/argocd-eks
./scripts/setup-gitea-repos.sh
```

## Quick Reference

### Clone All Repositories

```bash
mkdir -p ~/gitea-repos && cd ~/gitea-repos
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-platform.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-addons.git
```

### Update and Push Changes

```bash
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps
git pull origin main
# Make changes
git add .
git commit -m "Your message"
git push origin main
```

### Repopulate After Redeployment

```bash
cd ~/argocd-eks
./scripts/setup-gitea-repos.sh
```

### Backup Repositories

```bash
mkdir -p ~/gitea-backups/$(date +%Y%m%d)
cp -r ~/gitea-repos/* ~/gitea-backups/$(date +%Y%m%d)/
```

## Summary

- **Clone repositories** to your local machine
- **Make changes** locally and push to Gitea
- **ArgoCD watches** Gitea and auto-syncs changes
- **Run setup script** to repopulate after redeployment
- **Keep local backups** since Gitea data is ephemeral

---

**Related Guides:**

- [APPLICATIONS_FOLDER_GUIDE.md](APPLICATIONS_FOLDER_GUIDE.md) - Understanding ArgoCD Applications
- [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md) - Full deployment guide
