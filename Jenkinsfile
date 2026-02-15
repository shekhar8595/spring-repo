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

        stage('Activate GCP') {
            steps {
                echo "Activating GCP service account..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS --quiet
                        gcloud config set project ${PROJECT_ID} --quiet
                    """
                }
            }
        }

        stage('Delete Kubernetes Resources') {
            steps {
                echo "Deleting Kubernetes resources from cluster..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e
                        # Fetch cluster credentials
                        gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} --quiet

                        # Delete all resources in the namespace
                        kubectl delete all --all --namespace ${NAMESPACE} || true

                        # Optionally, delete namespace itself
                        kubectl delete namespace ${NAMESPACE} || true
                    """
                }
            }
        }

        stage('Delete GKE Cluster') {
            steps {
                echo "Deleting GKE cluster..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e
                        if gcloud container clusters describe ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} > /dev/null 2>&1; then
                            gcloud container clusters delete ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} --quiet
                            echo "Cluster ${CLUSTER_NAME} deleted."
                        else
                            echo "Cluster ${CLUSTER_NAME} does not exist."
                        fi
                    """
                }
            }
        }

        stage('Delete Docker Images from GCR') {
            steps {
                echo "Deleting Docker images from Google Container Registry..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e
                        # List all image digests and delete them
                        gcloud auth configure-docker --quiet
                        DIGESTS=\$(gcloud container images list-tags gcr.io/${PROJECT_ID}/${IMAGE_NAME} --format='get(digest)')
                        for digest in \$DIGESTS; do
                            gcloud container images delete gcr.io/${PROJECT_ID}/${IMAGE_NAME}@\$digest --quiet
                        done
                    """
                }
            }
        }

    }

    post {
        success {
            echo "✅ Environment cleanup completed successfully!"
        }
        failure {
            echo "❌ Cleanup failed. Check the logs!"
        }
    }
}
