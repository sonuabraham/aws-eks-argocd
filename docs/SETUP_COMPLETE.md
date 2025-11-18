# ✅ Setup Complete!

Your Gitea instance is fully configured and ready to use!

## What Was Set Up

### 1. Gitea Deployment ✅

- **Status:** Running
- **Namespace:** gitea
- **Access:** http://localhost:3000 (via port-forward)
- **Credentials:** gitea / gitea123

### 2. Repositories Created ✅

Four repositories have been created and populated with ArgoCD examples:

| Repository              | Description         | Contents                               |
| ----------------------- | ------------------- | -------------------------------------- |
| **argocd-example-apps** | Complete collection | All ArgoCD examples from official repo |
| **guestbook**           | Simple K8s app      | Basic Kubernetes manifests             |
| **helm-guestbook**      | Helm chart          | Helm-based deployment                  |
| **apps**                | App of Apps         | Application of Applications pattern    |

## Verify Your Setup

### 1. Check Gitea in Browser

Open http://localhost:3000 in your browser and login:

- Username: `gitea`
- Password: `gitea123`

You should see 4 repositories listed.

### 2. Browse a Repository

Click on any repository (e.g., `guestbook`) and you should see:

- `guestbook-ui-deployment.yaml`
- `guestbook-ui-svc.yaml`

### 3. Check Repository URLs

Your repositories are accessible at:

```
http://gitea-http.gitea.svc.cluster.local:3000/gitea/argocd-example-apps.git
http://gitea-http.gitea.svc.cluster.local:3000/gitea/guestbook.git
http://gitea-http.gitea.svc.cluster.local:3000/gitea/helm-guestbook.git
http://gitea-http.gitea.svc.cluster.local:3000/gitea/apps.git
```

## Next Steps

### Option 1: Deploy with ArgoCD (Recommended)

If you have ArgoCD installed, deploy the guestbook application:

```bash
# Apply the ArgoCD Application manifest
kubectl apply -f applications/guestbook/application.yaml

# Watch the application sync
kubectl get applications -n argocd -w

# Check the deployed application
kubectl get all -n guestbook
```

### Option 2: Deploy Manually

Deploy the guestbook app directly:

```bash
# Create namespace
kubectl create namespace guestbook

# Apply manifests from Gitea
kubectl apply -f http://localhost:3000/gitea/guestbook/raw/branch/main/guestbook-ui-deployment.yaml
kubectl apply -f http://localhost:3000/gitea/guestbook/raw/branch/main/guestbook-ui-svc.yaml

# Check deployment
kubectl get pods -n guestbook
```

### Option 3: Install ArgoCD

If ArgoCD is not installed, you can install it:

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Access at http://localhost:8080
```

## Working with Gitea

### Clone a Repository Locally

```bash
# Clone using HTTP
git clone http://localhost:3000/gitea/guestbook.git

# Make changes
cd guestbook
# Edit files...

# Push changes
git add .
git commit -m "Updated deployment"
git push origin main
```

### Create a New Repository

1. Go to http://localhost:3000
2. Click the "+" icon in the top right
3. Select "New Repository"
4. Fill in details and create

### Add Repository to ArgoCD

```bash
# Using ArgoCD CLI
argocd repo add http://gitea-http.gitea.svc.cluster.local:3000/gitea/your-repo.git \
  --username gitea \
  --password gitea123

# Or via UI: Settings → Repositories → Connect Repo
```

## Repository Contents

### argocd-example-apps

Contains multiple example applications:

- `guestbook/` - Simple guestbook
- `helm-guestbook/` - Helm version
- `apps/` - App of apps pattern
- `kustomize-guestbook/` - Kustomize example
- `sock-shop/` - Microservices demo
- And many more...

### guestbook

Simple Kubernetes application:

- `guestbook-ui-deployment.yaml` - Deployment manifest
- `guestbook-ui-svc.yaml` - Service manifest

### helm-guestbook

Helm chart structure:

- `Chart.yaml` - Chart metadata
- `values.yaml` - Default values
- `values-production.yaml` - Production overrides
- `templates/` - Kubernetes templates

### apps

Application of Applications:

- `Chart.yaml` - Helm chart metadata
- `templates/applications.yaml` - ArgoCD Application definitions
- `values.yaml` - Configuration values

## Useful Commands

```bash
# Check Gitea status
kubectl get pods -n gitea
kubectl logs -n gitea deployment/gitea

# Restart Gitea (WARNING: Will lose data if persistence is disabled!)
kubectl rollout restart deployment/gitea -n gitea

# List all repositories via API
curl -s -u gitea:gitea123 http://localhost:3000/api/v1/user/repos | jq -r '.[].name'

# Get repository details
curl -s -u gitea:gitea123 http://localhost:3000/api/v1/repos/gitea/guestbook | jq

# Port forward (if not running)
kubectl port-forward svc/gitea-http -n gitea 3000:3000
```

## Important Reminders

### ⚠️ Data Persistence

**Current Configuration:**

- Persistence is **DISABLED**
- All repository data is stored in memory
- **Data will be LOST if the Gitea pod restarts**

**Why?**

- Avoids storage issues with EKS Auto Mode
- Quick setup for workshop/testing
- No storage costs

**Backup Your Work:**
If you make important changes, back them up:

```bash
# Clone repositories locally
git clone http://localhost:3000/gitea/your-repo.git

# Or push to external Git hosting (GitHub, GitLab, etc.)
```

### 💡 For Production Use

If you need persistent storage:

1. Edit `gitea-values.yaml`
2. Enable persistence with a supported storage class
3. Redeploy: `terraform apply`

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#6-data-loss-after-pod-restart) for details.

## Troubleshooting

If you encounter any issues:

- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common problems
- Check [DEPLOYMENT_SUCCESS.md](DEPLOYMENT_SUCCESS.md) for deployment details
- Review [LOCAL_LAPTOP_SETUP.md](LOCAL_LAPTOP_SETUP.md) for setup instructions

## What's Next?

1. ✅ Gitea is running
2. ✅ Repositories are populated
3. 🎯 **Deploy applications with ArgoCD**
4. 🎯 **Practice GitOps workflows**
5. 🎯 **Experiment with different deployment patterns**

---

🎉 **You're all set! Start deploying applications with GitOps!**

Access Gitea: http://localhost:3000 (gitea/gitea123)
