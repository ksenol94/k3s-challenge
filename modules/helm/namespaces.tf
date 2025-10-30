# Infrastructure namespace (infra)
resource "kubernetes_namespace" "infra" {
  metadata {
    name = "infra"
  }
}

# Application namespace (apps)
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}