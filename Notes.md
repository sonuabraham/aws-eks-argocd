# First, find your cluster name

aws eks list-clusters --region us-east-1

# Update your kubeconfig with the correct cluster

aws eks update-kubeconfig --region us-east-1 --name hub-cluster

# Verify connection

kubectl get nodes

# Now try the port-forward again

kubectl port-forward svc/gitea-http -n gitea 3000:3000

# Create agocd using argocd-bootstrap-helm or argocd-bootstrap-gitops-bridge

# Get the ArgoCD server URL:

kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get argocd password

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Create spoke cluster

sonu@sonu-laptop:~/study/aws/workshops/argocd-eks$ argocd login k8s-argocd-argocdse-24d1a71bd1-de72757d55b560ed.elb.us-east-1.amazonaws.com --username admin --password h39UeWih8AeGsctU --insecure
WARNING: server is not configured with TLS. Proceed (y/n)? y
'admin:login' logged in successfully
Context 'k8s-argocd-argocdse-24d1a71bd1-de72757d55b560ed.elb.us-east-1.amazonaws.com' updated
sonu@sonu-laptop:~/study/aws/workshops/argocd-eks$ argocd repo add http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git --name guestbookrepo --username gitea --password gitea123
Repository 'http://gitea-http.gitea.svc.cluster.local:3000/gitea/eks-blueprints-workshop-gitops-apps.git' added
