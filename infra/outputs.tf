output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID of the VPC where the cluster and nodes are deployed"
  value       = module.vpc.vpc_id
}

output "argocd_server_url" {
  description = "ArgoCD server URL (LoadBalancer)"
  value       = "http://${data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress.0.hostname}"
}

output "argocd_initial_admin_password" {
  description = "ArgoCD initial admin password"
  value       = nonsensitive(data.kubernetes_secret.argocd_initial_admin_secret.data["password"])
  sensitive   = false
}

output "ecr_repository_url" {
  description = "ECR repository URL for the fiber app"
  value       = aws_ecr_repository.fiber_app.repository_url
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Get ArgoCD server service to extract LoadBalancer URL
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}