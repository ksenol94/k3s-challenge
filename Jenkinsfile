pipeline {
    agent any

    environment {
        TFVARS_PATH = "${WORKSPACE}/terraform.tfvars"
    }

    stages {
        stage('Init') {
            steps {
                echo "Jenkins CI initialized"
                sh 'echo "[INFO] Jenkins started pipeline on $(date)"'
            }
        }

        stage('Verify PostgreSQL') {
            steps {
                echo "🔍 Checking PostgreSQL connection..."
                script {
                    def PG_PASS = sh(script: "grep postgres_password ${TFVARS_PATH} | awk -F'=' '{print \$2}' | tr -d '[:space:]'", returnStdout: true).trim()
                    def MASTER_IP = sh(script: "grep ip ${TFVARS_PATH} | head -1 | awk -F'=' '{print \$2}' | tr -d '[:space:]|\"'", returnStdout: true).trim()

                    sh """
                        echo "[INFO] Listing PostgreSQL pods..."
                        kubectl -n infra get pods -l app=postgresql

                        echo "[INFO] Testing PostgreSQL connection (ClusterIP first)..."
                        export PGPASSWORD='${PG_PASS}'

                        if psql "postgresql://postgres:${PG_PASS}@postgresql.infra.svc.cluster.local:5432/postgres" -c "SELECT version();" >/dev/null 2>&1; then
                            echo "[OK] PostgreSQL ClusterIP connection successful."
                        else
                            echo "[WARN] ClusterIP connection failed, retrying via NodePort..."
                            if psql "postgresql://postgres:${PG_PASS}@${MASTER_IP}:30432/postgres" -c "SELECT version();" >/dev/null 2>&1; then
                                echo "[OK] PostgreSQL NodePort connection successful."
                            else
                                echo "[ERROR] Cannot connect to PostgreSQL (ClusterIP & NodePort failed)."
                                exit 1
                            fi
                        fi
                    """
                }
            }
        }

        stage('Verify Redis') {
            steps {
                echo "🔍 Checking Redis connection..."
                script {
                    def REDIS_PASS = sh(script: "grep redis_password ${TFVARS_PATH} | awk -F'=' '{print \$2}' | tr -d '[:space:]'", returnStdout: true).trim()
                    def MASTER_IP = sh(script: "grep ip ${TFVARS_PATH} | head -1 | awk -F'=' '{print \$2}' | tr -d '[:space:]|\"'", returnStdout: true).trim()

                    sh """
                        echo "[INFO] Listing Redis pods..."
                        kubectl -n infra get pods -l app=redis

                        echo "[INFO] Testing Redis via ClusterIP..."
                        if redis-cli -h redis.infra.svc.cluster.local -p 6379 -a ${REDIS_PASS} PING | grep PONG >/dev/null 2>&1; then
                            echo "[OK] Redis ClusterIP connection successful."
                        else
                            echo "[WARN] ClusterIP connection failed, retrying via NodePort..."
                            if redis-cli -h ${MASTER_IP} -p 30379 -a ${REDIS_PASS} PING | grep PONG >/dev/null 2>&1; then
                                echo "[OK] Redis NodePort connection successful."
                            else
                                echo "[ERROR] Redis connection failed (ClusterIP + NodePort)."
                                exit 1
                            fi
                        fi
                    """
                }
            }
        }

        stage('Validate Helm Releases') {
            steps {
                echo "Checking Helm & Kubernetes status..."
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
                echo "Verifying PostgreSQL backup CronJob..."
                sh '''
                    kubectl -n infra get cronjob postgresql-backup || echo "[WARN] No PostgreSQL backup CronJob found."
                    kubectl -n infra get jobs | grep postgresql-backup || echo "[INFO] No backup jobs have run yet."
                '''
            }
        }
    }

    post {
        success {
            echo "CI pipeline completed successfully!"
        }
        failure {
            echo "CI pipeline failed. Check logs above."
        }
    }
}