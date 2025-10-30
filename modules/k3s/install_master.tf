# Installs and configures K3s master node (Ubuntu prep + K3s setup + token creation)

resource "null_resource" "k3s_master_install" {
  triggers = {
    master_ip      = var.master.ip
    ssh_user       = var.master.ssh_user
    private_key    = var.master.private_key
    kubeconfig_dir = local.kube_dir
  }

  connection {
    host        = var.master.ip
    user        = var.master.ssh_user
    private_key = file(var.master.private_key)
  }

  # Upload necessary installation scripts to the remote node
  provisioner "file" {
    source      = "${path.module}/scripts/prepare_ubuntu.sh"
    destination = "/tmp/prepare_ubuntu.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_k3s_master.sh"
    destination = "/tmp/install_k3s_master.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/create_or_refresh_token.sh"
    destination = "/tmp/create_or_refresh_token.sh"
  }

# Execute installation scripts in sequence on the master node
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/prepare_ubuntu.sh /tmp/install_k3s_master.sh /tmp/create_or_refresh_token.sh",
      "sudo /tmp/prepare_ubuntu.sh",
      "sudo /tmp/install_k3s_master.sh",
      "sudo /tmp/create_or_refresh_token.sh"
    ]
  }
}

# Fetches kubeconfig, CA certificate, and Terraform static token from master
resource "null_resource" "k3s_master_fetch_and_token" {
  triggers = {
    master_ip      = var.master.ip
    ssh_user       = var.master.ssh_user
    private_key    = var.master.private_key
    kubeconfig_dir = local.kube_dir
  }

  connection {
    host        = var.master.ip
    user        = var.master.ssh_user
    private_key = file(var.master.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/fetch_kubeconfig.sh"
    destination = "/tmp/fetch_kubeconfig.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/fetch_ca_and_token.sh"
    destination = "/tmp/fetch_ca_and_token.sh"
  }

# Wait briefly to ensure API and token readiness
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/fetch_kubeconfig.sh /tmp/fetch_ca_and_token.sh",
      "echo '[WAIT] Waiting for kubeconfig & token readiness...'; sleep 3"
    ]
  }
  
# Download kubeconfig and Terraform token + CA to local .work dir
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/fetch_kubeconfig.sh '${var.master.ip}' '${var.master.ssh_user}' '${var.master.private_key}' '${local.kubeconfig}'"
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/fetch_ca_and_token.sh '${var.master.ip}' '${var.master.ssh_user}' '${var.master.private_key}' '${local.server_ca}' '${local.tf_token}'"
  }

  depends_on = [null_resource.k3s_master_install]
}

# Reads the node-token from master for worker node registration
resource "null_resource" "k3s_master_read_node_token" {
  triggers = {
    master_ip   = var.master.ip
    ssh_user    = var.master.ssh_user
    private_key = var.master.private_key
  }

# Fetch node-token via SSH to local .work directory
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/fetch_node_token.sh '${var.master.ip}' '${var.master.ssh_user}' '${var.master.private_key}' '${local.node_token}'"
  }

  depends_on = [null_resource.k3s_master_fetch_and_token]
}