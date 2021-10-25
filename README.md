# Deploying Coder via Terraform

These Terraform scripts automate Coder's installation and the provisioning of its necessary infrastructure on the major cloud providers. You can use this repo to quickly deploy Coder, or as a template for a custom Coder installation.

## Structure

Within each directory is a `main.tf` file, which serves as the entry point for Terraform.
It defines the required providers Terraform will use to provision the infrastructure.
In this case, Coder needs the following providers:

- AWS, Azure, GCP, etc.
- Kubernetes
- Helm

Next, the `<cloud-provider>.tf` file provisions the resources below:

- Private network
- Subnet within the private network
- Kubernetes cluster
- Managed node pool with auto-scaling

Once the above resources are created, the `k8s.tf` file steps through the following:

1. Cluster authentication
1. Namespace creation
1. Retrieval of Coder's Helm chart
1. Helm install of Coder

Note that the `terraform.tfvars` file contains the variable definitions.
You are expected to change these values prior to running `terraform apply`.

## Usage

1. [Install Terraform](https://www.terraform.io/downloads.html)
1. [Install `kubectl`](https://kubernetes.io/docs/tasks/tools/)
1. Clone this repository
1. `cd` into your cloud provider directory
1. Run `terraform init` to initialize Terraform
1. Define your variables in the `terraform.tfvars` file
1. Run `terraform plan` to view the resources Terraform will create
1. Run `terraform apply` to provision such resources & install Coder

## Accessing Coder

Once `terraform apply` is complete, you'll need to access Coder via the external IP of the ingress controller.
To do this, take the following steps:

1. Run the cloud provider-specific command to connect to your cluster
1. Run `kubectl get svc -n coder`
1. Copy & paste the `EXTERNAL_IP` value in your browser

## Documentation References

- [Coder](https://coder.com/docs/coder/latest)
- [Terraform](https://www.terraform.io/intro/index.html)
