// export aks cluster data for auth into cluster
data "azurerm_kubernetes_cluster" "primary" {
  depends_on          = [azurerm_kubernetes_cluster.primary] // refresh cluster state before reading
  name                = azurerm_kubernetes_cluster.primary.name
  resource_group_name = azurerm_resource_group.primary.name
}

// k8s provider declaration & auth
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.primary.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "coder-ns" {
  metadata {
    name = "coder"
  }
}

// helm provider declaration
provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.primary.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
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