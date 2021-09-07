// variable definitions
name            = "coder"          // resource group name
location        = "eastus"        // the region in which your cluster will be deployed
namespace       = "coder"         // the k8s namespace in which coder will be installed
coder_version   = null            // coder version to be installed - if null, latest version will be used
node_vm_size    = "Standard_B4ms" // node size to be used by k8s. see additional VM sizes: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
os_disk_size_gb = 100             // we recommend a disk of at least 100 GBs, to avoid the potential for pod evictions
min_count       = 1               // min amount of nodes provisioned by auto-scaling
max_count       = 4               // max amount of nodes provisioned by auto-scaling
network_policy  = "calico"        // enabling calico will disable traffic between Coder workspaces
network_plugin  = "kubenet"       // used to set up routing rules & communication with the Azure Virtual Network
address_space   = "10.0.0.0/16" // IP address space for the Azure virtual network to be created
