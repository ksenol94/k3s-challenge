resource "helm_release" "postgresql" {
  name       = "postgresql"
  namespace  = "infra"
  chart      = "${path.module}/charts/postgresql"
  version    = "0.1.0"

  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = true

  values = [
    file("${path.module}/charts/postgresql/values.yaml")
  ]

  set {
    name  = "auth.username"
    value = var.postgres_user
  }

  set_sensitive {
    name  = "auth.password"
    value = var.postgres_password
  }

  depends_on = [kubernetes_namespace.infra]

  lifecycle {
    ignore_changes = [status]
  }
}