// global variables
// ---
// resource group name
name         = "eric"
node_vm_size = "Standard_B4ms"
location     = "eastus"
// enabling calico will disable traffic between Coder workspaces
network_policy = "calico"
network_plugin = "kubenet"
address_space  = ["10.0.0.0/16"]
// we recommend a disk of at least 100 GBs, to avoid the potential for pod evictions
os_disk_size_gb = 100