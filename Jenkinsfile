pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/your-username/terraform-node-ci.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh '''
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                '''
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    ec2_ip = sh(script: "cd terraform && terraform output -raw ec2_public_ip", returnStdout: true).trim()
                    echo "EC2 Public IP: ${ec2_ip}"
                }
            }
        }

        stage('Deploy Node.js App to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} << EOF
                        sudo apt update
                        sudo apt install -y nodejs npm git
                        git clone https://github.com/your-username/terraform-node-ci.git
                        cd terraform-node-ci
                        npm install
                        nohup node index.js &
                        EOF
                    '''
                }
            }
        }
    }
}
