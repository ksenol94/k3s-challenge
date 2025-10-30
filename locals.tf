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

