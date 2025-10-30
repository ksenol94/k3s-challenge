pipeline {
  agent any
  environment {
    KUBECONFIG = "/var/jenkins_home/.kube/config"
  }
  stages {
    stage('Init') {
      steps {
        sh 'echo "Pipeline started"'
      }
    }
    stage('Terraform Apply') {
      steps {
        sh '''
          cd infra
          tofu init -input=false
          tofu apply -auto-approve
        '''
      }
    }
    stage('Verify Services') {
      steps {
        sh '''
          echo "[PostgreSQL Test]"
          psql "postgresql://postgres:postgres123@192.168.64.22:30432/appdb" -c "SELECT 1;"
          echo "[Redis Test]"
          redis-cli -h 192.168.64.22 -p 30379 -a redis123 ping
          echo "[Jenkins Access]"
          curl -sI http://192.168.64.22:32000 | grep "X-Jenkins"
        '''
      }
    }
    stage('Verify Backups') {
      steps {
        sh '''
          kubectl --insecure-skip-tls-verify=true -n infra exec -it statefulset/postgresql -- ls /var/lib/postgresql/data/backups || true
        '''
      }
    }
  }
  post {
    success { echo "✅ Challenge pipeline completed successfully!" }
    failure { echo "❌ Pipeline failed!" }
  }
}