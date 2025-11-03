# Defines node configuration and Helm credentials for local K3s deployment.
instances = [
  {
    name        = "master-node"
    ip          = "192.168.64.22"
    ssh_user    = "ubuntu"
    private_key = "~/.ssh/vm1_id_rsa"
    role        = "master"
  },
  {
    name        = "worker-node"
    ip          = "192.168.64.23"
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

