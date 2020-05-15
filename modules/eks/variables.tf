variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "region" {
  default = "eu-central-1"
}

variable "cluster_version" {
  default = "1.15"
}

variable "cluster_name" {
  type = string
  default = "eks-test"
}

variable "tags" {
  type = map(string)
}

variable "ami_version" {
  default = "v20200423"
  type = string
}

variable "asg_hook_timeout" {
  default = 360
  description = "timeout in sec to wait until lifecycle is completed"
}
