# Jenkins Image Build
resource "null_resource" "jenkins_image_build_import" {
  connection {
    host        = var.instances[0].ip
    user        = var.instances[0].ssh_user
    private_key = file(var.instances[0].private_key)
  }

  provisioner "file" {
    source      = "${path.module}/charts/jenkins/jenkins_image.sh"
    destination = "/tmp/jenkins_image.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jenkins_image.sh",
      "bash /tmp/jenkins_image.sh"
    ]
  }
}

# Deploy Jenkins via Helm
resource "helm_release" "jenkins" {
  name             = "jenkins"
  namespace        = "apps"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.8.105"
  create_namespace = true

  depends_on = [
    null_resource.jenkins_image_build_import,
    helm_release.redis,
    helm_release.postgresql
  ]

  values = [
    templatefile("${path.module}/charts/jenkins/values.yaml", {
      jenkins_user     = var.jenkins_user
      jenkins_password = var.jenkins_password
    })
  ]
}

# RBAC - Jenkins permissions
resource "kubernetes_role" "jenkins_role" {
  metadata {
    name      = "jenkins-role"
    namespace = "infra"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [helm_release.jenkins]
}

resource "kubernetes_role_binding" "jenkins_binding" {
  metadata {
    name      = "jenkins-binding"
    namespace = "infra"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.jenkins_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = "apps"
  }

  depends_on = [helm_release.jenkins]
}

# Cluster-wide permissions
resource "kubernetes_cluster_role" "jenkins_clusterrole" {
  metadata {
    name = "jenkins-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "configmaps", "secrets", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps", "batch", "extensions"]
    resources  = ["deployments", "replicasets", "cronjobs", "jobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["helm.sh"]
    resources  = ["releases"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "jenkins_clusterbinding" {
  metadata {
    name = "jenkins-cluster-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins_clusterrole.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = "apps"
  }
}

output "jenkins_url" {
  value = "http://${var.instances[0].ip}:32000"
}