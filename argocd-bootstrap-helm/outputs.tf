output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_url" {
  description = "ArgoCD server URL (use port-forward to access)"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:80"
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

output "argocd_ui_access" {
  description = "How to access ArgoCD UI"
  value       = <<-EOT
    1. Run port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:80
    2. Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
    3. Access UI: http://localhost:8080 (note: HTTP not HTTPS - insecure mode for workshop)
    4. Login with username: admin and the password from step 2
  EOT
}

output "gitops_applications" {
  description = "GitOps applications bootstrapped"
  value = var.enable_gitops_bootstrap ? [
    "gitops-apps",
    "gitops-platform",
    "gitops-addons"
  ] : []
}
