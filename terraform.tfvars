# Defines node configuration and Helm credentials for local K3s deployment.
instances = [
  {
    name        = "master-node-new"
    ip          = "192.168.64.5"
    ssh_user    = "ubuntu"
    private_key = "~/.ssh/vm1_id_rsa"
    role        = "master"
  },
  {
    name        = "worker-node"
    ip          = "192.168.64.6"
    ssh_user    = "ubuntu"
    private_key = "~/.ssh/vm1_id_rsa"
    role        = "worker"
  }
]

kubeconfig_path = "./.work"

# Helm Component Secrets
postgres_user     = "postgres"
postgres_password = "postgres123"
redis_password    = "redis123"
jenkins_user      = "admin"
jenkins_password  = "jenkins123"
# git_username = "git"
# git_password = "git123"
