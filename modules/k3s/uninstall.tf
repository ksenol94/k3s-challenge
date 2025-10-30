# Removes K3s from master and worker nodes during destroy phase only

# Safely uninstalls K3s agent on all worker nodes
resource "null_resource" "k3s_worker_uninstall" {
  for_each = { for i, w in var.workers : i => w }

  triggers = {
    worker_ip   = each.value.ip
    ssh_user    = each.value.ssh_user
    private_key = each.value.private_key
  }

  connection {
    host        = self.triggers.worker_ip
    user        = self.triggers.ssh_user
    private_key = file(self.triggers.private_key)
  }

# Upload uninstall script (only during destroy)
  provisioner "file" {
    when        = destroy
    source      = "${path.module}/scripts/uninstall_k3s.sh"
    destination = "/tmp/uninstall_k3s.sh"
  }
# Execute uninstall scripts
  provisioner "remote-exec" {
    when   = destroy
    inline = [
      "chmod +x /tmp/uninstall_k3s.sh || true",
      "sudo /tmp/uninstall_k3s.sh || true"
    ]
  }
}


resource "null_resource" "k3s_master_uninstall" {
  triggers = {
    master_ip   = var.master.ip
    ssh_user    = var.master.ssh_user
    private_key = var.master.private_key
  }

  connection {
    host        = self.triggers.master_ip
    user        = self.triggers.ssh_user
    private_key = file(self.triggers.private_key)
  }

  provisioner "file" {
    when        = destroy
    source      = "${path.module}/scripts/uninstall_k3s.sh"
    destination = "/tmp/uninstall_k3s.sh"
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = [
      "chmod +x /tmp/uninstall_k3s.sh || true",
      "sudo /tmp/uninstall_k3s.sh || true"
    ]
  }

  depends_on = [
    null_resource.k3s_worker_uninstall,
    null_resource.k3s_master_install
  ]
}