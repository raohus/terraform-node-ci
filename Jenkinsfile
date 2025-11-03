pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/raohus/terraform-node-ci.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Deploy Node.js App') {
            steps {
                // SSH into EC2 and deploy app
                sh '''
                EC2_IP=$(terraform output -raw ec2_public_ip)
                ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
                  sudo apt update
                  sudo apt install -y nodejs npm
                  git clone https://your-repo-url.git
                  cd your-app-folder
                  npm install
                  node index.js &
                EOF
                '''
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
