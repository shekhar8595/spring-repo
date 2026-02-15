pipeline {
    agent any

    environment {
        PROJECT_ID   = "spheric-subject-482019-e5"
        IMAGE_NAME   = "springboot-cicd-demo"
        CLUSTER_NAME = "spring-cluster"
        ZONE         = "us-central1-a"
        NAMESPACE    = "default"
    }

    stages {

        stage('Checkout') {
            steps {
                // Checkout code from GitHub
                checkout scm
            }
        }

        stage('Build JAR') {
            steps {
                echo "Building JAR using system Maven..."
                // Use system Maven installed on Jenkins server
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                script {
                    docker.build("gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "Pushing Docker image to GCR..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker
                        docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                echo "Deploying to GKE..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}
                        
                        # Apply Kubernetes deployment (create/update)
                        kubectl apply -f k8s-deployment.yaml --namespace ${NAMESPACE}

                        # Update deployment image to the new build
                        kubectl set image deployment/springboot-deployment \
                            springboot-container=gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER} \
                            --namespace ${NAMESPACE}
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "Verifying deployment..."
                sh "kubectl get pods --namespace ${NAMESPACE}"
                sh "kubectl get svc --namespace ${NAMESPACE}"
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful: Build #${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Deployment failed: Build #${BUILD_NUMBER}"
        }
    }
}
