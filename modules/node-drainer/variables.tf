variable "enabled" {
  default = true
  type = bool
}

variable "lambda_function_name" {
  default = "node-drainer"
  type = string
}

variable "cluster_name" {
  type = string
}

variable "lambda_timeout" {
  type = number
  default = 120
}
