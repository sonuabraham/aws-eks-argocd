# Quick Start Reference

Essential commands and workflows for the EKS Blueprints Workshop.

## Access Services

```bash
# Gitea (keep running in terminal 1)
kubectl port-forward svc/gitea-http -n gitea 3000:3000
# Access: http://localhost:3000 (gitea/gitea123)

# ArgoCD (keep running in terminal 2)
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Access: http://localhost:8080 (admin/PASSWORD)

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Clone Gitea Repositories

```bash
# Create workspace
mkdir -p ~/gitea-repos && cd ~/gitea-repos

# Clone repositories
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-platform.git
git clone http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-addons.git
```

## Deploy Guestbook Application

```bash
# Deploy via ArgoCD
kubectl apply -f applications/guestbook-gitea/application.yaml

# Check status
kubectl get applications -n argocd
kubectl get pods -n default

# Access guestbook
kubectl port-forward svc/guestbook-ui -n default 8081:80
# Or via LoadBalancer URL
```

## Update Application via GitOps

```bash
# 1. Navigate to repository
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps

# 2. Make changes
nano guestbook/deployment.yaml
# Change replicas: 1 to replicas: 3

# 3. Commit and push
git add .
git commit -m "Scale guestbook to 3 replicas"
git push origin main

# 4. Watch ArgoCD sync (automatic within 3 minutes)
kubectl get applications guestbook -n argocd -w
```

## Repopulate Gitea After Redeployment

```bash
# Run setup script
cd ~/argocd-eks
./scripts/setup-gitea-repos.sh

# Or restore from backup
cd ~/gitea-repos/eks-blueprints-workshop-gitops-apps
git remote set-url origin http://gitea:gitea123@localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git
git push -u origin main --force
```

## Common Commands

```bash
# Check all services
kubectl get pods -n gitea
kubectl get pods -n argocd
kubectl get applications -n argocd

# View ArgoCD application details
kubectl describe application guestbook -n argocd

# Force ArgoCD sync
kubectl patch application guestbook -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# List Gitea repositories
curl -s -u gitea:gitea123 http://localhost:3000/api/v1/user/repos | jq -r '.[].name'

# Check LoadBalancer status
kubectl get svc guestbook-ui -n default
```

## Folder Structure

```
argocd-eks/
├── applications/              # ArgoCD Application manifests
│   ├── guestbook-gitea/      # ✅ Use this one!
│   ├── guestbook/            # Example (external repo)
│   └── ...                   # Other examples
├── docs/                      # Documentation
├── scripts/
│   └── setup-gitea-repos.sh  # Populate Gitea
├── argocd-bootstrap/          # ArgoCD installation
└── main.tf                    # Gitea deployment
```

## GitOps Workflow

```
1. Edit files in ~/gitea-repos/eks-blueprints-workshop-gitops-apps/
2. git add . && git commit -m "message" && git push
3. ArgoCD detects changes (within 3 minutes)
4. ArgoCD syncs to cluster automatically
5. View changes in ArgoCD UI or kubectl
```

## Troubleshooting

```bash
# Can't access ArgoCD
# Use http:// not https://
# Port-forward to port 80: kubectl port-forward svc/argocd-server -n argocd 8080:80

# Can't access Gitea
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Application not syncing
kubectl describe application guestbook -n argocd
kubectl logs -n argocd deployment/argocd-server

# LoadBalancer not accessible
# Check if internet-facing:
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `guestbook`)].Scheme'
```

## Documentation

- **[README.md](README.md)** - Main project overview
- **[docs/COMPLETE_DEPLOYMENT_GUIDE.md](docs/COMPLETE_DEPLOYMENT_GUIDE.md)** - Full deployment guide
- **[docs/APPLICATIONS_FOLDER_GUIDE.md](docs/APPLICATIONS_FOLDER_GUIDE.md)** - Applications folder explained
- **[docs/GITEA_WORKFLOW_GUIDE.md](docs/GITEA_WORKFLOW_GUIDE.md)** - Gitea workflow guide
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Troubleshooting guide

## Key Points

- **applications/guestbook-gitea/** - Use this for deploying from Gitea
- **Other applications/** folders - Examples for learning
- **Clone Gitea repos** to ~/gitea-repos for easy access
- **Run setup script** after redeployment to repopulate Gitea
- **Keep backups** of your Gitea repositories (data is ephemeral)

---

**Quick Links:**

- Gitea: http://localhost:3000
- ArgoCD: http://localhost:8080
- [Complete Guide](docs/COMPLETE_DEPLOYMENT_GUIDE.md)
