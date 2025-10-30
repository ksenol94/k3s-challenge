resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = "apps"
  chart      = "${path.module}/charts/jenkins"
  version    = "0.1.0"

  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = true

  values = [
    file("${path.module}/charts/jenkins/values.yaml")
  ]

  set {
    name  = "controller.adminUser"
    value = var.jenkins_admin_user
  }

  set_sensitive {
    name  = "controller.adminPassword"
    value = var.jenkins_admin_pass
  }

  depends_on = [kubernetes_namespace.apps]
}