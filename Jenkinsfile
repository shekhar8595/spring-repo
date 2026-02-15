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

        // -------------------------------
        // Step 0: Setup required tools
        // -------------------------------
        stage('Setup Tools') {
            steps {
                script {
                    echo "Installing Docker, gcloud, and kubectl..."

                    // Update system
                    sh 'sudo apt update -y'

                    // Install Docker
                    sh '''
                    sudo apt install -y docker.io
                    sudo systemctl enable docker
                    sudo systemctl start docker
                    sudo usermod -aG docker jenkins || true
                    '''

                    // Install Google Cloud SDK
                    sh '''
                    sudo apt install -y apt-transport-https ca-certificates gnupg curl
                    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
                    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
                    sudo apt update
                    sudo apt install -y google-cloud-sdk
                    '''

                    // Install kubectl
                    sh '''
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                    '''

                    // Verify installations
                    sh '''
                    docker --version
                    gcloud version
                    kubectl version --client
                    '''
                }
            }
        }

        // -------------------------------
        // Step 1: Checkout code
        // -------------------------------
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // -------------------------------
        // Step 2: Build JAR
        // -------------------------------
        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        // -------------------------------
        // Step 3: Build Docker image
        // -------------------------------
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER}")
                }
            }
        }

        // -------------------------------
        // Step 4: Push Docker image
        // -------------------------------
        stage('Push Docker Image') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud auth configure-docker
                    docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        // -------------------------------
        // Step 5: Deploy to GKE
        // -------------------------------
        stage('Deploy to GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID}

                    # Apply deployment YAML (creates or updates)
                    kubectl apply -f k8s-deployment.yaml --namespace ${NAMESPACE}

                    # Update deployment image
                    kubectl set image deployment/springboot-deployment \
                        springboot-container=gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${BUILD_NUMBER} \
                        --namespace ${NAMESPACE}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Deployment successful: Build #${BUILD_NUMBER}"
        }
        failure {
            echo "Deployment failed: Build #${BUILD_NUMBER}"
        }
    }
}
