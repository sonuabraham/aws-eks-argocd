# Applications Folder Guide

This guide explains the purpose of the `applications/` folder and how to use ArgoCD Application manifests.

## Overview

The `applications/` folder contains **ArgoCD Application manifests**. These are Kubernetes custom resources that tell ArgoCD:

- **Where** to find application code (Git repository)
- **What** to deploy (path in the repository)
- **Where** to deploy it (namespace and cluster)
- **How** to sync it (automatic or manual)

## Folder Structure

```
applications/
├── guestbook-gitea/           # ✅ ACTIVE - Guestbook from Gitea
│   └── application.yaml       # Points to Gitea repository
├── guestbook/                 # Example - Original guestbook
│   └── application.yaml       # Points to external repo
├── eks-workshop-app-dev/      # Example - Workshop app dev
│   └── application.yaml
├── eks-workshop-gitops-dev/   # Example - Workshop gitops dev
│   └── application.yaml
├── eks-workshop-gitops-prod/  # Example - Workshop gitops prod
│   └── application.yaml
├── app-of-apps/               # Example - App of Apps pattern
│   ├── applications/
│   └── root-application.yaml
└── workloads/                 # Example - Additional workloads
    ├── nginx/
    └── redis/
```

## Purpose of Each Folder

### 1. guestbook-gitea/ ✅ ACTIVE

**Purpose:** Deploy guestbook from your local Gitea repository

**File:** `application.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  source:
    repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git
    path: guestbook
  destination:
    namespace: default
```

**Usage:**

```bash
# Deploy guestbook from Gitea
kubectl apply -f applications/guestbook-gitea/application.yaml

# Check status
kubectl get application guestbook -n argocd
```

**This is the one you should use!** It points to your local Gitea repository.

### 2. guestbook/

**Purpose:** Example pointing to external ArgoCD examples repository

**Difference from guestbook-gitea:**

- Points to GitHub: `https://github.com/argoproj/argocd-example-apps.git`
- Not using your local Gitea
- Provided as an example

**When to use:** If you want to deploy from external repositories

### 3. eks-workshop-app-dev/

**Purpose:** Example for deploying workshop app to dev environment

**Status:** Template/Example - needs configuration

**When to use:** When following specific workshop labs

### 4. eks-workshop-gitops-dev/ & eks-workshop-gitops-prod/

**Purpose:** Examples for different environments (dev/prod)

**Status:** Templates showing environment-specific deployments

**When to use:** To learn about multi-environment deployments

### 5. app-of-apps/

**Purpose:** Demonstrates the "App of Apps" pattern

**What it does:** One ArgoCD Application that creates other Applications

**When to use:** To manage multiple applications as a group

### 6. workloads/

**Purpose:** Additional example workloads (nginx, redis)

**Status:** Examples for learning

## How ArgoCD Applications Work

### Application Manifest Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app # Application name in ArgoCD
  namespace: argocd # Must be 'argocd'
spec:
  project: default # ArgoCD project
  source:
    repoURL: <GIT_REPO_URL> # Where to get the code
    targetRevision: HEAD # Branch/tag/commit
    path: <PATH_IN_REPO> # Folder in the repo
  destination:
    server: https://kubernetes.default.svc # Target cluster
    namespace: <TARGET_NAMESPACE> # Where to deploy
  syncPolicy:
    automated: # Auto-sync settings
      prune: true # Delete removed resources
      selfHeal: true # Auto-fix drift
```

### Key Components

**Source:**

- `repoURL`: Git repository URL
- `path`: Folder containing Kubernetes manifests
- `targetRevision`: Branch (HEAD = main branch)

**Destination:**

- `server`: Kubernetes cluster API
- `namespace`: Target namespace for deployment

**SyncPolicy:**

- `automated`: Enable auto-sync
- `prune`: Delete resources removed from Git
- `selfHeal`: Revert manual changes

## Common Use Cases

### Deploy Application from Gitea

```bash
# Use the guestbook-gitea application
kubectl apply -f applications/guestbook-gitea/application.yaml

# View in ArgoCD UI
# Open http://localhost:8080
```

### Create Your Own Application

```bash
# Create new application manifest
cat > applications/my-app/application.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git
    targetRevision: HEAD
    path: my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Apply it
