# Exports master IP and kubeconfig directory for reference
output "k3s_master_ip" {
  description = "IP address of the K3s master node"
  value       = var.master.ip
}

output "kubeconfig_dir" {
  description = "Local directory where kubeconfig, CA, and token files are stored"
  value       = var.kubeconfig_path
}