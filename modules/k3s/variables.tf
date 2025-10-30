# Defines connection and storage configuration for K3s setup
variable "master" {
  description = "Connection details for the K3s master node."
  type = object({
    ip          = string
    ssh_user    = string
    private_key = string
  })
}

variable "workers" {
  description = "Optional list of worker nodes that will join the cluster."
  type = list(object({
    ip          = string
    ssh_user    = string
    private_key = string
  }))
  default = []
}

variable "kubeconfig_path" {
  description = "Local directory where kubeconfig, CA, and token files will be stored."
  type        = string
  default     = "./.work"
}