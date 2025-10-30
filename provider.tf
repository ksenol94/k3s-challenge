terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Ensure .work directory exists
resource "null_resource" "prepare_workdir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/.work"
  }
}

# Wait until terraform-token.txt is created
resource "null_resource" "wait_for_token" {
  provisioner "local-exec" {
    command = "bash ${path.module}/modules/k3s/scripts/wait_for_token.sh ${path.root}/.work/terraform-token.txt 60"
  }
  depends_on = [
    null_resource.prepare_workdir,
    module.k3s
  ]
}

# Token Management
data "local_file" "terraform_token" {
  depends_on = [null_resource.wait_for_token]
  filename   = "${var.kubeconfig_path}/terraform-token.txt"
}

provider "kubernetes" {
  host     = "https://${local.master_instance.ip}:6443"
  token    = trim(data.local_file.terraform_token.content, "\n")
  insecure = true
}

provider "helm" {
  kubernetes {
    host     = "https://${local.master_instance.ip}:6443"
    token    = trim(data.local_file.terraform_token.content, "\n")
    insecure = true
  }
}