module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

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

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_group_defaults = {

    instance_types = ["m7i-flex.large"]

    attach_cluster_primary_security_group = true
  }

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

  # NodePort ingress rule
  node_security_group_additional_rules = {

    ingress_nodeport_tcp = {
      description = "Allow NodePort TCP"
      protocol    = "tcp"
      from_port   = 30000
      to_port     = 32767
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  tags = local.tags
}

data "aws_instances" "eks_nodes" {
  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}