pipeline {
    agent any

    environment {
        APP_NAME    = 'cicd-demo'
        DOCKER_TAG  = 'latest'
        SONAR_URL   = 'http://host.docker.internal:9000'
        SONAR_TOKEN = credentials('sonar-token')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh './mvnw clean package -DskipTests -B'
            }
        }

        stage('Test') {
            steps {
                sh './mvnw test -B'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Static Analysis (SonarQube)') {
            steps {
                sh '''
                    ./mvnw sonar:sonar \
                        -Dsonar.projectKey=cicd-demo \
                        -Dsonar.host.url=$SONAR_URL \
                        -Dsonar.token=$SONAR_TOKEN \
                        -B
                '''
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Quality Gate fallo: ${qg.status}. Despliegue bloqueado."
                        }
                    }
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
            cleanWs()
        }
        success {
            echo 'Pipeline completado exitosamente.'
        }
        failure {
            echo 'Pipeline fallo. Revisa los logs de la etapa en rojo.'
        }
    }
}