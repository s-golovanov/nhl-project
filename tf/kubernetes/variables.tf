variable "site_fqdn" {
  type        = string
  description = "Name of the project site"
  default     = "project.net"
}

variable "args" {
  description = "List of additional arguments for metric-server"
  type        = list(any)
  default = [
    "--kubelet-insecure-tls=true",
    "--logtostderr"
  ]
}

variable "test_env_svc_front_app" {
  type        = string
  description = "Name of the service for test env main frontend app"
  default     = "svc-front-app"
}

variable "prod_env_svc_front_app" {
  type        = string
  description = "Name of the service for prod env main frontend app"
  default     = "svc-front-app"
}

variable "tags" {
  type = object({
    Owner       = string
    Environment = string
  })

  description = "Tags for cloud objects of the project"
  default = {
    Owner       = "ProjectOwner"
    Environment = "ProjectEnv"
  }
}
