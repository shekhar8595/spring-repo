# # -------- Build Stage --------
# FROM maven:3.9.1-eclipse-temurin-17 AS build

# # Set working directory
# WORKDIR /app

# # Copy pom and download dependencies first (caching)
# COPY pom.xml .
# RUN mvn dependency:go-offline -B

# # Copy the source code
# COPY src ./src

# # Build the JAR
# RUN mvn clean package -DskipTests

# # -------- Run Stage --------
# FROM eclipse-temurin:17-jdk-alpine

# # Set working directory
# WORKDIR /app

# # Copy the JAR from build stage
# COPY --from=build /app/target/*.jar app.jar

# # Expose port
# EXPOSE 8080

# # Create non-root user
# RUN addgroup -S spring && adduser -S spring -G spring
# USER spring

# # JVM options for production (optional)
# ENTRYPOINT ["java","-Xms256m","-Xmx512m","-Djava.security.egd=file:/dev/./urandom","-jar","/app/app.jar"]

pipeline {
    agent any

    environment {
        PROJECT_ID   = "spheric-subject-482019-e5"
        IMAGE_NAME   = "springboot-cicd-demo"
        CLUSTER_NAME = "spring-cluster"
        ZONE         = "us-central1-a"
        NAMESPACE    = "default"
        K8S_MANIFEST = "k8s/k8s-deployment.yaml"
    }

    stages {
        stage('Destroy Environment') {
            steps {
                echo "Deleting GKE resources and Docker images..."
                withCredentials([file(credentialsId: 'gcp-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        set -e

                        echo "Activating GCP service account..."
                        gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS --quiet

                        # Fetch cluster credentials (if cluster exists)
                        if gcloud container clusters describe ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} > /dev/null 2>&1; then
                            echo "Fetching cluster credentials..."
                            gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} --quiet

                            echo "Deleting Kubernetes deployment and service..."
                            kubectl delete -f ${K8S_MANIFEST} --namespace ${NAMESPACE} --ignore-not-found

                            echo "Deleting namespace resources..."
                            kubectl delete namespace ${NAMESPACE} --ignore-not-found
                        else
                            echo "Cluster ${CLUSTER_NAME} does not exist. Skipping Kubernetes cleanup."
                        fi

                        echo "Deleting GKE cluster..."
                        gcloud container clusters delete ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} --quiet || echo "Cluster already deleted."

                        echo "Deleting Docker images from GCR..."
                        gcloud container images list-tags gcr.io/${PROJECT_ID}/${IMAGE_NAME} --format='get(digest)' | \
                        xargs -r -n1 -I{} gcloud container images delete gcr.io/${PROJECT_ID}/${IMAGE_NAME}@{} --quiet || echo "No images to delete."
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Environment cleanup completed successfully."
        }
        failure {
            echo "⚠️ Cleanup encountered errors."
        }
    }
}
