// kubernetes provider delcaration

provider "kubernetes" {
  host                   = aws_eks_cluster.primary.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.primary.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", "${var.name}-cluster"]
    command     = "aws"
  }
}

// k8s resource definitions for coder
resource "kubernetes_namespace" "coder-ns" {
  metadata {
    name = var.namespace
  }
}

// installs calico cni plugin
resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.primary.name
  addon_name   = "vpc-cni"
}

// helm provider declaration
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.primary.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.primary.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", "${var.name}-cluster"]
      command     = "aws"
    }
  }
}

// pull down coder helm chart & install it
resource "helm_release" "cdr-chart" {
  name       = "coder"
  repository = "https://helm.coder.com"
  chart      = "coder"
  namespace  = var.namespace
  version    = var.coder_version
}