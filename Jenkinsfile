pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'production'], description: 'Select environment to deploy')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        TF_DIR                = 'terraform'
        DOCKER_IMAGE          = "raohus/node-app:${params.ENV}"
        STABLE_IMAGE          = "raohus/node-app:stable-${params.ENV}"
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
                            docker build --build-arg ENV=${params.ENV} -t $DOCKER_IMAGE .
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push $DOCKER_IMAGE
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

        stage('Fetch EC2 IP') {
            steps {
                script {
                    env.EC2_PUBLIC_IP = sh(script: "terraform output -raw ec2_public_ip", returnStdout: true).trim()
                    echo "🌐 EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                }
            }
        }

        stage('Deploy App on EC2') {
            steps {
                echo "✅ Deploying Docker image to EC2..."
                sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "
                        docker stop node-app || true &&
                        docker rm node-app || true &&
                        docker pull $DOCKER_IMAGE &&
                        docker run -d -p 80:3000 --name node-app $DOCKER_IMAGE
                    "
                """
            }
        }
    }

    post {
        success {
            echo '🎉 Deployment successful! Tagging as stable image...'
            sh """
                docker tag $DOCKER_IMAGE $STABLE_IMAGE
                docker push $STABLE_IMAGE
            """
        }
        failure {
            echo '❌ Deployment failed. Rolling back to last stable image...'
            sh """
                ssh -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "
                    docker stop node-app || true &&
                    docker rm node-app || true &&
                    docker pull $STABLE_IMAGE &&
                    docker run -d -p 80:3000 --name node-app $STABLE_IMAGE
                "
            """
        }
    }
}

