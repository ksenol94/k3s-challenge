pipeline {
    agent any

    environment {
        TFVARS_PATH = "${WORKSPACE}/terraform.tfvars"

        PG_PASS = sh(
            script: "grep postgres_password ${TFVARS_PATH} | awk -F'=' '{print \$2}' | tr -d '[:space:]'",
            returnStdout: true
        ).trim()

        REDIS_PASS = sh(
            script: "grep redis_password ${TFVARS_PATH} | awk -F'=' '{print \$2}' | tr -d '[:space:]'",
            returnStdout: true
        ).trim()

        MASTER_IP = sh(
            script: "grep ip ${TFVARS_PATH} | head -1 | awk -F'=' '{print \$2}' | tr -d '[:space:]|\"'",
            returnStdout: true
        ).trim()
    }

    stages {

        stage('Init') {
            steps {
                echo "✅ Jenkins CI initialized"
                sh 'echo "[INFO] Jenkins started pipeline on $(date)"'
            }
        }

        stage('Verify PostgreSQL') {
            steps {
                echo "🔍 Checking PostgreSQL connection..."
                sh '''
                    echo "[INFO] Listing PostgreSQL pods..."
                    kubectl -n infra get pods -l app=postgresql

                    echo "[INFO] Testing PostgreSQL connection..."
                    export PGPASSWORD=${PG_PASS}

                    # Cluster içi DNS üzerinden test
                    if ! psql "postgresql://postgres:${PG_PASS}@postgresql.infra.svc.cluster.local:5432/postgres" -c "SELECT version();" >/dev/null 2>&1; then
                        echo "[ERROR] ❌ Cannot connect to PostgreSQL inside cluster (postgresql.infra.svc.cluster.local:5432)"
                        echo "[INFO] Trying NodePort (${MASTER_IP}:30432) as fallback..."
                        if ! psql "postgresql://postgres:${PG_PASS}@${MASTER_IP}:30432/postgres" -c "SELECT version();" >/dev/null 2>&1; then
                            echo "[ERROR] ❌ Cannot connect to PostgreSQL via NodePort either."
                            exit 1
                        else
                            echo "[OK] ✅ PostgreSQL connection via NodePort successful."
                        fi
                    else
                        echo "[OK] ✅ PostgreSQL connection via ClusterIP successful."
                    fi
                '''
            }
        }

        stage('Verify Redis') {
            steps {
                echo "🔍 Checking Redis connection..."
                sh '''
                    echo "[INFO] Listing Redis pods..."
                    kubectl -n infra get pods -l app=redis

                    echo "[INFO] Testing Redis connection..."
                    if redis-cli -h redis.infra.svc.cluster.local -p 6379 -a "${REDIS_PASS}" PING | grep -q "PONG"; then
                        echo "[OK] ✅ Redis connection via ClusterIP successful."
                    elif redis-cli -h ${MASTER_IP} -p 30379 -a "${REDIS_PASS}" PING | grep -q "PONG"; then
                        echo "[OK] ✅ Redis connection via NodePort successful."
                    else
                        echo "[ERROR] ❌ Redis connection failed (ClusterIP + NodePort)."
                        exit 1
                    fi
                '''
            }
        }

        stage('Validate Helm Releases') {
            steps {
                echo "📦 Checking Helm and Kubernetes status..."
                sh '''
                    echo "[INFO] Helm releases:"
                    helm list -A
                    echo "[INFO] Pods status:"
                    kubectl get pods -A
                '''
            }
        }

        stage('PostgreSQL Backup Check') {
            steps {
                echo "💾 Verifying scheduled PostgreSQL backups..."
                sh '''
                    echo "[INFO] Checking if PostgreSQL backup CronJob exists..."
                    kubectl -n infra get cronjob postgresql-backup || echo "[WARN] No backup CronJob found."

                    echo "[INFO] Checking backup jobs..."
                    kubectl -n infra get jobs | grep postgresql-backup || echo "[WARN] No backup jobs found yet."
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 CI pipeline completed successfully!"
        }
        failure {
            echo "❌ CI pipeline failed. Check logs above."
        }
    }
}
