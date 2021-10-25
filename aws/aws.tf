// aws provider declaration
provider "aws" {
  region = var.region
}

// create vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "Coder VPC"
  }
}

// internet gateway connected to the vpc
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Coder Internet Gateway"
  }
}

// create vpc route table
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

// create subnet 1
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.128.0.0/22"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
}

// associate route table with subnet
resource "aws_route_table_association" "routetablea1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable.id

  depends_on = [
    aws_subnet.subnet1
  ]
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.128.4.0/22"
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "routetablea2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable.id

  depends_on = [
    aws_subnet.subnet2
  ]
}

// create node group iam role
resource "aws_iam_role" "coderiamnoderole" {
  name = "coder-eks-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// attach eks node policy to iam role
resource "aws_iam_role_policy_attachment" "primary-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.coderiamnoderole.name
}

// attach cni policy to iam role
resource "aws_iam_role_policy_attachment" "primary-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.coderiamnoderole.name
}

// attach ecr policy to iam role
resource "aws_iam_role_policy_attachment" "primary-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.coderiamnoderole.name
}

// create eks iam role 
resource "aws_iam_role" "coderiamrole" {
  name = "${var.name}-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// attach eks cluster policy to iam role
resource "aws_iam_role_policy_attachment" "coder-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.coderiamrole.name
}

// attach eks service policy to iam role
resource "aws_iam_role_policy_attachment" "coder-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.coderiamrole.name
}

// create eks cluster & check if IAM perms are created
resource "aws_eks_cluster" "primary" {
  name     = "${var.name}-cluster"
  role_arn = aws_iam_role.coderiamrole.arn


  vpc_config {
    subnet_ids         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_group_ids = [aws_security_group.codersg.id]
  }

  // ensure that iam perms are created before and deleted after eks cluster handling
  depends_on = [
    aws_iam_role_policy_attachment.coder-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.coder-AmazonEKSServicePolicy
  ]
}

// ami data source
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_1.21/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-20211005"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

// provide ec2 nodes with cluster credentials
locals {
  codercvm-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.primary.endpoint}' --b64-cluster-ca '${aws_eks_cluster.primary.certificate_authority.0.data}' '${var.name}-cluster'
USERDATA
}

// ec2 launch template
resource "aws_launch_template" "coder-node" {
  name                   = "${var.name}-node"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = "coder-key-pair"
  vpc_security_group_ids = [aws_security_group.codersg-node.id]
  user_data              = base64encode(local.codercvm-node-userdata)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Coder"
    }
  }
}

// key pair for accessing ec2 instances
resource "aws_key_pair" "coder-key-pair" {
  key_name   = "${var.name}-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxajecymvENWJdjgs/Y6ExTNRGWlqV78/67lLgg/IgVH60aQ++uFEVGBBDjBC1I7db2yBr10gEcwbdy6AYyU9A0p7hdBM8e8sXh+4RNInKzgSTPpqcPmbVo/Eb9/+WA+wH6MVEI3h9tL3u2MFPsXpKmWy76fOOwI7/K/89llXx1GWFqmXl9myL8yY2llKdmBP1VfNR2i7bGxhdj1xgdz+ssufctVJRRsRTjYgPK93/yHKk5ePH+ZK45Gt0wpGijCpw/c4pjgO8h7flD4jQCHfkTRPZQt+pXQ1EHi77Plp0zBPgZR5ZDZyGBDx22j3Us+ENifTXOZ7baKk4lgKsy9592hakT+SFKh8eGzDn5KkgCVeRJZZEqmx2lZ230uGiqxmpG53Y2DFTwBMnxfKBrygW9JIvzmylvo5tiI0TCs1PlRr57NUYucbsOASzgVttcABLZ13QKFRp5UAh+5nWkZqzBKwFPV3cSf3P+WG/MQ6w1XCUjsbNujOHA7j1n/c+YyM= eric@erics-MacBook-Pro"
}

// create node group for ec2 instances
resource "aws_eks_node_group" "codercvms" {
  cluster_name    = aws_eks_cluster.primary.name
  node_group_name = "codercvms"
  node_role_arn   = aws_iam_role.coderiamnoderole.arn
  subnet_ids      = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "Coder"
  }

  scaling_config {
    desired_size = 1
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.primary-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.primary-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.primary-AmazonEC2ContainerRegistryReadOnly,
  ]

  launch_template {
    id      = aws_launch_template.coder-node.id
    version = aws_launch_template.coder-node.latest_version
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

// cluster security group
resource "aws_security_group" "codersg" {
  name        = "${var.name}-cluster-sg"
  description = "Cluster communication from master to worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                             = "Coder"
    "kubernetes.io/cluster/codervpc" = "owned"
  }
}

// node security group
resource "aws_security_group" "codersg-node" {
  name        = "${var.name}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                             = "Coder"
    "kubernetes.io/cluster/codervpc" = "owned"
  }
}

resource "aws_security_group_rule" "coder-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.codersg-node.id
  source_security_group_id = aws_security_group.codersg-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "coder-node-ingress-cluster-https" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.codersg-node.id
  source_security_group_id = aws_security_group.codersg.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "coder-node-ingress-cluster-others" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.codersg-node.id
  source_security_group_id = aws_security_group.codersg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "coder-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.codersg.id
  source_security_group_id = aws_security_group.codersg-node.id
  to_port                  = 443
  type                     = "ingress"
}