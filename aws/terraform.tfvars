// variable definitions
name                = "coder"         // prefix for resource names
region              = "us-west-2"     // region in which AWS resources will be deployed
availability_zone_1 = "us-west-2a"    // availability zone for subnet #1
availability_zone_2 = "us-west-2b"    // availability zone for subnet #2
vpc_cidr_block      = "10.128.0.0/16" // vpc id address range
namespace           = "coder"         // the k8s namespace in which coder will be installed
coder_version       = null            // coder version to be installed - if null, latest version will be used
instance_type       = "r6g.xlarge"    // type of ec2 instance to be provisioned. see available instance types here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
max_size            = 4               // max amount of nodes in the auto scaling group
min_size            = 1               // min amount of nodes in the auto scaling group