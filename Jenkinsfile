pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'production'], description: 'Select environment to deploy')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        TF_DIR                = 'terraform'
        DOCKER_IMAGE = "raohus/node-app:${params.ENV}"
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

        stage('Terraform Init & Apply') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh 'terraform init'
                        sh "terraform apply -auto-approve -var environment=${params.ENV}"
                    }
                }
            }
        }

        stage('Deploy Container') {
            steps {
                script {
                    echo "🚀 Deploying container for ${params.ENV}..."
                    // Force failure if image doesn’t exist
                    sh """
                        set -e
                        docker pull ${DOCKER_IMAGE} || (echo "❌ Image not found!" && exit 1)
                        echo "✅ Deployment succeeded with image: ${DOCKER_IMAGE}"
                    """
                    error("Simulated failure for rollback testing")
                }
            }
        }

        stage('Push Stable Image') {
            steps {
                echo "🏷 Tagging current build as stable image..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker tag $DOCKER_IMAGE $STABLE_IMAGE
                        docker push $STABLE_IMAGE
                    """
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment successful! Stable image updated to ${STABLE_IMAGE}"
        }

        failure {
            echo "❌ Deployment failed. Rolling back to previous stable image..."
            script {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker pull $STABLE_IMAGE
                        docker tag $STABLE_IMAGE raohus/node-app:${params.ENV}
                        docker push raohus/node-app:${params.ENV}
                    """
                }
            }
            echo "✅ Rollback complete — reverted ${params.ENV} tag to last stable image."
        }
    }
}

