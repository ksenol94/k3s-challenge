# Local Kubernetes (K3s) DevOps Infrastructure

   This project automates the setup of a local Kubernetes (K3s) cluster (1 master and 1 worker node) using OpenTofu (Terraform), Helm, Jenkins, PostgreSQL and Redis.

ChatGPT Pro Plan used for helper AI Tool.

## Overview

-	Automates K3s master and worker node setup via Terraform and shell scripts.
-	Deploys PostgreSQL (with daily backup), Redis, and Jenkins using Helm charts.
-	Secrets and passwords are securely passed through terraform.tfvars.
-	Includes CLI test scripts for validating system health and external connectivity.
-	Provides a cleanup workflow for complete teardown and re-deployment.

## Requirements

-	Ubuntu virtual machine (you can use this infrastructure for 1 master minimum).
-	SSH key (Public and Private Key) for accessing VMs. Public Key must be added into VMs before start.
-	OpenTofu (Terraform) for infrastructure provisioning.
-	kubectl and Helm CLI for Kubernetes management.
-	psql and redis-cli for external connection testing.
-	Optional: Multipass or VirtualBox for VM creation.

## How to Use
In root folder use
```bash
tofu init && tofu plan
```
if you can see the infrastructure plan successfully you can use
```bash
tofu apply -auto-approve
```

# Infrastructure Setup
## Terraform Infrastructure

-   install_master.tf and install_workers.tf files executing install scripts in right order.
-	prepare_ubuntu.sh updates the system, disables swap and firewall, sets up DNS, and installs Helm, Docker etc.
-	install_k3s_master.sh installs the K3s master node and configures API.
-	install_k3s_worker.sh installs the worker node and joins into the cluster using the master node token.
-	Token and kubeconfig management scripts (fetch_kubeconfig.sh, create_or_refresh_token.sh, wait_for_token.sh) automate authentication setup.

## Helm Deployments

-	PostgreSQL is deployed using a scheduled backup job.
-	Redis is deployed with persistence and NodePort access for external connectivity.
-	Jenkins is deployed as a CI/CD server with Kubernetes integration and preinstalled plugins. Also Jenkinsfile in root folder executes test automatically when you build it in UI.
-	All Helm charts are stored under modules/helm/charts/ and follow clean code and minimalist structure.


## Test Scripts with details and usage

infra-check.sh 
- This script automatically validates the health and accessibility of Redis, PostgreSQL, and Jenkins deployments—retrieving all required credentials and connection details dynamically from the project’s terraform.tfvars file—and can be executed locally or in Jenkins with a single command in manuel-test-scripts folder.

```bash
chmod +x infra-check.sh && ./infra-check.sh
```

test_postgres.sh
-  This script verifies that the PostgreSQL service deployed via Terraform and Helm is reachable, correctly configured, and actively generating backups inside its persistent volume.


test_redis.sh
-  Verifies Redis connectivity, authentication, data persistence (SET/GET), and NodePort accessibility using credentials from terraform.tfvars.

test_jenkins.sh
-  Validates Jenkins’ external availability, authentication endpoint, and Kubernetes resource status with credentials dynamically loaded from terraform.tfvars.

## Challenge Requirement Coverage

-	All resources are managed via Git.
-	Shell scripts handle installation and dependencies. Scripts like prepare_ubuntu.sh, install_k3s_master.sh, and install_k3s_worker.sh automate setup from scratch.
-	Fully reproducible on clean Ubuntu VMs. The entire cluster can be recreated on fresh Ubuntu instances with a single tofu apply.
-	Kubernetes (K3s) cluster provisioned via OpenTofu(Terraform). Both master and worker nodes are provisioned automatically through Terraform modules and scripts.
-	PostgreSQL, Redis, and Jenkins are deployed using Helm charts.
-	Redis persistence and external access. Redis is accessible externally through NodePort and data is stored persistently on local-path volumes managed by the cluster.
-	PostgreSQL persistence with PVC. PostgreSQL data is stored persistently on local-path volumes managed by the cluster.
-	Jenkins deployed and externally accessible. Jenkins is deployed via Helm and reachable through and ready for  pipeline integration (all plugins and container dependencies are automatically installed).
-	No plain-text secrets. Sensitive credentials are securely passed via terraform.tfvars.
-	CLI test scripts implemented. Scripts verify the health and connectivity of PostgreSQL, Redis, and Jenkins:
-	infra-check.sh checks overall infrastructure status (Pods, PVCs, Services).


## Summary
This project delivers a secure, fully automated, and reproducible DevOps infrastructure on Kubernetes (K3s).
From VM preparation to service validation, every stage—setup, testing, and cleanup—is fully automated using Terraform, Helm, and shell scripting.
