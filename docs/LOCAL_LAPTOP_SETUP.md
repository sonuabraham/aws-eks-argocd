# Running ArgoCD Workshop from Your Local Laptop

This guide helps you replicate the AWS workshop environment on your local laptop, using your existing EKS cluster.

## Overview

You'll be deploying Gitea (local Git server) on your existing EKS cluster and populating it with ArgoCD example applications, allowing you to run the workshop from your laptop instead of a cloud IDE.

## Prerequisites

### Required Tools on Your Laptop

- **AWS CLI** - configured with credentials
- **kubectl** - Kubernetes command-line tool
- **Terraform** >= 1.0
- **git** - for cloning repositories
- **curl** - for API calls
- **jq** - for JSON parsing (optional but recommended)

### Install Missing Tools

**macOS:**

```bash
brew install awscli kubectl terraform git jq
```

**Linux (Ubuntu/Debian):**

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# jq
sudo apt install jq git curl
```

**Windows (using WSL2):**

```bash
# Use the Linux instructions above in WSL2
# Or use Chocolatey:
choco install awscli kubernetes-cli terraform git jq
```

## Step 1: Configure AWS Access

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity

# List your EKS clusters
aws eks list-clusters --region us-east-1
```

## Step 2: Get Your Existing Cluster Details

```bash
# Set your cluster name and region
export CLUSTER_NAME="hub-cluster"
export AWS_REGION="us-east-1"

# Get VPC ID
export VPC_ID=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --query 'cluster.resourcesVpcConfig.vpcId' \
  --output text)

# Display values
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "VPC ID: $VPC_ID"
```

## Step 3: Configure kubectl

```bash
# Update kubeconfig to access your cluster
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify connection
kubectl get nodes
kubectl get namespaces

# Check if ArgoCD is already installed
kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD not installed"
```

## Step 4: Configure Terraform Variables

```bash
# Create terraform.tfvars with your values
cat > terraform.tfvars <<EOF
region       = "$AWS_REGION"
cluster_name = "$CLUSTER_NAME"
vpc_id       = "$VPC_ID"

enable_gitea  = true
enable_argocd = false  # Set to true if ArgoCD is not installed

tags = {
  Terraform   = "true"
  Environment = "workshop"
  Project     = "local-laptop-setup"
  ManagedBy   = "$(whoami)"
}
EOF

# Review the file
cat terraform.tfvars
```

## Step 5: Deploy Gitea

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy Gitea (takes ~5-10 minutes)
terraform apply

# Wait for Gitea to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gitea -n gitea --timeout=300s
```

## Step 6: Access Gitea from Your Laptop

### Option A: Port Forward (Recommended for local access)

```bash
# Forward Gitea to your laptop
kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Access in browser: http://localhost:3000
# Username: gitea
# Password: gitea123
```

### Option B: LoadBalancer (if AWS LB Controller is installed)

```bash
# Get LoadBalancer URL
kubectl get svc gitea-http -n gitea

# Access via the EXTERNAL-IP shown
```

## Step 7: Populate Gitea with Workshop Content

This script creates 4 repositories with ArgoCD example applications:

```bash
# Make script executable
chmod +x scripts/setup-gitea-repos.sh

# Run the setup script
./scripts/setup-gitea-repos.sh
```

**What this creates:**

- `argocd-example-apps` - All ArgoCD examples
- `guestbook` - Simple Kubernetes app
- `helm-guestbook` - Helm-based app
- `apps` - Application of Applications pattern

## Step 8: Verify Gitea Repositories

```bash
# In your browser, go to http://localhost:3000
# Login with: gitea / gitea123
# You should see 4 repositories created
```

Or verify via API:

```bash
curl -u gitea:gitea123 http://localhost:3000/api/v1/user/repos | jq '.[].name'
```

## Step 9: Deploy ArgoCD Applications

Now you can deploy applications using ArgoCD:

```bash
# Deploy the guestbook application
kubectl apply -f applications/guestbook/application.yaml

# Check application status
kubectl get applications -n argocd

