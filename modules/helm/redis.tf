resource "null_resource" "cleanup_redis" {
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "${path.root}/.work/k3s-master.yaml"
    }
    command = <<EOT
      echo "[Cleanup] Removing any old Redis resources and Helm metadata..."
      kubectl --insecure-skip-tls-verify=true -n infra delete all -l app=redis --ignore-not-found
      kubectl --insecure-skip-tls-verify=true -n infra delete pvc redis-pvc --ignore-not-found
      kubectl --insecure-skip-tls-verify=true -n infra delete secret redis-secret --ignore-not-found
      kubectl --insecure-skip-tls-verify=true -n infra delete secret -l "owner=helm,name=redis" --ignore-not-found
      kubectl --insecure-skip-tls-verify=true -n infra delete configmap -l "owner=helm,name=redis" --ignore-not-found
      echo "[Cleanup] Completed."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "helm_release" "redis" {
  name       = "redis"
  namespace  = "infra"
  chart      = "${path.module}/charts/redis"
  version    = "0.1.0"

  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = true

  values = [file("${path.module}/charts/redis/values.yaml")]

  set_sensitive {
    name  = "auth.password"
    value = var.redis_password
  }

  depends_on = [
    kubernetes_namespace.infra,
    null_resource.cleanup_redis
  ]
}