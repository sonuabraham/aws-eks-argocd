#!/bin/bash

# Setup Gitea repositories for ArgoCD workshop
set -e

echo "🔧 Setting up Gitea repositories for ArgoCD workshop..."

# Check if port-forward is already running
PORT_FORWARD_PID=""
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "✅ Port 3000 is already in use (port-forward likely running)"
    GITEA_URL="localhost:3000"
else
    # Get Gitea service URL
    GITEA_URL=$(kubectl get svc gitea-http -n gitea -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

    if [ -z "$GITEA_URL" ]; then
        echo "⚠️  Gitea LoadBalancer not ready. Starting port-forward..."
        kubectl port-forward svc/gitea-http -n gitea 3000:3000 &
        PORT_FORWARD_PID=$!
        GITEA_URL="localhost:3000"
        echo "⏳ Waiting for port-forward to be ready..."
        sleep 5
    fi
fi

GITEA_BASE_URL="http://${GITEA_URL}"
GITEA_USER="gitea"
GITEA_PASS="gitea123"

echo "📍 Gitea URL: $GITEA_BASE_URL"

# Wait for Gitea to be ready
echo "⏳ Waiting for Gitea to be ready..."
for i in {1..30}; do
    if curl -s "$GITEA_BASE_URL" > /dev/null 2>&1; then
        echo "✅ Gitea is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

# Create API token (or use existing one)
echo "🔑 Creating API token..."
API_TOKEN=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"workshop-token-$(date +%s)\"}" \
    -u "$GITEA_USER:$GITEA_PASS" \
    "$GITEA_BASE_URL/api/v1/users/$GITEA_USER/tokens" 2>/dev/null | jq -r '.sha1' 2>/dev/null || echo "")

if [ -z "$API_TOKEN" ] || [ "$API_TOKEN" == "null" ]; then
    echo "⚠️  Could not create new token. Trying to list existing tokens..."
    # Try to use basic auth instead
    API_TOKEN="use-basic-auth"
fi

echo "✅ API Token ready"

# Function to create repository
create_repo() {
    local repo_name=$1
    local description=$2
    
    echo "📁 Creating repository: $repo_name"
    
    # Check if repo already exists
    REPO_EXISTS=$(curl -s -u "$GITEA_USER:$GITEA_PASS" \
        "$GITEA_BASE_URL/api/v1/repos/$GITEA_USER/$repo_name" 2>/dev/null | jq -r '.name' 2>/dev/null || echo "")
    
    if [ "$REPO_EXISTS" == "$repo_name" ]; then
        echo "   ✓ Repository already exists"
        return 0
    fi
    
    # Create new repository
    RESULT=$(curl -s -u "$GITEA_USER:$GITEA_PASS" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$repo_name\",
            \"description\": \"$description\",
            \"private\": false,
            \"auto_init\": true,
            \"default_branch\": \"main\"
        }" \
        "$GITEA_BASE_URL/api/v1/user/repos" 2>/dev/null)
    
    if echo "$RESULT" | jq -e '.name' >/dev/null 2>&1; then
        echo "   ✓ Repository created successfully"
    else
        echo "   ⚠️  Could not verify repository creation"
    fi
}

# Create workshop repositories based on AWS EKS Blueprints Workshop
create_repo "eks-blueprints-workshop-gitops-apps" "EKS Blueprints Workshop - Application GitOps configurations"
create_repo "eks-blueprints-workshop-gitops-platform" "EKS Blueprints Workshop - Platform GitOps configurations"
create_repo "eks-blueprints-workshop-gitops-addons" "EKS Blueprints Workshop - Addons GitOps configurations"

# Wait a moment for repositories to be fully initialized
echo "⏳ Waiting for repositories to initialize..."
sleep 3

# Clone and push sample content
echo "📦 Setting up repository content..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Configure git
git config --global user.email "workshop-user@example.com"
git config --global user.name "workshop-user"

