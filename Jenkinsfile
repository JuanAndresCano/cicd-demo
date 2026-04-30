pipeline {
    agent any

    environment {
        APP_NAME   = 'cicd-demo'
        DOCKER_TAG = 'latest'
        SONAR_URL  = 'http://sonarqube:9000'
    }

    stages {

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build') {
            steps { sh 'mvn clean package -DskipTests -B' }
        }

        stage('Test') {
            steps { sh 'mvn test -B' }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Static Analysis (SonarQube)') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        ./mvnw sonar:sonar \
                            -Dsonar.projectKey=cicd-demo \
                            -Dsonar.host.url=$SONAR_URL \
                            -Dsonar.token=$SONAR_TOKEN \
                            -B
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t cicd-demo:latest .'
            }
        }

        stage('Container Security Scan (Trivy)') {
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/trivy \
                        aquasec/trivy image \
                            --exit-code 1 \
                            --severity CRITICAL \
                            --no-progress \
                            cicd-demo:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker stop cicd-demo || true
                    docker rm   cicd-demo || true
                    docker run -d \
                        --name cicd-demo \
                        -p 80:8081 \
                        cicd-demo:latest
                '''
            }
        }
    }

    post {
        always {
            echo 'Limpiando espacio de trabajo...'
            script {
                try { cleanWs() } catch (e) { echo "cleanWs omitido: ${e.message}" }
            }
        }
        success { echo 'Pipeline completado exitosamente.' }
        failure { echo 'Pipeline fallo. Revisa los logs.' }
    }
}