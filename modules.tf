module "node-drainer" {
  source = "./modules/node-drainer"
  enabled = true
  cluster_name = var.cluster_name
}

module "eks" {
  source = "./modules/eks"
  cluster_name = var.cluster_name
  map_users = var.map_users
  map_roles = var.map_roles
  tags = var.tags
  ami_version = var.ami_version
}
