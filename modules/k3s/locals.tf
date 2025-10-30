# Defines local file paths for kubeconfig, CA, and token storage
locals {
  kube_dir    = trimsuffix(var.kubeconfig_path, "/")
  kubeconfig  = "${local.kube_dir}/k3s-master.yaml"
  server_ca   = "${local.kube_dir}/server-ca.crt"
  tf_token    = "${local.kube_dir}/terraform-token.txt"
  node_token  = "${local.kube_dir}/node-token"
  server_url  = "https://${var.master.ip}:6443"
}