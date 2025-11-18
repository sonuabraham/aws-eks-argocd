#!/bin/bash

# Get ArgoCD admin password
echo "🔐 Getting ArgoCD admin password..."

PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

if [ -z "$PASSWORD" ]; then
    echo "❌ Could not retrieve ArgoCD password. Make sure ArgoCD is installed and running."
    exit 1
fi

echo "✅ ArgoCD Admin Credentials:"
echo "Username: admin"
echo "Password: $PASSWORD"
echo ""
echo "🌐 Access ArgoCD:"
echo "LoadBalancer URL:"
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "LoadBalancer not ready yet"
echo ""
echo "Port Forward (alternative):"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then access: https://localhost:8080"