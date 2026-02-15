pipeline {
    agent any

    environment {
        PROJECT_ID   = "spheric-subject-482019-e5"
        IMAGE_NAME   = "springboot-cicd-demo"
        CLUSTER_NAME = "spring-cluster"
        ZONE         = "us-central1-a"
        NAMESPACE    = "default"
        K8S_MANIFEST = "k8s/" // Apply all YAMLs inside k8s folder
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
                echo "Building JAR using Maven..."
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
                        set -e
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS --quiet
                        gcloud auth configure-docker --quiet
                        docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Create GKE Cluster if Not Exists') {
            steps {
                echo "Ensuring GKE cluster exists..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS --quiet
                        if ! gcloud container clusters describe ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} > /dev/null 2>&1; then
                            echo "Cluster not found. Creating ${CLUSTER_NAME}..."
                            gcloud container clusters create ${CLUSTER_NAME} \
                                --zone ${ZONE} \
                                --num-nodes=1 \
                                --project ${PROJECT_ID} \
                                --quiet
                        else
                            echo "Cluster ${CLUSTER_NAME} already exists."
                        fi
                    """
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                echo "Deploying to GKE..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS --quiet
                        gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} --quiet

                        # Check if manifest directory exists and has yaml files
                        if [ ! -d ${K8S_MANIFEST} ] || [ -z "\$(ls -A ${K8S_MANIFEST}/*.yaml 2>/dev/null)" ]; then
                            echo "ERROR: Kubernetes manifests not found in directory ${K8S_MANIFEST}"
                            exit 1
                        fi

                        echo "Applying Kubernetes manifests from ${K8S_MANIFEST}..."
                        kubectl apply -f ${K8S_MANIFEST} --namespace ${NAMESPACE}

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
