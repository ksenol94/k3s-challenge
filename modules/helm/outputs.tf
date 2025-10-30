# Exposes created namespaces and Helm releases as output values.
output "namespaces" {
  value = {
    infra = kubernetes_namespace.infra.metadata[0].name
    apps  = kubernetes_namespace.apps.metadata[0].name
  }
}

output "helm_releases" {
  value = {
    redis = helm_release.redis.name
  }
}