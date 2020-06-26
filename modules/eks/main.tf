data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.33.0"

  name = "test-vpc"
  cidr = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"]
  public_subnets = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "subnet-type" = "public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "subnet-type" = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
  tags = merge(
  var.tags,
  {
    Cluster = var.cluster_name
  },
  )
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
}

//data "aws_subnet_ids" "private" {
//  vpc_id = module.vpc.vpc_id
//  tags = {
//    subnet-type = "private"
//  }
//}

data "aws_subnet" "subnets_per_zone" {
  for_each = toset(data.aws_availability_zones.available.names)
  vpc_id = module.vpc.vpc_id
  availability_zone = each.value
  tags = {
    subnet-type = "private"
  }
}

//data "aws_subnet" "subnet_zone_b" {
//  availability_zone = data.aws_availability_zones.available.names[1]
//  tags = {
//    subnet-type = "private"
//  }
//  vpc_id = module.vpc.vpc_id
//}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 11.1"

  cluster_name = var.cluster_name
  subnets = module.vpc.private_subnets
  enable_irsa = true

  cluster_version = var.cluster_version

  //  worker_ami_name_filter = "amazon-eks-node-${var.cluster_version}-*v20200423"
  //  worker_ami_name_filter = "amazon-eks-node-${var.cluster_version}-*v20200406"
  worker_ami_name_filter = "amazon-eks-node-${var.cluster_version}-*${var.ami_version}"

  tags = merge(
  var.tags,
  {
    Cluster = var.cluster_name
  },
  )

  vpc_id = module.vpc.vpc_id

  worker_create_initial_lifecycle_hooks = true

  workers_group_defaults = {
    instance_type = "t2.medium"
    additional_userdata = "echo foo bar"
    asg_min_size = 1
    asg_max_size = 5
    asg_desired_capacity = 1
    asg_recreate_on_change = true
    kubelet_extra_args        = "--system-reserved=cpu=100m,memory=100Mi,ephemeral-storage=1Gi --kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=1Gi --eviction-hard=memory.available<100Mi,nodefs.available<5% --enforce-node-allocatable=pods"
    asg_initial_lifecycle_hooks = [
      {
        name = "node-drainer-${var.cluster_name}"
        lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
        default_result = "ABANDON"
        // timeout after 6min
        heartbeat_timeout = var.asg_hook_timeout
      }
    ]
    tags = [
      {
        key = "k8s.io/cluster-autoscaler/enabled"
        propagate_at_launch = "false"
        value = "true"
      },
      {
        key = "k8s.io/cluster-autoscaler/${var.cluster_name}"
        propagate_at_launch = "false"
        value = "true"
      }
    ]
  }

  worker_groups = [
    {
      name = "worker-group-1"
      subnets = [
        data.aws_subnet.subnets_per_zone[data.aws_availability_zones.available.names[0]].id
      ]
    },
    {
      name = "worker-group-2"
      subnets = [
        data.aws_subnet.subnets_per_zone[data.aws_availability_zones.available.names[1]].id
      ]
    }
  ]

  map_users = var.map_users
  map_roles = var.map_roles
}
