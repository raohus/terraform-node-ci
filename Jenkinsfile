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
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                    EC2_IP=$(terraform output -raw ec2_public_ip)
                    ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP << EOF
                      sudo yum update -y
                      sudo yum install -y nodejs git
                      git clone https://github.com/raohus/terraform-node-ci.git
                      cd terraform-node-ci
                      npm install
                      nohup node index.js > app.log 2>&1 &
                    EOF
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed.'
        }
    }
}
