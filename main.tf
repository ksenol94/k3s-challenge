# Deploys K3s cluster (master + workers)
module "k3s" {
  source = "./modules/k3s"

  master = {
    ip          = local.master_instance.ip
    ssh_user    = local.master_instance.ssh_user
    private_key = local.master_instance.private_key
  }

  workers         = local.worker_instances
  kubeconfig_path = var.kubeconfig_path
}

# Deploys Helm-managed applications (Redis, PostgreSQL, Jenkins)
module "helm" {
  source = "./modules/helm"

  redis_password     = var.redis_password
  jenkins_admin_user = var.jenkins_admin_user
  jenkins_admin_pass = var.jenkins_admin_pass
  postgres_user      = var.postgres_user
  postgres_password  = var.postgres_password

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [
    module.k3s,
    null_resource.wait_for_token
  ]
}
