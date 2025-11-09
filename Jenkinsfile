pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'production'], description: 'Select environment')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        TF_DIR = 'terraform'
        APP_IMAGE = 'node-app:latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/raohus/terraform-node-ci.git',
                credentialsId: 'gitrepoaccess'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                echo "Building Docker image for ${params.ENV} environment..."
                docker build --build-arg ENV=${params.ENV} -t $APP_IMAGE .
                docker save $APP_IMAGE -o node-app.tar
                """
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Select Workspace') {
            steps {
                script {
                    def workspaceName = params.ENV
                    dir("${TF_DIR}") {
                        sh """
                        echo "Checking Terraform workspace: ${workspaceName}"
                        if terraform workspace list | grep -q '${workspaceName}'; then
                            terraform workspace select ${workspaceName}
                        else
                            terraform workspace new ${workspaceName}
                        fi
                        """
                    }
                    env.ENVIRONMENT = workspaceName
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh "terraform plan -var environment=${env.ENVIRONMENT}"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh "terraform apply -auto-approve -var environment=${env.ENVIRONMENT}"
                }
            }
        }

        stage('Deploy App via Terraform User Data') {
            steps {
                echo "✅ Terraform will install Docker & run the app automatically on EC2 with NODE_ENV=${env.ENVIRONMENT}"
            }
        }
    }

    post {
        success {
            echo '🎉 Deployment successful! Visit the EC2 public IP output by Terraform.'
        }
        failure {
            echo '❌ Deployment failed. Consider running terraform destroy for cleanup.'
        }
    }
}
