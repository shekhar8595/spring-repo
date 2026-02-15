pipeline {
    agent any

    environment {
        PROJECT_ID = "YOUR_PROJECT_ID"
        IMAGE_NAME = "springboot-cicd-demo"
        CLUSTER_NAME = "spring-cluster"
        ZONE = "us-central1-a"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$BUILD_NUMBER .
                """
            }
        }

        stage('Push Image') {
            steps {
                sh """
                gcloud auth configure-docker
                docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$BUILD_NUMBER
                """
            }
        }

        stage('Deploy to GKE') {
            steps {
                sh """
                gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
                kubectl set image deployment/springboot-deployment \
                springboot-container=gcr.io/$PROJECT_ID/$IMAGE_NAME:$BUILD_NUMBER
                """
            }
        }
    }
}
