pipeline {
    agent any

    environment {
        // Values pulled directly from terraform.tfvars
        TFVARS_PATH = "${WORKSPACE}/terraform.tfvars"
        PG_PASS = sh(script: "grep postgres_password ${TFVARS_PATH} | awk -F'=' '{print $2}' | tr -d '\"[:space:]'", returnStdout: true).trim()
        REDIS_PASS = sh(script: "grep redis_password ${TFVARS_PATH} | awk -F'=' '{print $2}' | tr -d '\"[:space:]'", returnStdout: true).trim()
        MASTER_IP = sh(script: "grep master_ip ${TFVARS_PATH} | awk -F'=' '{print $2}' | tr -d '\"[:space:]'", returnStdout: true).trim()
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
                    kubectl -n infra get pods -l app=postgres
                    export PGPASSWORD=${PG_PASS}
                    psql "postgresql://postgres:${PG_PASS}@${MASTER_IP}:30432/postgres" -c "SELECT version();"
                '''
            }
        }

        stage('Verify Redis') {
            steps {
                echo "🔍 Checking Redis connection..."
                sh '''
                    kubectl -n infra get pods -l app=redis
                    redis-cli -h ${MASTER_IP} -p 30379 -a "${REDIS_PASS}" PING
                '''
            }
        }

        stage('Validate Helm Releases') {
            steps {
                echo "📦 Checking Helm deployments..."
                sh '''
                    helm list -A
                    kubectl get pods -A
                '''
            }
        }

        stage('PostgreSQL Backup Check') {
            steps {
                echo "💾 Verifying scheduled PostgreSQL backups..."
                sh '''
                    kubectl -n infra get cronjob postgresql-backup
                    kubectl -n infra get jobs | grep postgresql-backup || true
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