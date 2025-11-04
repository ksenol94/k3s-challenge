# Defines sensitive credentials and configuration variables for Helm components.
variable "redis_password" {
  type        = string
  sensitive   = true
  description = "Redis password"
}

variable "jenkins_user" {
  type        = string
  description = "Jenkins admin username"
}

variable "jenkins_password" {
  type        = string
  sensitive   = true
  description = "Jenkins admin password"
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username"
  default     = "postgres"
}

variable "postgres_password" {
  type        = string
  sensitive   = true
  description = "PostgreSQL password"
}

variable "master_ip" {
  description = "K3s master node IP address"
  type        = string
}

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