kubectl apply -f applications/my-app/application.yaml
```

### Deploy Multiple Applications

```bash
# Deploy all applications in a folder
kubectl apply -f applications/guestbook-gitea/
kubectl apply -f applications/eks-workshop-app-dev/

# Or deploy all at once
kubectl apply -f applications/ --recursive
```

## Relationship with Gitea Repositories

### How They Connect

```
┌─────────────────────────────────────────────────────────────┐
│  applications/guestbook-gitea/application.yaml              │
│  (ArgoCD Application Manifest)                              │
│                                                              │
│  Points to ──────────────────────────────────────────────┐  │
└──────────────────────────────────────────────────────────┼──┘
                                                            │
                                                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Gitea Repository                                           │
│  eks-blueprints-workshop-gitops-apps                        │
│                                                              │
│  guestbook/                                                 │
│  ├── deployment.yaml  ◄── ArgoCD deploys these             │
│  └── service.yaml     ◄── to your cluster                  │
└─────────────────────────────────────────────────────────────┘
```

### The Flow

1. **You create** an Application manifest in `applications/` folder
2. **You apply** it to Kubernetes: `kubectl apply -f applications/guestbook-gitea/application.yaml`
3. **ArgoCD reads** the manifest and knows where to find the code (Gitea)
4. **ArgoCD clones** the Gitea repository
5. **ArgoCD deploys** the Kubernetes manifests from the repository
6. **ArgoCD watches** for changes in Gitea and auto-syncs

## Which Applications to Use

### For This Workshop

**Use these:**

- ✅ `applications/guestbook-gitea/` - Deploys from your Gitea

**Don't use these (examples only):**

- ❌ `applications/guestbook/` - Points to external GitHub
- ❌ `applications/eks-workshop-*` - Templates needing configuration
- ❌ `applications/app-of-apps/` - Advanced pattern example
- ❌ `applications/workloads/` - Additional examples

### For Learning

All folders are useful for learning different patterns:

- **guestbook-gitea** - Basic GitOps deployment
- **app-of-apps** - Managing multiple apps
- **eks-workshop-\*** - Environment-specific deployments

## Managing Applications

### View Applications

```bash
# List all applications
kubectl get applications -n argocd

# Get application details
kubectl describe application guestbook -n argocd

# View in ArgoCD UI
# Open http://localhost:8080
```

### Sync Application

```bash
# Manual sync
kubectl patch application guestbook -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# Or use ArgoCD UI - click "Sync" button
```

### Delete Application

```bash
# Delete application (and deployed resources)
kubectl delete -f applications/guestbook-gitea/application.yaml

# Or by name
kubectl delete application guestbook -n argocd
```

## Best Practices

### 1. One Application per Folder

```
applications/
├── app1/
│   └── application.yaml
├── app2/
│   └── application.yaml
└── app3/
    └── application.yaml
```

### 2. Use Descriptive Names

```yaml
metadata:
  name: guestbook-production # Clear and specific
  # Not: app1, test, my-app
```

### 3. Enable Auto-Sync for GitOps

```yaml
syncPolicy:
  automated:
    prune: true # Remove deleted resources
    selfHeal: true # Fix manual changes
```

### 4. Use CreateNamespace Option

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true # Auto-create target namespace
```

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
kubectl describe application guestbook -n argocd

# Check ArgoCD can reach Gitea
kubectl exec -n argocd deployment/argocd-server -- \
  curl http://gitea-http.gitea.svc.cluster.local:3000
```

### Application Stuck in Progressing

```bash
# Check deployed resources
kubectl get all -n <target-namespace>

# Check pod logs
kubectl logs -n <target-namespace> <pod-name>
```

### Application Shows OutOfSync

```bash
# Force refresh
kubectl patch application guestbook -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

## Summary

- **applications/** folder contains ArgoCD Application manifests
- **Each manifest** tells ArgoCD what to deploy and where
- **guestbook-gitea/** is the active one pointing to your Gitea
- **Other folders** are examples for learning
- **Apply manifests** with `kubectl apply -f applications/...`
- **View in ArgoCD UI** at http://localhost:8080

---

**Next:** See [GITEA_WORKFLOW_GUIDE.md](GITEA_WORKFLOW_GUIDE.md) for working with Gitea repositories
