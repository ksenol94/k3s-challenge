locals {
  # Defines reusable local variables for node definitions and working directory.
  master_instance = one([
    for i in var.instances : i if i.role == "master"
  ])

  # One or more worker nodes can exist
  worker_instances = [
    for i in var.instances : {
      ip          = i.ip
      ssh_user    = i.ssh_user
      private_key = i.private_key
    } if i.role == "worker"
  ]

  # Local working directory for kubeconfig and temporary files
  work_dir = "${path.root}/.work"
}

# For local Kubectl, Helm etc. connection

locals {
  kubeconfig_path = "${path.root}/.work/k3s-master.yaml"
}

data "local_file" "kubeconfig" {
  filename   = local.kubeconfig_path
  depends_on = [module.k3s]
}

resource "null_resource" "fix_kubeconfig_server" {
  depends_on = [data.local_file.kubeconfig]

  provisioner "local-exec" {
    command = <<EOT
      MASTER_IP=${module.k3s.master_ip}
      if grep -q "127.0.0.1" ${local.kubeconfig_path}; then
        sed -i "s/127\\.0\\.0\\.1/$${MASTER_IP}/g" ${local.kubeconfig_path}
        echo "[INFO] Replaced 127.0.0.1 with $${MASTER_IP} in kubeconfig."
      else
        echo "[INFO] Kubeconfig already has correct server address."
      fi
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
