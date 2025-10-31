resource "helm_release" "postgresql" {
  name       = "postgresql"
  namespace  = "infra"
  chart      = "${path.module}/charts/postgresql"
  version    = "0.1.0"

  # Stabil & idempotent davranış
  recreate_pods              = true
  replace                    = true
  force_update               = true
  cleanup_on_fail            = true
  disable_openapi_validation = true
  atomic                     = false
  wait                       = true
  timeout                    = 300

  values = [file("${path.module}/charts/postgresql/values.yaml")]

  # NodePort dış erişim (örn: 30432)
  set {
    name  = "service.type"
    value = "NodePort"
  }
  set {
    name  = "service.nodePort"
    value = "30432"
  }

  # Şifre sadece Terraform’dan (manifestlere yazılmaz)
  set_sensitive {
    name  = "auth.password"
    value = var.postgres_password
  }

  depends_on = [
    kubernetes_namespace.infra
  ]

  lifecycle {
    ignore_changes = [status]
  }
}