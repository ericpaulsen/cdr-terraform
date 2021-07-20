// global variables
name           = "eric"         // prefix for resource names
project_id     = "coder-dev-1"  // your GCP project ID
region         = "us-central1"  // region in which your cluster will be deployed
namespace      = "coder"        // k8s namespace in which Coder will be installed
coder_version  = null           // coder version to be installed - if null, latest version will be used
machine_type   = "n1-highmem-4" // node size to be used by k8s. see additional machine types here: https://cloud.google.com/compute/docs/machine-types
image_type     = "UBUNTU"       // node image. we recommend any image with a Kernel version of 5.x, to be compatible with CVMs: https://coder.com/docs/coder/v1.20/workspaces/cvms
disk_size_gb   = 100            // we recommend a disk of at least 100 GBs, to avoid the potential for pod evictions
min_node_count = 1              // min amount of nodes provisioned by auto-scaling
max_node_count = 4              // max amount of nodes provisioned by auto-scaling