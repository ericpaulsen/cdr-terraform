# Retrieve an access token as the Terraform runner
data "google_client_config" "default" {}

data "google_container_cluster" "primary" {
  name     = "${var.name}-cluster"
  location = var.region
}

# k8s provider declaration
provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}

# k8s resource definitions for Coder
resource "kubernetes_namespace" "coder-ns" {
  metadata {
    name = "coder"
  }
}

# helm provider declaration
provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
    )
  }
}

resource "helm_release" "cdr-chart" {
  name       = "cdr-chart"
  repository = "https://helm.coder.com"
  chart      = "coder"
  version    = "1.20"
  namespace  = "coder"
}