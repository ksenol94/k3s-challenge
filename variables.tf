variable "instances" {
  description = "List of VM instances (master and workers)"
  type = list(object({
    name        = string
    ip          = string
    ssh_user    = string
    private_key = string
    role        = string # must be 'master' or 'worker'
  }))
}

variable "kubeconfig_path" {
  description = "Path to local work directory (stores kubeconfig, CA, and tokens)"
  type        = string
  default     = "./.work"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

variable "jenkins_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

# variable "git_username" {
#   description = "Git username for Jenkins credential injection"
#   type        = string
# }

# variable "git_password" {
#   description = "Git password or token for Jenkins credential injection"
#   type        = string
#   sensitive   = true
# }