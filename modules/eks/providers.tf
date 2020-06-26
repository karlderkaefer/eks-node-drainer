terraform {
  required_version = ">= 0.12.0"
  required_providers {
    helm = "~> 1.0"
    random = "~> 2.1"
    local = "~> 1.2"
    null = "~> 2.1"
    template = "~> 2.1"
  }
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token = data.aws_eks_cluster_auth.cluster.token
  load_config_file = false
  version = "~> 1.11"
}
