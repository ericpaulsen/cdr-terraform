// export access token for auth into k8s cluster
data "google_client_config" "default" {}

data "google_container_cluster" "primary" {
  name     = "${var.name}-cluster"
  location = var.region
}

// k8s provider declaration & auth
provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}

// k8s resource definitions for coder
resource "kubernetes_namespace" "coder-ns" {
  metadata {
    name = "coder"
  }
}

// helm provider declaration
provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
    )
  }
}

// pull down Coder helm chart & install it
resource "helm_release" "cdr-chart" {
  name       = "cdr-chart"
  repository = "https://helm.coder.com"
  chart      = "coder"
  version    = "1.20"
  namespace  = "coder"
}