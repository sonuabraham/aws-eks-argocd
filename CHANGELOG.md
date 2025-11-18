# Changelog

All notable changes and fixes to this project.

## [Latest] - 2025-11-11

### Added

- **LoadBalancer Configuration Documentation** - Comprehensive guide for LoadBalancer setup
  - `docs/LOADBALANCER_CONFIGURATION.md` - Complete LoadBalancer configuration guide
  - Covers internet-facing vs internal LoadBalancers
  - Troubleshooting common LoadBalancer issues
  - Alternative access methods
  - Cost and security considerations

### Fixed

- **LoadBalancer Internet Access** - Fixed guestbook LoadBalancer to be internet-facing

  - Added annotation: `service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing`
  - Added annotation: `service.beta.kubernetes.io/aws-load-balancer-type: external`
  - Updated `scripts/setup-gitea-repos.sh` to create services with correct annotations

- **Guestbook Image** - Fixed image pull errors

  - Changed from `gcr.io/heptio-images/ks-guestbook-demo:0.2` (deprecated)
  - To `gcr.io/google-samples/gb-frontend:v5` (actual working guestbook app)
  - Updated `scripts/setup-gitea-repos.sh` with working image

- **ArgoCD Port-Forward** - Corrected port-forward configuration
  - Changed from port 443 (HTTPS) to port 80 (HTTP)
  - Updated all documentation to use `kubectl port-forward svc/argocd-server -n argocd 8080:80`
  - Updated all URLs from `https://localhost:8080` to `http://localhost:8080`

### Changed

- **Documentation Organization** - Moved all documentation to `docs/` folder

  - Created `docs/README.md` as documentation index
  - Organized guides by category
  - Updated all cross-references

- **Repository Structure** - Updated Gitea repository setup
  - `eks-blueprints-workshop-gitops-apps` - Contains working guestbook application
  - `eks-blueprints-workshop-gitops-platform` - Platform configurations
  - `eks-blueprints-workshop-gitops-addons` - Addon configurations

## Configuration Changes

### Guestbook Deployment

```yaml
# Before
containers:
- image: gcr.io/heptio-images/ks-guestbook-demo:0.2  # Broken

# After
containers:
- image: gcr.io/google-samples/gb-frontend:v5  # Working guestbook app
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
```

### Guestbook Service

```yaml
# Before
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
spec:
  type: LoadBalancer
  # No annotations - creates internal LoadBalancer

# After
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
spec:
  type: LoadBalancer
```

### ArgoCD Access

```bash
# Before (incorrect)
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access: https://localhost:8080

# After (correct)
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Access: http://localhost:8080
```

## Documentation Updates

### New Documents

- `docs/LOADBALANCER_CONFIGURATION.md` - LoadBalancer configuration guide
- `docs/README.md` - Documentation index
- `CHANGELOG.md` - This file

### Updated Documents

- `README.md` - Main project README with updated structure
- `docs/COMPLETE_DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `docs/ARGOCD_INSTALLATION.md` - ArgoCD installation guide
- `docs/ARGOCD_SUCCESS.md` - ArgoCD success guide
- `docs/TROUBLESHOOTING.md` - Troubleshooting guide
- `argocd-bootstrap/outputs.tf` - Corrected port-forward commands
- `argocd-bootstrap/README.md` - Updated technical documentation

### Files Moved

All documentation moved from root to `docs/` folder:

- `ARGOCD_INSTALLATION.md` → `docs/ARGOCD_INSTALLATION.md`
- `ARGOCD_SUCCESS.md` → `docs/ARGOCD_SUCCESS.md`
- `COMPLETE_DEPLOYMENT_GUIDE.md` → `docs/COMPLETE_DEPLOYMENT_GUIDE.md`
- `DEPLOYMENT_SUCCESS.md` → `docs/DEPLOYMENT_SUCCESS.md`
- `GETTING_STARTED.md` → `docs/GETTING_STARTED.md`
- `LOCAL_LAPTOP_SETUP.md` → `docs/LOCAL_LAPTOP_SETUP.md`
- `README_DEPLOYMENT.md` → `docs/README_DEPLOYMENT.md`
- `SETUP_COMPLETE.md` → `docs/SETUP_COMPLETE.md`
- `TROUBLESHOOTING.md` → `docs/TROUBLESHOOTING.md`

## Breaking Changes

None. All changes are backward compatible.

## Migration Guide

If you deployed before these changes:

### Update Guestbook Service

```bash
# Clone the repository from Gitea
git clone http://localhost:3000/gitea/eks-blueprints-workshop-gitops-apps.git

# Update service.yaml with new annotations
# Commit and push

# Delete service to force recreation
kubectl delete svc guestbook-ui -n default

# ArgoCD will recreate with new configuration
```

### Update ArgoCD Port-Forward

```bash
# Kill old port-forward
pkill -f "kubectl port-forward.*argocd"

# Start new port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Access at http://localhost:8080 (HTTP not HTTPS)
```

## Known Issues

### Gitea Data Persistence

- **Issue**: Data is ephemeral (lost on pod restart)
- **Reason**: Configured for EKS Auto Mode compatibility
- **Workaround**: Enable persistence in `gitea-values.yaml` if your cluster supports it
- **Status**: By design for workshop environment

### LoadBalancer Provisioning Time

- **Issue**: LoadBalancer takes 2-3 minutes to provision
- **Reason**: AWS ELB provisioning time
- **Workaround**: Use port-forward for immediate access
- **Status**: Expected AWS behavior

## Future Improvements

- [ ] Add support for AWS Load Balancer Controller
- [ ] Add Ingress examples
- [ ] Add TLS/SSL configuration examples
- [ ] Add monitoring and logging setup
- [ ] Add backup and restore procedures

## References

- [AWS EKS Blueprints Workshop](https://catalog.workshops.aws/eks-blueprints-terraform/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Service Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [AWS Load Balancer Documentation](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)