# Or deploy the app-of-apps pattern
kubectl apply -f applications/app-of-apps/root-application.yaml
```

## Step 10: Access ArgoCD UI (if installed)

```bash
# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access in browser: http://localhost:8080
# Username: admin
# Password: (from command above)
```

## Working from Your Laptop

### Daily Workflow

1. **Start port-forwards** (in separate terminal windows):

   ```bash
   # Terminal 1: Gitea
   kubectl port-forward svc/gitea-http -n gitea 3000:3000

   # Terminal 2: ArgoCD (if needed)
   kubectl port-forward svc/argocd-server -n argocd 8080:80
   ```

2. **Make changes to applications** in Gitea repositories

3. **Watch ArgoCD sync** the changes automatically

### Useful Commands

```bash
# Check Gitea status
kubectl get pods -n gitea
kubectl logs -n gitea deployment/gitea

# Check ArgoCD applications
kubectl get applications -n argocd
kubectl describe application guestbook -n argocd

# Sync an application manually
kubectl patch application guestbook -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# Check deployed applications
kubectl get all -n guestbook
```

## Repository Structure in Gitea

After running the setup script, your Gitea will have:

```
gitea/argocd-example-apps/
├── guestbook/
│   ├── guestbook-ui-deployment.yaml
│   └── guestbook-ui-svc.yaml
├── helm-guestbook/
│   ├── Chart.yaml
│   └── templates/
├── apps/
│   └── (Application manifests)
└── (many other examples)

gitea/guestbook/
├── guestbook-ui-deployment.yaml
└── guestbook-ui-svc.yaml

gitea/helm-guestbook/
├── Chart.yaml
├── values.yaml
└── templates/

gitea/apps/
└── (Application of Applications manifests)
```

## Troubleshooting

### Cannot connect to cluster

```bash
# Re-configure kubectl
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Check AWS credentials
aws sts get-caller-identity
```

### Gitea not accessible

```bash
# Check Gitea pods
kubectl get pods -n gitea
kubectl describe pod -n gitea -l app.kubernetes.io/name=gitea

# Check service
kubectl get svc -n gitea
```

### Port forward keeps disconnecting

```bash
# Use a more stable port-forward with auto-reconnect
while true; do
  kubectl port-forward svc/gitea-http -n gitea 3000:3000
  echo "Port forward disconnected, reconnecting..."
  sleep 2
done
```

### Setup script fails

```bash
# Check if jq is installed
which jq || echo "Install jq: brew install jq"

# Check if Gitea is accessible
curl http://localhost:3000

# Run script with debug
bash -x scripts/setup-gitea-repos.sh
```

## Cleanup

### Remove only Gitea (keep cluster)

```bash
terraform destroy
```

### Remove everything

```bash
# Delete ArgoCD applications first
kubectl delete applications --all -n argocd

# Then destroy Gitea
terraform destroy
```

## Tips for Local Development

1. **Use tmux or screen** to manage multiple port-forwards
2. **Create aliases** for common commands:

   ```bash
   alias k='kubectl'
   alias kga='kubectl get applications -n argocd'
   alias gitea-pf='kubectl port-forward svc/gitea-http -n gitea 3000:3000'
   alias argocd-pf='kubectl port-forward svc/argocd-server -n argocd 8080:80'
   ```

3. **Keep a terminal window** with port-forwards running
4. **Use VS Code** with Kubernetes extension for easier management
5. **Bookmark** http://localhost:3000 (Gitea) and http://localhost:8080 (ArgoCD)

## Next Steps

1. Explore the example applications in Gitea
2. Modify application manifests and watch ArgoCD sync
3. Create your own applications in Gitea
4. Practice GitOps workflows
5. Try the app-of-apps pattern

## Cost Considerations

Since you're using your existing cluster:

- **Gitea pod**: Minimal cost (~$0.01-0.05/hour)
- **EBS volume**: ~$0.10/month for 10Gi
- **LoadBalancer**: ~$0.025/hour (if used)

**Remember to run `terraform destroy` when done to remove Gitea resources!**

---

For more details, see:

- [README.md](README.md) - Main documentation
- [GETTING_STARTED.md](GETTING_STARTED.md) - Quick start guide