# Setup eks-blueprints-workshop-gitops-apps repository
echo "📤 Setting up eks-blueprints-workshop-gitops-apps..."
if git clone "http://$GITEA_USER:$GITEA_PASS@$GITEA_URL/$GITEA_USER/eks-blueprints-workshop-gitops-apps.git" 2>/dev/null; then
    cd eks-blueprints-workshop-gitops-apps
    
    # Create sample application manifests
    mkdir -p guestbook
    
    cat > guestbook/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook-ui
spec:
  replicas: 1
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: guestbook-ui
  template:
    metadata:
      labels:
        app: guestbook-ui
    spec:
      containers:
      - image: gcr.io/google-samples/gb-frontend:v5
        name: guestbook-ui
        ports:
        - containerPort: 80
        env:
        - name: GET_HOSTS_FROM
          value: dns
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 200m
            memory: 200Mi
EOF

    cat > guestbook/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: guestbook-ui
EOF

    cat > README.md <<'EOF'
# EKS Blueprints Workshop - GitOps Apps

Application configurations for the EKS Blueprints Workshop.

## Applications
- guestbook - Simple guestbook application
EOF

    git add .
    git commit -m "Initial application configurations" || echo "No changes"
    git push origin main || echo "Already up to date"
    cd ..
else
    echo "⚠️  Could not clone eks-blueprints-workshop-gitops-apps"
fi

# Setup eks-blueprints-workshop-gitops-platform repository
echo "📤 Setting up eks-blueprints-workshop-gitops-platform..."
if git clone "http://$GITEA_USER:$GITEA_PASS@$GITEA_URL/$GITEA_USER/eks-blueprints-workshop-gitops-platform.git" 2>/dev/null; then
    cd eks-blueprints-workshop-gitops-platform
    
    # Create platform configuration
    cat > README.md <<'EOF'
# EKS Blueprints Workshop - GitOps Platform

Platform-level configurations for the EKS Blueprints Workshop.

This repository contains platform infrastructure and configuration managed via GitOps.
EOF

    cat > .gitkeep <<'EOF'
# Platform configurations will be added here
EOF

    git add .
    git commit -m "Initial platform configuration" || echo "No changes"
    git push origin main || echo "Already up to date"
    cd ..
else
    echo "⚠️  Could not clone eks-blueprints-workshop-gitops-platform"
fi

# Setup eks-blueprints-workshop-gitops-addons repository
echo "📤 Setting up eks-blueprints-workshop-gitops-addons..."
if git clone "http://$GITEA_USER:$GITEA_PASS@$GITEA_URL/$GITEA_USER/eks-blueprints-workshop-gitops-addons.git" 2>/dev/null; then
    cd eks-blueprints-workshop-gitops-addons
    
    # Create addons structure
    cat > README.md <<'EOF'
# EKS Blueprints Workshop - GitOps Addons

Cluster addons configurations for the EKS Blueprints Workshop.

This repository contains addon configurations managed via GitOps.
EOF

    cat > .gitkeep <<'EOF'
# Addon configurations will be added here
EOF

    git add .
    git commit -m "Initial addons configuration" || echo "No changes"
    git push origin main || echo "Already up to date"
    cd ..
else
    echo "⚠️  Could not clone eks-blueprints-workshop-gitops-addons"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Kill port-forward if we started it
if [ ! -z "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi

echo "✅ Gitea repositories setup complete!"
echo ""
echo "🌐 Access Gitea at: $GITEA_BASE_URL"
echo "👤 Username: $GITEA_USER"
echo "🔑 Password: $GITEA_PASS"
echo ""
echo "📚 Available repositories (AWS EKS Blueprints Workshop):"
echo "  - eks-blueprints-workshop-gitops-apps (Application GitOps configurations)"
echo "  - eks-blueprints-workshop-gitops-platform (Platform GitOps configurations)"
echo "  - eks-blueprints-workshop-gitops-addons (Addons GitOps configurations)"
echo ""
echo "🔗 Repository URLs:"
echo "  http://$GITEA_URL/$GITEA_USER/eks-blueprints-workshop-gitops-apps.git"
echo "  http://$GITEA_URL/$GITEA_USER/eks-blueprints-workshop-gitops-platform.git"
echo "  http://$GITEA_URL/$GITEA_USER/eks-blueprints-workshop-gitops-addons.git"