// reference azure terraform provider
provider "azurerm" {
  features {}
}

// create azure resource group to isolate resources
resource "azurerm_resource_group" "primary" {
  name     = "${var.name}-test"
  location = var.location
}

// create virtual network for k8s to reside in
resource "azurerm_virtual_network" "cluster-network" {
  name                = "${var.name}-vnet"
  location            = var.location
  address_space       = var.address_space
  resource_group_name = azurerm_resource_group.primary.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-subnet"
  resource_group_name  = azurerm_resource_group.primary.name
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.cluster-network.name
}

// create azure cluster to host coder
resource "azurerm_kubernetes_cluster" "primary" {
  name                = "${var.name}-cluster"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  dns_prefix          = "${var.name}-dns"
  addon_profile {
    http_application_routing {
      enabled = true
    }
  }
  network_profile {
    network_policy = var.network_policy
    network_plugin = var.network_plugin
  }
  default_node_pool {
    name       = "${var.name}aksnode"
    node_count = 1
    vm_size    = var.node_vm_size
  }
  identity {
    type = "SystemAssigned"
  }
  tags = {
    Environment = "Dev Cluster"
  }
}

// create separately managed node pool
resource "azurerm_kubernetes_cluster_node_pool" "primary_nodes" {
  name                  = "${var.name}akspool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.primary.id
  enable_auto_scaling   = true
  vm_size               = var.node_vm_size
  max_count             = var.max_count
  min_count             = var.min_count
  os_disk_size_gb       = var.os_disk_size_gb
}