pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'production'], description: 'Select environment to deploy')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        TF_DIR = 'terraform'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/raohus/terraform-node-ci.git',
                    credentialsId: 'gitrepoaccess'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    echo "🚀 Building and pushing Docker image for ${params.ENV}..."
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            docker build --build-arg ENV=${params.ENV} -t raohus/node-app:${params.ENV} .
                            echo $DOCKER_PASS | docker login -u raohus --password-stdin
                            docker push raohus/node-app:${params.ENV}
                        """
                    }
                }
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
                            echo "🔧 Selecting Terraform workspace: ${workspaceName}"
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
                echo "✅ EC2 instance will automatically pull raohus/node-app:${env.ENVIRONMENT} from Docker Hub and start the app."
            }
        }
    }

    post {
        success {
            echo '🎉 Deployment successful! Check your Terraform output for EC2 public IP.'
        }
        failure {
            echo '❌ Deployment failed. Review logs or consider running terraform destroy for cleanup.'
        }
    }
}

