Local Kubernetes (K3s) DevOps Infrastructure

This project automates the setup of a local Kubernetes (K3s) cluster using OpenTofu (Terraform), Helm, and Jenkins.
It provides a fully reproducible DevOps environment on clean Ubuntu VMs with persistent storage, PostgreSQL backups, and Redis caching.

Overview
	•	Automates K3s master and worker node setup via Terraform and shell scripts.
	•	Deploys PostgreSQL, Redis, and Jenkins using Helm charts.
	•	Secrets and passwords are securely passed through terraform.tfvars.
	•	Includes CLI test scripts for validating system health and external connectivity.
	•	Provides a cleanup workflow for complete teardown and re-deployment.

Requirements
	•	Ubuntu virtual machines (1 master and 1 worker minimum).
	•	SSH key with access to all VMs.
	•	OpenTofu (Terraform) for infrastructure provisioning.
	•	kubectl and Helm CLI for Kubernetes management.
	•	psql and redis-cli for external connection testing.
	•	Optional: Multipass or VirtualBox for VM creation.

Infrastructure Setup

1. Preparation Scripts
	•	prepare_ubuntu.sh updates the system, disables swap and firewall, sets up DNS, and installs Helm.
	•	install_k3s_master.sh installs the K3s master node, configures API (port 6443), and sets StorageClass to “Immediate”.
	•	install_k3s_worker.sh joins the worker node to the cluster using the master join token.
	•	Token and kubeconfig management scripts (fetch_kubeconfig.sh, create_or_refresh_token.sh, wait_for_token.sh) automate authentication setup.

2. Helm Deployments
	•	PostgreSQL is deployed with persistent volume storage and a scheduled backup job.
	•	Redis is deployed with persistence and NodePort access for external connectivity.
	•	Jenkins is deployed as a CI/CD server with Kubernetes integration and preinstalled plugins.
	•	All Helm charts are stored under modules/helm/charts/ and follow best-practice structure.

Challenge Requirement Coverage

Completed
	•	All resources are managed via Git.
All Terraform, Helm, and shell scripts are version-controlled and can be tracked.
	•	Shell scripts handle installation and dependencies.
Scripts like prepare_ubuntu.sh, install_k3s_master.sh, and install_k3s_worker.sh automate setup from scratch.
	•	Fully reproducible on clean Ubuntu VMs.
The entire cluster can be recreated on fresh Ubuntu instances with a single tofu apply.
	•	Kubernetes (K3s) cluster provisioned via Terraform (OpenTofu).
Both master and worker nodes are provisioned automatically through Terraform modules and scripts.
	•	Applications deployed via Helm charts.
PostgreSQL, Redis, and Jenkins are deployed using well-structured Helm charts.
	•	Redis persistence and external access.
Redis is accessible externally through NodePort (30379) and uses a persistent volume for data durability.
	•	PostgreSQL persistence with PVC.
PostgreSQL data is stored persistently on local-path volumes managed by the cluster.
	•	Jenkins deployed and externally accessible.
Jenkins is deployed via Helm and reachable through NodePort (32000), ready for future pipeline integration.
	•	No plain-text secrets.
Sensitive credentials (database and Jenkins admin passwords) are securely passed via terraform.tfvars using Helm’s set_sensitive.
	•	CLI test scripts implemented.
Scripts verify the health and connectivity of PostgreSQL, Redis, and Jenkins:
	•	infra-check.sh checks overall infrastructure status (Pods, PVCs, Services).
	•	test_postgres.sh tests PostgreSQL external connection on NodePort 30432.
	•	test_redis.sh validates Redis response via NodePort 30379.
	•	test_jenkins.sh confirms Jenkins HTTP accessibility on NodePort 32000.
    Example usage:
  bash scripts/test_postgres.sh
  bash scripts/test_redis.sh 
  bash scripts/test_jenkins.sh 

 Not Yet Implemented
	•	PostgreSQL backup management.
The CronJob for automated backups runs every 5 minutes (for testing) and logs successful runs.
However, backup file persistence under /backups is pending verification.
	•	Jenkins pipeline configuration.
Jenkins is deployed and accessible, but pipeline setup and automated build triggers have not been implemented yet.

Summary

This project delivers a secure, fully automated, and reproducible DevOps infrastructure on Kubernetes (K3s).
From VM preparation to service validation, every stage—setup, testing, and cleanup—is fully automated using Terraform, Helm, and shell scripting.
