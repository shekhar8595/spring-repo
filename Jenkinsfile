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
                echo "Checking out code from GitHub..."
                checkout scm
            }
        }

        stage('Build JAR') {
            steps {
                echo "Building JAR using system Maven..."
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
                        echo "Activating GCP service account..."
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                        echo "Configuring Docker for GCR..."
                        gcloud auth configure-docker --quiet
                        echo "Pushing Docker image..."
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
                        echo "Activating GCP service account..."
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                        
                        echo "Fetching cluster credentials..."
                        gcloud container clusters get-credentials ${CLUSTER_NAME} \
                            --zone ${ZONE} \
                            --project ${PROJECT_ID} \
                            --quiet

                        echo "Applying Kubernetes deployment..."
                        kubectl apply -f k8s-deployment.yaml --namespace ${NAMESPACE}

                        echo "Updating deployment image..."
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
