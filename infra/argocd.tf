# Create argocd namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
  depends_on = [module.eks]
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.argocd_version

  values = [
    yamlencode({
      global = {
        domain = var.argocd_domain
      }
      
      configs = {
        params = {
          "server.insecure" = true
        }
        cm = {
          "url" = "https://${var.argocd_domain}"
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
        }
      }

      server = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        ingress = {
          enabled = false
        }
      }

      controller = {
        metrics = {
          enabled = true
        }
      }

      repoServer = {
        metrics = {
          enabled = true
        }
      }

      applicationSet = {
        enabled = true
      }
    })
  ]

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd
  ]
}

# Create application namespace for our fiber app
resource "kubernetes_namespace" "fiber_app" {
  metadata {
    name = var.app_namespace
    labels = {
      name = var.app_namespace
    }
  }
  depends_on = [module.eks]
}

# Note: ArgoCD Application will be created manually after cluster is ready
# This avoids the chicken-and-egg problem with Kubernetes provider

# Get ArgoCD initial admin password
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

# Service account for ArgoCD to access ECR
resource "aws_iam_role" "argocd_ecr_role" {
  name = "${local.cluster_name}-argocd-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:argocd:argocd-repo-server"
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "argocd_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd_ecr_role.name
}

# ECR Repository for the fiber app
resource "aws_ecr_repository" "fiber_app" {
  name                 = "${var.project_name}/fiber-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "fiber_app_policy" {
  repository = aws_ecr_repository.fiber_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}