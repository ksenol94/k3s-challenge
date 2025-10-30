output "master_ip" {
  value       = local.master_instance.ip
  description = "Master node IP"
}

output "worker_ips" {
  value       = [for i in var.instances : i.ip if i.role == "worker"]
  description = "Worker node IP list"
}

output "kubeconfig_path" {
  value       = var.kubeconfig_path
  description = "Local path to kubeconfig"
}