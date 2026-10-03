module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  # ------------------------------------------------------------
  # EKS Cluster
  # ------------------------------------------------------------
  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  # ------------------------------------------------------------
  # EKS Add-ons
  # ------------------------------------------------------------
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }
  }

  # ------------------------------------------------------------
  # Networking
  # ------------------------------------------------------------
  vpc_id = module.vpc.vpc_id

  # Worker nodes will be created in public subnets
  subnet_ids = module.vpc.public_subnets

  # EKS control plane ENIs
  control_plane_subnet_ids = module.vpc.intra_subnets

  # ------------------------------------------------------------
  # Managed Node Group Defaults
  # ------------------------------------------------------------
  eks_managed_node_group_defaults = {

    instance_types = ["m7i-flex.large"]

    attach_cluster_primary_security_group = true

    tags = {
      Environment = "dev"
      ExtraTag    = "e-commerce-app"
    }
  }

  # ------------------------------------------------------------
  # EKS Managed Node Group
  # ------------------------------------------------------------
  eks_managed_node_groups = {

    tws-demo-ng = {

      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["m7i-flex.large"]
      capacity_type  = "ON_DEMAND"

      disk_size = 35

      use_custom_launch_template = false

      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
        ExtraTag    = "e-commerce-app"
      }
    }
  }

  # ------------------------------------------------------------
  # Node Security Group
  # ------------------------------------------------------------
  # This rule is applied to the EKS node security group.
  # Therefore, all EC2 worker nodes in this node group
  # receive this rule.
  # ------------------------------------------------------------
  node_security_group_additional_rules = {

    ingress_nodeport_tcp = {

      description = "Allow Kubernetes NodePort TCP 30000-32000"

      protocol = "tcp"

      from_port = 30000
      to_port   = 32000

      type = "ingress"

      cidr_blocks = [
        "0.0.0.0/0"
      ]
    }
  }

  # ------------------------------------------------------------
  # Common EKS Tags
  # ------------------------------------------------------------
  tags = local.tags
}


# ------------------------------------------------------------
# Get Running EKS Worker EC2 Instances
# ------------------------------------------------------------

data "aws_instances" "eks_nodes" {

  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [
    module.eks
  ]
}